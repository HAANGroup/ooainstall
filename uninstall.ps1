# ── Orbis Uninstaller for Windows (PowerShell) ───────────────────────────────
# Usage: irm https://install.iamorbis.one/uninstall.ps1 | iex
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"

$InstallDir = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else { "$env:USERPROFILE\orbis" }

function Write-Info    { param($msg) Write-Host "[orbis] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[orbis] $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "[orbis] $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "[orbis] ERROR: $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "  ██████╗ ██████╗ ██████╗ ██╗███████╗" -ForegroundColor Magenta
Write-Host "  ██╔═══██╗██╔══██╗██╔══██╗██║██╔════╝" -ForegroundColor Magenta
Write-Host "  ██║   ██║██████╔╝██████╔╝██║███████╗" -ForegroundColor Magenta
Write-Host "  ██║   ██║██╔══██╗██╔══██╗██║╚════██║" -ForegroundColor Magenta
Write-Host "  ╚██████╔╝██║  ██║██████╔╝██║███████║" -ForegroundColor Magenta
Write-Host "   ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝╚══════╝" -ForegroundColor Magenta
Write-Host ""
Write-Warn "Orbis Uninstaller"
Write-Host ""

# ── Check install dir exists ──────────────────────────────────────────────────
if (-not (Test-Path $InstallDir)) {
    Write-Err "Orbis install directory not found: $InstallDir"
}

# ── Confirm ───────────────────────────────────────────────────────────────────
Write-Warn "This will:"
Write-Warn "  * Stop and remove all Orbis containers"
Write-Warn "  * Delete all Docker volumes (your database and data will be lost)"
Write-Warn "  * Remove the install directory: $InstallDir"
Write-Host ""
$confirm = Read-Host "  Are you sure you want to uninstall Orbis? [y/N]"
if ($confirm -notmatch "^[Yy]$") {
    Write-Info "Uninstall cancelled."
    exit 0
}

# ── Offer backup before wiping ────────────────────────────────────────────────
Write-Host ""
$doBackup = Read-Host "  Create a database backup before uninstalling? [Y/n]"
if ($doBackup -eq "" -or $doBackup -match "^[Yy]") {
    $backupFile = "$env:USERPROFILE\orbis-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').sql"
    Write-Info "Backing up database to $backupFile ..."
    try {
        docker compose -f "$InstallDir\docker-compose.yml" exec -T postgres `
            pg_dump -U orbis orbis | Out-File -FilePath $backupFile -Encoding utf8
        Write-Success "Backup saved to $backupFile"
    } catch {
        Write-Warn "Backup failed (containers may already be stopped). Continuing without backup."
        Remove-Item -Path $backupFile -ErrorAction SilentlyContinue
    }
}

# ── Stop and remove containers + volumes ─────────────────────────────────────
Write-Host ""
Write-Info "Stopping Orbis containers..."
if (Test-Path "$InstallDir\docker-compose.yml") {
    try {
        docker compose -f "$InstallDir\docker-compose.yml" down --volumes --remove-orphans
    } catch {
        Write-Warn "Could not stop containers cleanly. Continuing..."
    }
}

# ── Remove Docker images ──────────────────────────────────────────────────────
Write-Host ""
$rmImages = Read-Host "  Remove Orbis Docker images to free disk space? [Y/n]"
if ($rmImages -eq "" -or $rmImages -match "^[Yy]") {
    Write-Info "Removing Orbis images..."
    try {
        docker images --format "{{.Repository}}:{{.Tag}}" |
            Where-Object { $_ -like "iamorbis/*" } |
            ForEach-Object { docker rmi -f $_ }
        Write-Success "Images removed."
    } catch {
        Write-Warn "Could not remove some images. You can remove them manually in Docker Desktop."
    }
}

# ── Remove install directory ──────────────────────────────────────────────────
Write-Host ""
Write-Info "Removing install directory: $InstallDir ..."
Remove-Item -Recurse -Force $InstallDir

Write-Host ""
Write-Success "Orbis has been uninstalled."
