# ── Orbis Installer for Windows (PowerShell) ─────────────────────────────────
# Usage: irm https://install.iamorbis.one/install.ps1 | iex
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"

$OrbisVersion  = if ($env:ORBIS_VERSION) { $env:ORBIS_VERSION } else { "latest" }
$InstallDir    = if ($env:INSTALL_DIR)   { $env:INSTALL_DIR   } else { "$env:USERPROFILE\orbis" }
$PrimaryBaseUrl      = "https://install.iamorbis.one"
$MirrorBaseUrl       = "https://raw.githubusercontent.com/HAANGroup/ooainstall/master"
$script:BoxWidth      = 48
$script:BoxMaxWidth   = 76

function Write-Info    { param($msg) Write-Host "[orbis] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[orbis] $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "[orbis] $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "[orbis] ERROR: $msg" -ForegroundColor Red; exit 1 }

function New-RandomHex { param($bytes) -join ((1..$bytes) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) }) }

function Write-BoxLine {
    param(
        [string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::Green
    )

    $width = $script:BoxWidth
    if ([string]::IsNullOrEmpty($Text)) {
        Write-Host ("  | {0} |" -f "".PadRight($width)) -ForegroundColor $Color
        return
    }

    $words = $Text -split '\s+'
    $line = ""

    foreach ($word in $words) {
        if ($word.Length -gt $width) {
            if ($line.Length -gt 0) {
                Write-Host ("  | {0} |" -f $line.PadRight($width)) -ForegroundColor $Color
                $line = ""
            }

            $offset = 0
            while ($offset -lt $word.Length) {
                $length = [Math]::Min($width, $word.Length - $offset)
                $content = $word.Substring($offset, $length).PadRight($width)
                Write-Host ("  | {0} |" -f $content) -ForegroundColor $Color
                $offset += $length
            }
            continue
        }

        if ($line.Length -eq 0) {
            $line = $word
            continue
        }

        if (($line.Length + 1 + $word.Length) -le $width) {
            $line = "$line $word"
        } else {
            Write-Host ("  | {0} |" -f $line.PadRight($width)) -ForegroundColor $Color
            $line = $word
        }
    }

    if ($line.Length -gt 0) {
        Write-Host ("  | {0} |" -f $line.PadRight($width)) -ForegroundColor $Color
    }
}

function Write-BoxBorder {
    $fill = "".PadLeft($script:BoxWidth, "-")
    Write-Host ("  +{0}+" -f $fill) -ForegroundColor Green
}

function Write-BannerLine {
    param([string]$Text)

    $esc = [char]27
    Write-Host "$esc[1;36m$Text$esc[0m"
}

function Get-OrbisFile {
    param(
        [string]$Path,
        [string]$OutFile
    )

    $sources = @(
        "$MirrorBaseUrl/$Path",
        "$PrimaryBaseUrl/$Path"
    )

    foreach ($source in $sources) {
        try {
            Invoke-WebRequest -Uri $source -OutFile $OutFile
            Write-Success "$OutFile downloaded"
            return
        } catch { }
    }

    Write-Err "Failed to download $Path from all installer sources."
}

Write-Host ""
Write-BannerLine "    ██████╗ ██████╗ ██████╗ ██╗███████╗"
Write-BannerLine "   ██╔═══██╗██╔══██╗██╔══██╗██║██╔════╝"
Write-BannerLine "   ██║   ██║██████╔╝██████╔╝██║███████╗"
Write-BannerLine "   ██║   ██║██╔══██╗██╔══██╗██║╚════██║"
Write-BannerLine "   ╚██████╔╝██║  ██║██████╔╝██║███████║"
Write-BannerLine "    ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝╚══════╝"
Write-Host ""
Write-Info "Orbis Self-Hosted Installer — version: $OrbisVersion"
Write-Host ""

# ── Check prerequisites ───────────────────────────────────────────────────────
try { docker --version | Out-Null } catch { Write-Err "Docker not found. Install from https://docs.docker.com/desktop/windows/" }

try { docker info | Out-Null } catch {
    Write-Err "Docker is installed but not running. Please start Docker Desktop and re-run this installer."
}

try { docker compose version | Out-Null } catch { Write-Err "Docker Compose plugin not found." }

Write-Info "Docker found: $(docker --version)"
Write-Info "Compose found: $(docker compose version)"
Write-Host ""

# ── Install directory ─────────────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Set-Location $InstallDir
Write-Info "Installing into: $InstallDir"

# ── Download compose + env ────────────────────────────────────────────────────
Get-OrbisFile -Path "docker-compose.yml" -OutFile "docker-compose.yml"
Get-OrbisFile -Path "temporal-dynamicconfig.yaml" -OutFile "temporal-dynamicconfig.yaml"
Get-OrbisFile -Path "nginx.selfhosted.conf" -OutFile "nginx.selfhosted.conf"

if (-not (Test-Path ".env")) {
    Get-OrbisFile -Path ".env.example" -OutFile ".env"

    # ── Auto-generate required secrets ────────────────────────────────────────
    Write-Info "Auto-generating secrets..."
    $encryptionKey = New-RandomHex 32
    $dbPassword    = New-RandomHex 16
    $jwtSecret     = New-RandomHex 32

    # Generate a random admin password (16 alphanumeric chars)
    $adminEmail    = "admin@orbis.local"
    $adminPassword = -join ((1..16) | ForEach-Object { [char](Get-Random -InputObject (@(48..57) + @(65..90) + @(97..122))) })

    $envContent = Get-Content ".env" -Raw
    $envContent = $envContent -replace '(?m)^ENCRYPTION_KEY=.*', "ENCRYPTION_KEY=$encryptionKey"
    $envContent = $envContent -replace '(?m)^DB_PASSWORD=.*',    "DB_PASSWORD=$dbPassword"
    $envContent = $envContent -replace '(?m)^JWT_SECRET=.*',     "JWT_SECRET=$jwtSecret"
    if ($envContent -match '(?m)^ADMIN_EMAIL=') {
        $envContent = $envContent -replace '(?m)^ADMIN_EMAIL=.*', "ADMIN_EMAIL=$adminEmail"
    } else {
        $envContent = $envContent.TrimEnd() + "`nADMIN_EMAIL=$adminEmail"
    }
    if ($envContent -match '(?m)^ADMIN_PASSWORD=') {
        $envContent = $envContent -replace '(?m)^ADMIN_PASSWORD=.*', "ADMIN_PASSWORD=$adminPassword"
    } else {
        $envContent = $envContent.TrimEnd() + "`nADMIN_PASSWORD=$adminPassword"
    }
    Set-Content ".env" $envContent -NoNewline
    icacls ".env" /inheritance:r /grant:r "${env:USERNAME}:F" | Out-Null
    Write-Success "Secrets generated and written to .env"

    Write-Host ""
    Write-Warn "Review your .env before starting (APP_URL, SMTP, etc.):"
    Write-Warn "  notepad $InstallDir\.env"
    Write-Host ""
    $editNow = Read-Host "  Open .env for editing now? [Y/n]"
    if ($editNow -eq "" -or $editNow -match "^[Yy]") {
        notepad.exe ".env"
        Read-Host "  Press Enter when done editing .env"
    }
} else {
    Write-Info ".env already exists, skipping template."
}

# ── Validate required secrets are set ────────────────────────────────────────
function Assert-EnvVar {
    param($key)
    $line = Get-Content ".env" | Where-Object { $_ -match "^$key=(.+)" }
    if (-not $line) { Write-Err "$key is not set in .env. Run: notepad $InstallDir\.env" }
}
Assert-EnvVar "ENCRYPTION_KEY"
Assert-EnvVar "DB_PASSWORD"
Assert-EnvVar "JWT_SECRET"

# ── Pull images ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Info "Pulling Orbis images (this may take a few minutes)..."
try {
    docker compose pull
} catch {
    Write-Err "Failed to pull images. Check your internet connection and try again.`n  If the problem persists: https://docs.iamorbis.one/self-hosted/troubleshooting"
}

# ── Start ─────────────────────────────────────────────────────────────────────
Write-Host ""
$startNow = Read-Host "  Start Orbis now? [Y/n]"
if ($startNow -eq "" -or $startNow -match "^[Yy]") {
    # Remove any stale volumes from a previous install so postgres initialises
    # fresh with the current DB_PASSWORD (volumes persist across removing the install dir).
    docker compose down -v --remove-orphans 2>$null

    try {
        docker compose up -d

        # Wait for the API to become healthy (up to 3 minutes)
        Write-Info "Waiting for services to be ready..."
        $waitTries = 0
        while ($waitTries -lt 36) {
            $status = docker compose ps api 2>$null | Out-String
            if ($status -match "\(healthy\)") { break }
            Start-Sleep -Seconds 5
            $waitTries++
        }
        $finalStatus = docker compose ps api 2>$null | Out-String
        if ($finalStatus -match "\(healthy\)") {
            Write-Success "All services are ready"
        } else {
            Write-Warn "Services are taking longer than expected. Check logs with: docker compose logs"
        }

        # Read admin credentials from .env (may have been set above or pre-existing)
        $adminEmailVal = (Get-Content ".env" | Where-Object { $_ -match "^ADMIN_EMAIL=(.+)" } | Select-Object -First 1) -replace "^ADMIN_EMAIL=", ""
        $adminPassVal  = (Get-Content ".env" | Where-Object { $_ -match "^ADMIN_PASSWORD=(.+)" } | Select-Object -First 1) -replace "^ADMIN_PASSWORD=", ""
        $boxLines = @(
            "Orbis is up and running!",
            "URL: http://localhost",
            "Logs: cd $InstallDir && docker compose logs -f",
            "Stop: cd $InstallDir && docker compose down"
        )
        if ($adminEmailVal -and $adminPassVal) {
            $boxLines += @(
                "",
                "Admin login (change after first sign-in):",
                "Email: $adminEmailVal",
                "Password: $adminPassVal"
            )
        }
        $maxLineLength = ($boxLines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
        if ($maxLineLength -gt $script:BoxMaxWidth) {
            $script:BoxWidth = $script:BoxMaxWidth
        } elseif ($maxLineLength -gt $script:BoxWidth) {
            $script:BoxWidth = $maxLineLength
        }

        Write-Host ""
        Write-BoxBorder
        Write-BoxLine "Orbis is up and running!"
        Write-BoxBorder
        Write-BoxLine "URL: http://localhost"
        if ($adminEmailVal -and $adminPassVal) {
            Write-BoxLine ""
            Write-BoxLine "Admin login (change after first sign-in):"
            Write-BoxLine "Email: $adminEmailVal"
            Write-BoxLine "Password: $adminPassVal"
        }
        Write-BoxBorder
        Write-BoxLine "Logs: cd $InstallDir && docker compose logs -f" ([ConsoleColor]::DarkGray)
        Write-BoxLine "Stop: cd $InstallDir && docker compose down" ([ConsoleColor]::DarkGray)
        Write-BoxBorder
        Write-Host ""

        Start-Process "http://localhost"
    } catch {
        Write-Host ""
        Write-Warn "Something went wrong starting Orbis. Checking container status..."
        Write-Host ""
        docker compose ps
        Write-Host ""
        Write-Warn "Check logs with:"
        Write-Warn "  docker compose -f $InstallDir\docker-compose.yml logs postgres"
        Write-Warn "  docker compose -f $InstallDir\docker-compose.yml logs api"
        Write-Host ""
        Write-Warn "Common fixes:"
        Write-Warn "  * 'postgres is unhealthy'  -> your .env secrets are missing. Run: notepad $InstallDir\.env"
        Write-Warn "  * 'port 80 already in use' -> stop the process using port 80 and re-run: cd $InstallDir; docker compose up -d"
        Write-Warn "  * 'image not found'        -> re-run the installer to pull fresh images"
        Write-Host ""
        Write-Warn "Full troubleshooting guide: https://docs.iamorbis.one/self-hosted/troubleshooting"
        exit 1
    }
} else {
    Write-Host ""
    Write-Info "To start later:"
    Write-Info "  cd $InstallDir; docker compose up -d"
}

Write-Host ""
# ── Telemetry ping (anonymous) ────────────────────────────────────────────────
try {
    $body = "{`"version`":`"$OrbisVersion`",`"os`":`"Windows`"}"
    Invoke-WebRequest -Uri "$PrimaryBaseUrl/telemetry/install" `
        -Method POST -Body $body -ContentType "application/json" `
        -TimeoutSec 5 -UseBasicParsing | Out-Null
} catch { }

Write-Success "Installation complete."
