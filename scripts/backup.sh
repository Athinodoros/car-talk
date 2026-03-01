#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# backup.sh — Create a PostgreSQL backup from the remote Docker host.
#
# Usage:
#   ./scripts/backup.sh
#
# Cron example (daily at 2 AM):
#   0 2 * * * /path/to/car-post-all/scripts/backup.sh >> /var/log/carpostall-backup.log 2>&1
#
# Required environment variables (set in .env or export before running):
#   POSTGRES_PASSWORD
#
# Backups are stored in the backups/ directory (relative to project root).
# Retention: backups older than 30 days are automatically deleted.
# ──────────────────────────────────────────────────────────────────────────────

REMOTE_DOCKER_HOST="tcp://192.168.1.164:2375"
COMPOSE_FILE="docker-compose.prod.yml"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$PROJECT_DIR/backups"
RETENTION_DAYS=30

# Database settings (must match docker-compose.prod.yml)
DB_USER="carpost"
DB_NAME="carpostall"
CONTAINER_SERVICE="postgres"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log()   { echo -e "${GREEN}[backup]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
warn()  { echo -e "${YELLOW}[backup]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
error() { echo -e "${RED}[backup]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

# ── Load .env file if present ────────────────────────────────────────────────

if [ -f "$PROJECT_DIR/.env" ]; then
  log "Loading environment from $PROJECT_DIR/.env"
  set -a
  # shellcheck disable=SC1091
  source "$PROJECT_DIR/.env"
  set +a
fi

# ── Validate required env vars ──────────────────────────────────────────────

if [ -z "${POSTGRES_PASSWORD:-}" ]; then
  error "Missing required environment variable: POSTGRES_PASSWORD"
  error "Set it in a .env file or export it before running this script."
  exit 1
fi

# ── Export DOCKER_HOST for all subsequent commands ──────────────────────────

export DOCKER_HOST="$REMOTE_DOCKER_HOST"
log "Targeting remote Docker host: $DOCKER_HOST"

# ── Create backup directory if it doesn't exist ────────────────────────────

mkdir -p "$BACKUP_DIR"

# ── Verify the postgres container is running ────────────────────────────────

log "Checking that the postgres container is running..."
if ! docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" ps --status running "$CONTAINER_SERVICE" | grep -q "$CONTAINER_SERVICE"; then
  error "The postgres container is not running."
  error "Start it with: DOCKER_HOST=$REMOTE_DOCKER_HOST docker compose -f $COMPOSE_FILE up -d postgres"
  exit 1
fi

# ── Create backup ───────────────────────────────────────────────────────────

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_FILENAME="backup_${TIMESTAMP}.dump"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILENAME"

log "Starting backup: $BACKUP_FILENAME"

if docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" exec -T "$CONTAINER_SERVICE" \
  pg_dump -U "$DB_USER" -d "$DB_NAME" -Fc > "$BACKUP_PATH"; then
  BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
  log "Backup completed successfully: $BACKUP_FILENAME ($BACKUP_SIZE)"
else
  error "Backup failed!"
  # Clean up partial backup file if it exists
  rm -f "$BACKUP_PATH"
  exit 1
fi

# ── Validate backup file ───────────────────────────────────────────────────

if [ ! -s "$BACKUP_PATH" ]; then
  error "Backup file is empty. Something went wrong."
  rm -f "$BACKUP_PATH"
  exit 1
fi

log "Backup file validated (non-empty)."

# ── Retention: delete backups older than 30 days ────────────────────────────

log "Cleaning up backups older than $RETENTION_DAYS days..."
DELETED_COUNT=0
while IFS= read -r old_backup; do
  rm -f "$old_backup"
  warn "Deleted old backup: $(basename "$old_backup")"
  DELETED_COUNT=$((DELETED_COUNT + 1))
done < <(find "$BACKUP_DIR" -name "backup_*.dump" -type f -mtime +$RETENTION_DAYS 2>/dev/null)

if [ "$DELETED_COUNT" -gt 0 ]; then
  log "Deleted $DELETED_COUNT old backup(s)."
else
  log "No old backups to clean up."
fi

# ── Summary ─────────────────────────────────────────────────────────────────

TOTAL_BACKUPS=$(find "$BACKUP_DIR" -name "backup_*.dump" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)

log "Backup complete!"
log "  File:           $BACKUP_PATH"
log "  Size:           $BACKUP_SIZE"
log "  Total backups:  $TOTAL_BACKUPS"
log "  Total size:     $TOTAL_SIZE"

exit 0
