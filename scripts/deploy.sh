#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# deploy.sh — Build and deploy car-post-all to the remote Docker host.
#
# Usage:
#   ./scripts/deploy.sh              # Build + deploy
#   ./scripts/deploy.sh --no-build   # Deploy without rebuilding (use existing images)
#
# Required environment variables (set in .env or export before running):
#   POSTGRES_PASSWORD
#   JWT_SECRET
#   JWT_REFRESH_SECRET
#
# Optional:
#   SENTRY_DSN
#   FIREBASE_SERVICE_ACCOUNT_KEY
# ──────────────────────────────────────────────────────────────────────────────

REMOTE_DOCKER_HOST="tcp://192.168.1.164:2375"
COMPOSE_FILE="docker-compose.prod.yml"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HEALTH_URL="http://192.168.1.164:3001/health"
MAX_HEALTH_RETRIES=30
HEALTH_INTERVAL=2

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log()   { echo -e "${GREEN}[deploy]${NC} $*"; }
warn()  { echo -e "${YELLOW}[deploy]${NC} $*"; }
error() { echo -e "${RED}[deploy]${NC} $*" >&2; }

# ── Validate required env vars ────────────────────────────────────────────────

validate_env() {
  local missing=0
  for var in POSTGRES_PASSWORD JWT_SECRET JWT_REFRESH_SECRET; do
    if [ -z "${!var:-}" ]; then
      error "Missing required environment variable: $var"
      missing=1
    fi
  done
  if [ "$missing" -eq 1 ]; then
    error "Set the required variables in a .env file or export them before running this script."
    exit 1
  fi
}

# ── Load .env file if present ─────────────────────────────────────────────────

if [ -f "$PROJECT_DIR/.env" ]; then
  log "Loading environment from $PROJECT_DIR/.env"
  set -a
  # shellcheck disable=SC1091
  source "$PROJECT_DIR/.env"
  set +a
fi

validate_env

# ── Export DOCKER_HOST for all subsequent commands ────────────────────────────

export DOCKER_HOST="$REMOTE_DOCKER_HOST"
log "Targeting remote Docker host: $DOCKER_HOST"

# ── Parse arguments ───────────────────────────────────────────────────────────

SKIP_BUILD=false
for arg in "$@"; do
  case "$arg" in
    --no-build) SKIP_BUILD=true ;;
    *) warn "Unknown argument: $arg" ;;
  esac
done

# ── Build ─────────────────────────────────────────────────────────────────────

if [ "$SKIP_BUILD" = false ]; then
  log "Building production images..."
  docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" build
else
  log "Skipping build (--no-build)"
fi

# ── Deploy ────────────────────────────────────────────────────────────────────

log "Starting services..."
docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" up -d

# ── Wait for health check ────────────────────────────────────────────────────

log "Waiting for backend health check at $HEALTH_URL ..."
for i in $(seq 1 $MAX_HEALTH_RETRIES); do
  if curl -sf "$HEALTH_URL" > /dev/null 2>&1 || wget -qO- "$HEALTH_URL" > /dev/null 2>&1; then
    log "Backend is healthy (attempt $i/$MAX_HEALTH_RETRIES)"
    break
  fi
  if [ "$i" -eq "$MAX_HEALTH_RETRIES" ]; then
    error "Backend did not become healthy after $((MAX_HEALTH_RETRIES * HEALTH_INTERVAL))s"
    error "Check logs: DOCKER_HOST=$REMOTE_DOCKER_HOST docker compose -f $COMPOSE_FILE logs backend"
    exit 1
  fi
  sleep $HEALTH_INTERVAL
done

# ── Run database migrations ──────────────────────────────────────────────────

log "Running database migrations..."
if docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" exec backend node dist/db/migrate.js; then
  log "Migrations completed successfully."
else
  error "Migration failed. Check logs for details."
  exit 1
fi

# ── Done ──────────────────────────────────────────────────────────────────────

log "Deployment complete!"
log "  Backend API: http://192.168.1.164:3001"
log "  Health:      $HEALTH_URL"
