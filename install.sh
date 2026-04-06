#!/usr/bin/env bash
set -euo pipefail

# ── Orbis Installer ──────────────────────────────────────────────────────────
# Usage: bash <(curl -fsSL https://install.iamorbis.one/install.sh)
# -----------------------------------------------------------------------------

ORBIS_VERSION="${ORBIS_VERSION:-latest}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/orbis}"
PRIMARY_BASE_URL="https://install.iamorbis.one"
MIRROR_BASE_URL="https://raw.githubusercontent.com/HAANGroup/ooainstall/master"

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

BOX_WIDTH=56
BOX_MAX_WIDTH=76

box_utf8_enabled() {
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *UTF-8*|*utf8*) return 0 ;;
    *) return 1 ;;
  esac
}

box_chars() {
  if box_utf8_enabled; then
    BOX_TOP_LEFT='╔'; BOX_TOP_JOIN='╠'; BOX_BOTTOM_LEFT='╚'
    BOX_TOP_RIGHT='╗'; BOX_TOP_FILL='═'; BOX_SIDE='║'
    BOX_MID_RIGHT='╣'; BOX_BOTTOM_RIGHT='╝'
  else
    BOX_TOP_LEFT='+'; BOX_TOP_JOIN='+'; BOX_BOTTOM_LEFT='+'
    BOX_TOP_RIGHT='+'; BOX_TOP_FILL='-'; BOX_SIDE='|'
    BOX_MID_RIGHT='+'; BOX_BOTTOM_RIGHT='+'
  fi
}

wrap_box_text() {
  local text="$1"
  local width="$2"
  local line=""
  local word=""
  local remaining=""
  local chunk=""

  if [ -z "$text" ]; then
    printf '%s\n' ""
    return
  fi

  for word in $text; do
    if [ ${#word} -gt "$width" ]; then
      if [ -n "$line" ]; then
        printf '%s\n' "$line"
        line=""
      fi

      remaining="$word"
      while [ ${#remaining} -gt "$width" ]; do
        chunk=${remaining:0:$width}
        printf '%s\n' "$chunk"
        remaining=${remaining:$width}
      done

      if [ -n "$remaining" ]; then
        line="$remaining"
      fi
      continue
    fi

    if [ -z "$line" ]; then
      line="$word"
      continue
    fi
    if [ $(( ${#line} + 1 + ${#word} )) -le "$width" ]; then
      line="${line} ${word}"
    else
      printf '%s\n' "$line"
      line="$word"
    fi
  done

  if [ -n "$line" ]; then
    printf '%s\n' "$line"
  fi
}

print_box_border() {
  local left="$1"
  local fill="$2"
  local right="$3"
  local line
  line=$(printf "%${BOX_WIDTH}s" "")
  line=${line// /$fill}
  printf "  ${G}${BOLD}%s%s%s${NC}\n" "$left" "$line" "$right"
}

print_box_line() {
  local text="$1"
  local width="$BOX_WIDTH"
  local line

  if [ -z "$text" ]; then
    printf "  ${G}${BOLD}%s${NC} %-*s ${G}${BOLD}%s${NC}\n" "$BOX_SIDE" "$width" "" "$BOX_SIDE"
    return
  fi

  while IFS= read -r line; do
    printf "  ${G}${BOLD}%s${NC} %-*s ${G}${BOLD}%s${NC}\n" "$BOX_SIDE" "$width" "$line" "$BOX_SIDE"
  done < <(wrap_box_text "$text" "$width")
}

download_file() {
  local path="$1"
  local output="$2"
  local url

  for base in "$MIRROR_BASE_URL" "$PRIMARY_BASE_URL"; do
    url="${base}/${path}"
    if curl -fsSL "$url" -o "$output"; then
      ok "${output}"
      return 0
    fi
  done

  error "Failed to download ${path} from all installer sources."
}

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
download_file "docker-compose.yml" docker-compose.yml
download_file "temporal-dynamicconfig.yaml" temporal-dynamicconfig.yaml
download_file "nginx.selfhosted.conf" nginx.selfhosted.conf

# ── Environment file ──────────────────────────────────────────────────────────
if [ ! -f .env ]; then
  download_file ".env.example" .env

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
  box_chars

  BOX_LINES=(
    "Orbis is up and running!"
    "URL: http://localhost"
    "Logs: cd ${INSTALL_DIR} && docker compose logs -f"
    "Stop: cd ${INSTALL_DIR} && docker compose down"
  )

  if [ -n "$ADMIN_EMAIL_VAL" ] && [ -n "$ADMIN_PASS_VAL" ]; then
    BOX_LINES+=("" "Admin login (change after first sign-in):" "Email: ${ADMIN_EMAIL_VAL}" "Password: ${ADMIN_PASS_VAL}")
  fi

  max_line_length=0
  for line in "${BOX_LINES[@]}"; do
    [ "${#line}" -gt "$max_line_length" ] && max_line_length=${#line}
  done
  if [ "$max_line_length" -gt "$BOX_MAX_WIDTH" ]; then
    BOX_WIDTH="$BOX_MAX_WIDTH"
  elif [ "$max_line_length" -gt "$BOX_WIDTH" ]; then
    BOX_WIDTH="$max_line_length"
  fi

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
  print_box_border "$BOX_TOP_LEFT" "$BOX_TOP_FILL" "$BOX_TOP_RIGHT"
  print_box_line "Orbis is up and running!"
  print_box_border "$BOX_TOP_JOIN" "$BOX_TOP_FILL" "$BOX_MID_RIGHT"
  print_box_line "URL: http://localhost"
  if [ -n "$ADMIN_EMAIL_VAL" ] && [ -n "$ADMIN_PASS_VAL" ]; then
    print_box_line ""
    print_box_line "Admin login (change after first sign-in):"
    print_box_line "Email: ${ADMIN_EMAIL_VAL}"
    print_box_line "Password: ${ADMIN_PASS_VAL}"
  fi
  print_box_border "$BOX_TOP_JOIN" "$BOX_TOP_FILL" "$BOX_MID_RIGHT"
  print_box_line "Logs: cd ${INSTALL_DIR} && docker compose logs -f"
  print_box_line "Stop: cd ${INSTALL_DIR} && docker compose down"
  print_box_border "$BOX_BOTTOM_LEFT" "$BOX_TOP_FILL" "$BOX_BOTTOM_RIGHT"
  echo ""
else
  divider
  info "Start later with:"
  info "  cd ${INSTALL_DIR} && docker compose up -d"
fi

# ── Telemetry ping (anonymous) ────────────────────────────────────────────────
curl -fsSL -X POST "${PRIMARY_BASE_URL}/telemetry/install" \
  -H "Content-Type: application/json" \
  -d "{\"version\":\"${ORBIS_VERSION}\",\"os\":\"$(uname -s)\"}" \
  --max-time 5 --silent > /dev/null 2>&1 || true
