#!/usr/bin/env bash
set -euo pipefail

# ── Orbis Uninstaller ────────────────────────────────────────────────────────
# Usage: curl -sSL https://install.iamorbis.one/uninstall.sh | bash
# ----------------------------------------------------------------------------

INSTALL_DIR="${INSTALL_DIR:-$HOME/orbis}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[orbis]${NC} $*"; }
success() { echo -e "${GREEN}[orbis]${NC} $*"; }
warn()    { echo -e "${YELLOW}[orbis]${NC} $*"; }
error()   { echo -e "${RED}[orbis] ERROR:${NC} $*" >&2; exit 1; }

echo ""
echo "  ██████╗ ██████╗ ██████╗ ██╗███████╗"
echo "  ██╔═══██╗██╔══██╗██╔══██╗██║██╔════╝"
echo "  ██║   ██║██████╔╝██████╔╝██║███████╗"
echo "  ██║   ██║██╔══██╗██╔══██╗██║╚════██║"
echo "  ╚██████╔╝██║  ██║██████╔╝██║███████║"
echo "   ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝╚══════╝"
echo ""
warn "Orbis Uninstaller"
echo ""

# ── Check install dir exists ─────────────────────────────────────────────────
if [ ! -d "$INSTALL_DIR" ]; then
  error "Orbis install directory not found: $INSTALL_DIR"
fi

# ── Confirm ──────────────────────────────────────────────────────────────────
warn "This will:"
warn "  • Stop and remove all Orbis containers"
warn "  • Delete all Docker volumes (your database and data will be lost)"
warn "  • Remove the install directory: $INSTALL_DIR"
echo ""
read -r -p "  Are you sure you want to uninstall Orbis? [y/N] " CONFIRM
if [[ ! "${CONFIRM:-N}" =~ ^[Yy]$ ]]; then
  info "Uninstall cancelled."
  exit 0
fi

# ── Offer backup before wiping ───────────────────────────────────────────────
echo ""
read -r -p "  Create a database backup before uninstalling? [Y/n] " DO_BACKUP
if [[ "${DO_BACKUP:-Y}" =~ ^[Yy]$ ]]; then
  BACKUP_FILE="$HOME/orbis-backup-$(date +%Y%m%d-%H%M%S).sql"
  info "Backing up database to $BACKUP_FILE ..."
  if docker compose -f "$INSTALL_DIR/docker-compose.yml" exec -T postgres \
      pg_dump -U orbis orbis > "$BACKUP_FILE" 2>/dev/null; then
    success "Backup saved to $BACKUP_FILE"
  else
    warn "Backup failed (containers may already be stopped). Continuing without backup."
    rm -f "$BACKUP_FILE"
  fi
fi

# ── Stop and remove containers + volumes ─────────────────────────────────────
echo ""
info "Stopping Orbis containers..."
if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
  docker compose -f "$INSTALL_DIR/docker-compose.yml" down --volumes --remove-orphans 2>/dev/null || true
fi

# ── Remove Docker images ──────────────────────────────────────────────────────
echo ""
read -r -p "  Remove Orbis Docker images to free disk space? [Y/n] " RM_IMAGES
if [[ "${RM_IMAGES:-Y}" =~ ^[Yy]$ ]]; then
  info "Removing Orbis images..."
  docker images --format '{{.Repository}}:{{.Tag}}' | grep 'iamorbis/' | xargs docker rmi -f 2>/dev/null || true
  success "Images removed."
fi

# ── Remove install directory ──────────────────────────────────────────────────
echo ""
info "Removing install directory: $INSTALL_DIR ..."
rm -rf "$INSTALL_DIR"

echo ""
success "Orbis has been uninstalled."
