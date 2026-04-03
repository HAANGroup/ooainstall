#!/usr/bin/env bash
set -euo pipefail

# ── Orbis Installer ──────────────────────────────────────────────────────────
# Usage: bash <(curl -fsSL https://install.iamorbis.one)
# -----------------------------------------------------------------------------

ORBIS_VERSION="${ORBIS_VERSION:-latest}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/orbis}"
COMPOSE_URL="https://install.iamorbis.one/docker-compose.yml"
ENV_URL="https://install.iamorbis.one/.env.example"
TEMPORAL_CONFIG_URL="https://install.iamorbis.one/temporal-dynamicconfig.yaml"
NGINX_CONFIG_URL="https://install.iamorbis.one/nginx.selfhosted.conf"

# ── Colors ───────────────────────────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'
B='\033[0;34m'; M='\033[0;35m'; W='\033[1;37m'; DIM='\033[2m'; NC='\033[0m'
BOLD='\033[1m'

step()    { echo -e "\n${BOLD}${C}  ▸ $*${NC}"; }
ok()      { echo -e "  ${G}✓${NC}  $*"; }
info()    { echo -e "  ${DIM}$*${NC}"; }
warn()    { echo -e "  ${Y}⚠${NC}  $*"; }
ask()     { echo -e "  ${M}?${NC}  $*"; }
error()   { echo -e "\n  ${R}✖  $*${NC}" >&2; exit 1; }
divider() { echo -e "  ${DIM}────────────────────────────────────────────────${NC}"; }

# ── Banner ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${C}${BOLD}"
echo "    ██████╗ ██████╗ ██████╗ ██╗███████╗"
echo "   ██╔═══██╗██╔══██╗██╔══██╗██║██╔════╝"
echo "   ██║   ██║██████╔╝██████╔╝██║███████╗"
echo "   ██║   ██║██╔══██╗██╔══██╗██║╚════██║"
echo "   ╚██████╔╝██║  ██║██████╔╝██║███████║"
echo "    ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝╚══════╝"
echo -e "${NC}"
echo -e "  ${BOLD}Self-Hosted Installer${NC}  ${DIM}v${ORBIS_VERSION}${NC}"
divider

# ── Prerequisites ─────────────────────────────────────────────────────────────
command -v docker >/dev/null 2>&1 || error "Docker not found. Install it from https://docs.docker.com/get-docker/"
docker info >/dev/null 2>&1       || error "Docker is not running. Start Docker Desktop and re-run this script."
docker compose version >/dev/null 2>&1 || error "Docker Compose plugin not found."

DOCKER_VER=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
COMPOSE_VER=$(docker compose version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
ok "Docker ${DOCKER_VER}  •  Compose ${COMPOSE_VER}"

# ── Install directory ─────────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
ok "Install directory: ${INSTALL_DIR}"

# ── Download config files ─────────────────────────────────────────────────────
step "Downloading config files"
curl -fsSL "$COMPOSE_URL"          -o docker-compose.yml       && ok "docker-compose.yml"
curl -fsSL "$TEMPORAL_CONFIG_URL"  -o temporal-dynamicconfig.yaml && ok "temporal-dynamicconfig.yaml"
curl -fsSL "$NGINX_CONFIG_URL"     -o nginx.selfhosted.conf    && ok "nginx.selfhosted.conf"

# ── Environment file ──────────────────────────────────────────────────────────
if [ ! -f .env ]; then
  curl -fsSL "$ENV_URL" -o .env && ok ".env template downloaded"

  if command -v openssl >/dev/null 2>&1; then
    step "Generating secrets"
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    DB_PASSWORD=$(openssl rand -hex 16)
    JWT_SECRET=$(openssl rand -hex 32)
    ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -d '/+=' | head -c 16)
    ADMIN_EMAIL="admin@orbis.local"

    sed "s/^ENCRYPTION_KEY=.*/ENCRYPTION_KEY=${ENCRYPTION_KEY}/" .env > .env.tmp && mv .env.tmp .env
    sed "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/"           .env > .env.tmp && mv .env.tmp .env
    sed "s/^JWT_SECRET=.*/JWT_SECRET=${JWT_SECRET}/"              .env > .env.tmp && mv .env.tmp .env

    # Write admin credentials (append, works regardless of template content)
    grep -v "^ADMIN_EMAIL="    .env > .env.tmp && mv .env.tmp .env
    grep -v "^ADMIN_PASSWORD=" .env > .env.tmp && mv .env.tmp .env
    { echo "ADMIN_EMAIL=${ADMIN_EMAIL}"; echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}"; } >> .env

    chmod 600 .env
    ok "Secrets generated"
  else
    warn "openssl not found — set ENCRYPTION_KEY, DB_PASSWORD, JWT_SECRET manually in .env"
  fi

  divider
  info "Review .env before starting (APP_URL, SMTP, etc.):"
  info "  nano ${INSTALL_DIR}/.env"
  echo ""
  ask "Open .env for editing now? [y/N] "
  read -r EDIT_ENV
  if [[ "${EDIT_ENV:-N}" =~ ^[Yy]$ ]]; then
    "${EDITOR:-nano}" .env
  fi
