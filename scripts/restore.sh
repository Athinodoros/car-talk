#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# restore.sh — Restore a PostgreSQL backup to the remote Docker host.
#
# Usage:
#   ./scripts/restore.sh backups/backup_2024-01-15_12-30-00.dump
#   ./scripts/restore.sh /absolute/path/to/backup.dump
#
# WARNING: This is a destructive operation. It will drop and recreate all
# objects in the target database. You will be asked for confirmation.
#
# Required environment variables (set in .env or export before running):
#   POSTGRES_PASSWORD
# ──────────────────────────────────────────────────────────────────────────────

REMOTE_DOCKER_HOST="tcp://192.168.1.164:2375"
COMPOSE_FILE="docker-compose.prod.yml"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Database settings (must match docker-compose.prod.yml)
DB_USER="carpost"
DB_NAME="carpostall"
CONTAINER_SERVICE="postgres"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log()   { echo -e "${GREEN}[restore]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
warn()  { echo -e "${YELLOW}[restore]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*"; }
error() { echo -e "${RED}[restore]${NC} $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

# ── Validate arguments ─────────────────────────────────────────────────────

if [ $# -lt 1 ]; then
  error "Usage: $0 <backup-file>"
  error "Example: $0 backups/backup_2024-01-15_12-30-00.dump"
  exit 1
fi

BACKUP_FILE="$1"

# Resolve relative paths against project directory
if [[ "$BACKUP_FILE" != /* ]]; then
  BACKUP_FILE="$PROJECT_DIR/$BACKUP_FILE"
fi

# ── Validate backup file ───────────────────────────────────────────────────

if [ ! -f "$BACKUP_FILE" ]; then
  error "Backup file not found: $BACKUP_FILE"
  exit 1
fi

if [ ! -s "$BACKUP_FILE" ]; then
  error "Backup file is empty: $BACKUP_FILE"
  exit 1
fi

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
log "Backup file: $BACKUP_FILE ($BACKUP_SIZE)"

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

# ── Confirmation prompt ────────────────────────────────────────────────────

echo ""
warn "WARNING: This will restore the database from a backup."
warn "The existing data in '$DB_NAME' will be OVERWRITTEN."
warn ""
warn "  Backup file:  $(basename "$BACKUP_FILE")"
warn "  Backup size:  $BACKUP_SIZE"
warn "  Target DB:    $DB_NAME"
warn "  Target host:  192.168.1.164 (remote Docker)"
echo ""

read -rp "Are you sure you want to proceed? (yes/no): " CONFIRMATION

if [ "$CONFIRMATION" != "yes" ]; then
  log "Restore cancelled by user."
  exit 0
fi

# ── Export DOCKER_HOST for all subsequent commands ──────────────────────────

export DOCKER_HOST="$REMOTE_DOCKER_HOST"
log "Targeting remote Docker host: $DOCKER_HOST"

# ── Verify the postgres container is running ────────────────────────────────

log "Checking that the postgres container is running..."
if ! docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" ps --status running "$CONTAINER_SERVICE" | grep -q "$CONTAINER_SERVICE"; then
  error "The postgres container is not running."
  error "Start it with: DOCKER_HOST=$REMOTE_DOCKER_HOST docker compose -f $COMPOSE_FILE up -d postgres"
  exit 1
fi

# ── Stop the backend to prevent writes during restore ───────────────────────

log "Stopping the backend service to prevent writes during restore..."
if docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" ps --status running backend | grep -q backend; then
  docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" stop backend
  BACKEND_WAS_RUNNING=true
  log "Backend stopped."
else
  BACKEND_WAS_RUNNING=false
  log "Backend was not running."
fi

# ── Terminate existing connections to the database ──────────────────────────

log "Terminating existing connections to $DB_NAME..."
docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" exec -T "$CONTAINER_SERVICE" \
  psql -U "$DB_USER" -d postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();" \
  > /dev/null 2>&1 || true

# ── Drop and recreate the database ─────────────────────────────────────────

log "Dropping and recreating database $DB_NAME..."
docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" exec -T "$CONTAINER_SERVICE" \
  psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"

docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" exec -T "$CONTAINER_SERVICE" \
  psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

# ── Restore the backup ─────────────────────────────────────────────────────

log "Restoring backup..."
if docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" exec -T "$CONTAINER_SERVICE" \
  pg_restore -U "$DB_USER" -d "$DB_NAME" --no-owner --no-privileges --verbose < "$BACKUP_FILE" 2>&1 | tail -5; then
  log "Restore completed successfully."
else
  # pg_restore returns non-zero even on warnings (e.g., "role does not exist"),
  # so we check if the database is actually usable.
  warn "pg_restore exited with warnings (this is often normal)."
fi

# ── Verify the restore ─────────────────────────────────────────────────────

log "Verifying restored database..."
TABLE_COUNT=$(docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" exec -T "$CONTAINER_SERVICE" \
  psql -U "$DB_USER" -d "$DB_NAME" -t -c \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d '[:space:]')

if [ "$TABLE_COUNT" -gt 0 ] 2>/dev/null; then
  log "Verification passed: $TABLE_COUNT table(s) found in the restored database."
else
  error "Verification failed: no tables found in the restored database."
  exit 1
fi

# ── Restart the backend if it was running ───────────────────────────────────

if [ "$BACKEND_WAS_RUNNING" = true ]; then
  log "Restarting the backend service..."
  docker compose -f "$PROJECT_DIR/$COMPOSE_FILE" start backend
  log "Backend restarted."
fi

# ── Done ────────────────────────────────────────────────────────────────────

log "Restore complete!"
log "  Source:    $(basename "$BACKUP_FILE")"
log "  Database:  $DB_NAME"
log "  Tables:    $TABLE_COUNT"

exit 0
