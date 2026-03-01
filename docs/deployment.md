# Deployment Guide

Production deployment for the Car Post All backend, running on a remote Docker host at `192.168.1.164`.

## Architecture Overview

```
Internet
  │
  ▼
[ Caddy / nginx ]  ← HTTPS termination (port 443)
  │
  ▼
[ Fastify backend ] ← Docker container (port 3001 on host, 3000 internal)
  │
  ▼
[ PostgreSQL ]      ← Docker container (port 5434 on host, 5432 internal)
```

All services run via `docker-compose.prod.yml` on the remote Docker host. A reverse proxy (Caddy or nginx) handles TLS termination and forwards traffic to the backend.

## Environment Variables

Create a `.env` file in the project root (never commit this file):

```bash
# Required
POSTGRES_PASSWORD=<strong-random-password>
JWT_SECRET=<random-256-bit-hex>
JWT_REFRESH_SECRET=<different-random-256-bit-hex>

# Optional
SENTRY_DSN=https://...@sentry.io/...
FIREBASE_SERVICE_ACCOUNT_KEY=<base64-encoded-service-account-json>
```

Generate secrets:

```bash
openssl rand -hex 32   # For JWT_SECRET
openssl rand -hex 32   # For JWT_REFRESH_SECRET
openssl rand -base64 24  # For POSTGRES_PASSWORD
```

## Deploy, Backup, and Restore Scripts

All scripts live in `scripts/` and target the remote Docker host automatically.

### Deploy

```bash
./scripts/deploy.sh              # Build images + deploy
./scripts/deploy.sh --no-build   # Deploy without rebuilding
```

What it does:
1. Loads `.env` from the project root
2. Validates required environment variables
3. Builds production Docker images (unless `--no-build`)
4. Starts services via `docker compose up -d`
5. Waits for the backend health check at `http://192.168.1.164:3001/health`
6. Runs database migrations (`node dist/db/migrate.js`)

### Backup

```bash
./scripts/backup.sh
```

Creates a `pg_dump` (custom format) in `backups/`. Automatically deletes backups older than 30 days.

Cron example (daily at 2 AM):

```cron
0 2 * * * /path/to/car-post-all/scripts/backup.sh >> /var/log/carpostall-backup.log 2>&1
```

### Restore

```bash
./scripts/restore.sh backups/backup_2024-01-15_12-30-00.dump
```

Destructive operation: drops and recreates the database, stops the backend during restore, then restarts it. Requires interactive confirmation.

## HTTPS with Caddy (Recommended)

Caddy provides automatic HTTPS with Let's Encrypt certificate provisioning and renewal. No manual certificate management required.

### Caddyfile

Create `Caddyfile` in the project root:

```caddyfile
api.carpostall.com {
    reverse_proxy 192.168.1.164:3001

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
    }

    log {
        output file /var/log/caddy/access.log {
            roll_size 10mb
            roll_keep 5
        }
    }
}
```

### Running Caddy with Docker Compose

You can add a Caddy service to a separate compose file or run it alongside the existing stack. Example `docker-compose.caddy.yml`:

```yaml
services:
  caddy:
    image: caddy:2-alpine
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"  # HTTP/3
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data        # Certificates
      - caddy_config:/config    # Runtime config
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  caddy_data:
  caddy_config:
```

Deploy it alongside the existing production stack:

```bash
export DOCKER_HOST=tcp://192.168.1.164:2375

# Start the backend + postgres (existing stack)
docker compose -f docker-compose.prod.yml up -d

# Start the reverse proxy
docker compose -f docker-compose.caddy.yml up -d
```

### How Caddy TLS Works

- Caddy automatically obtains a Let's Encrypt certificate for the domain in the Caddyfile.
- Certificates are stored in the `caddy_data` volume and renewed automatically before expiry.
- DNS for `api.carpostall.com` must point to the public IP of the Docker host (or the machine running Caddy).
- Port 80 must be accessible from the internet for the ACME HTTP-01 challenge (Caddy handles this automatically).

### Running Caddy Without Docker

If you prefer to run Caddy directly on the host:

```bash
# Install (Debian/Ubuntu)
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install caddy

# Copy Caddyfile and start
sudo cp Caddyfile /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
sudo systemctl reload caddy
```

## Alternative: nginx Configuration

If you prefer nginx over Caddy, you will need to manage TLS certificates separately (e.g., with certbot).

### nginx Config Snippet

```nginx
server {
    listen 80;
    server_name api.carpostall.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.carpostall.com;

    ssl_certificate     /etc/letsencrypt/live/api.carpostall.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.carpostall.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        proxy_pass http://192.168.1.164:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support for Socket.IO
    location /socket.io/ {
        proxy_pass http://192.168.1.164:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### certbot Setup for nginx

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate (nginx must be running and port 80 reachable)
sudo certbot --nginx -d api.carpostall.com

# Auto-renewal is set up automatically via systemd timer
sudo systemctl status certbot.timer
```

## Checklist

Before deploying to production:

- [ ] DNS record for `api.carpostall.com` points to the host's public IP
- [ ] Ports 80 and 443 are open on the firewall
- [ ] `.env` file is populated with production secrets
- [ ] Backend port 3001 is NOT exposed publicly (only through the reverse proxy)
- [ ] Backup cron job is configured
- [ ] Sentry DSN is set (optional but recommended)
- [ ] Firebase service account key is configured (if push notifications are enabled)
- [ ] Flutter app `API_BASE_URL` is updated to `https://api.carpostall.com`