else
  ok ".env already exists — skipping"
fi

# ── Validate required secrets ─────────────────────────────────────────────────
check_env_var() {
  local key="$1"
  local val
  val=$(grep -E "^${key}=" .env 2>/dev/null | cut -d= -f2- | tr -d '[:space:]')
  [ -n "$val" ] || error "${key} is not set in .env — run: nano ${INSTALL_DIR}/.env"
}
check_env_var ENCRYPTION_KEY
check_env_var DB_PASSWORD
check_env_var JWT_SECRET

# ── Pull images ───────────────────────────────────────────────────────────────
step "Pulling images"
info "This may take a few minutes on the first install..."
echo ""
docker compose pull || error "Failed to pull images. Check your internet connection."

# ── Start ─────────────────────────────────────────────────────────────────────
divider
ask "Start Orbis now? [Y/n] "
read -r START_NOW
if [[ "${START_NOW:-Y}" =~ ^[Yy]$ ]]; then
  step "Starting Orbis"
  docker compose down -v --remove-orphans 2>/dev/null || true
  echo ""
  if ! docker compose up -d; then
    echo ""
    warn "Something went wrong. Container status:"
    docker compose ps
    echo ""
    warn "Diagnose with:"
    info "  docker compose -f ${INSTALL_DIR}/docker-compose.yml logs postgres"
    info "  docker compose -f ${INSTALL_DIR}/docker-compose.yml logs api"
    echo ""
    warn "Common causes:"
    info "  • postgres unhealthy  → missing secrets in .env"
    info "  • port 80 in use      → stop the conflicting process, then: cd ${INSTALL_DIR} && docker compose up -d"
    error "Startup failed. See above for details."
  fi

  # Read admin credentials from .env
  ADMIN_EMAIL_VAL=$(grep -E "^ADMIN_EMAIL="    .env 2>/dev/null | cut -d= -f2- | tr -d '[:space:]' || true)
  ADMIN_PASS_VAL=$(grep  -E "^ADMIN_PASSWORD=" .env 2>/dev/null | cut -d= -f2- | tr -d '[:space:]' || true)

  # Wait for the API to become healthy (up to 3 minutes)
  step "Waiting for services to be ready"
  WAIT_TRIES=0
  printf "  "
  until docker compose ps api 2>/dev/null | grep -q "(healthy)" || [ $WAIT_TRIES -ge 36 ]; do
    printf "."
    sleep 5
    WAIT_TRIES=$((WAIT_TRIES + 1))
  done
  echo ""
  if docker compose ps api 2>/dev/null | grep -q "(healthy)"; then
    ok "All services are ready"
  else
    warn "Services are taking longer than expected to start. Check logs with: docker compose logs"
  fi

  if command -v open >/dev/null 2>&1; then
    open "http://localhost" 2>/dev/null || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost" 2>/dev/null || true
  fi

  # ── Success banner ─────────────────────────────────────────────────────────
  echo ""
  echo -e "  ${G}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "  ${G}${BOLD}║           Orbis is up and running!               ║${NC}"
  echo -e "  ${G}${BOLD}╠══════════════════════════════════════════════════╣${NC}"
  echo -e "  ${G}${BOLD}║${NC}  ${W}URL:${NC}       http://localhost                      ${G}${BOLD}║${NC}"
  if [ -n "$ADMIN_EMAIL_VAL" ] && [ -n "$ADMIN_PASS_VAL" ]; then
  echo -e "  ${G}${BOLD}║${NC}                                                  ${G}${BOLD}║${NC}"
  echo -e "  ${G}${BOLD}║${NC}  ${W}Admin login (change after first sign-in):${NC}       ${G}${BOLD}║${NC}"
  echo -e "  ${G}${BOLD}║${NC}  ${C}Email:${NC}     ${ADMIN_EMAIL_VAL}$(printf '%*s' $((30 - ${#ADMIN_EMAIL_VAL})) '')${G}${BOLD}║${NC}"
  echo -e "  ${G}${BOLD}║${NC}  ${C}Password:${NC}  ${ADMIN_PASS_VAL}$(printf '%*s' $((30 - ${#ADMIN_PASS_VAL})) '')${G}${BOLD}║${NC}"
  fi
  echo -e "  ${G}${BOLD}╠══════════════════════════════════════════════════╣${NC}"
  echo -e "  ${G}${BOLD}║${NC}  ${DIM}Logs:  cd ~/orbis && docker compose logs -f${NC}    ${G}${BOLD}║${NC}"
  echo -e "  ${G}${BOLD}║${NC}  ${DIM}Stop:  cd ~/orbis && docker compose down${NC}       ${G}${BOLD}║${NC}"
  echo -e "  ${G}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
else
  divider
  info "Start later with:"
  info "  cd ${INSTALL_DIR} && docker compose up -d"
fi

# ── Telemetry ping (anonymous) ────────────────────────────────────────────────
curl -fsSL -X POST https://install.iamorbis.one/telemetry/install \
  -H "Content-Type: application/json" \
  -d "{\"version\":\"${ORBIS_VERSION}\",\"os\":\"$(uname -s)\"}" \
  --max-time 5 --silent > /dev/null 2>&1 || true
