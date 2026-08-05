param([switch]$NoPause)

# Keep this file pure ASCII. Windows PowerShell 5.1 reads a .ps1 without a BOM
# using the system ANSI code page, so non-ASCII comments are decoded wrongly and
# can break parsing of the whole script on a machine with a different locale.

$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

# Record everything to a log file. When a deployment fails, sending this one file
# is enough to diagnose it: no screenshots, no recalling what scrolled past.
$logPath = Join-Path $PSScriptRoot "start-log.txt"
$transcriptStarted = $false
try {
    Start-Transcript -LiteralPath $logPath -Force | Out-Null
    $transcriptStarted = $true
} catch {
    Write-Host "Could not write the log file at $logPath. Continuing without it."
}

function Exit-Run {
    param([int]$Code)
    if ($transcriptStarted) { try { Stop-Transcript | Out-Null } catch { } }
    # When the script is double-clicked, or started through the right-click
    # "Run with PowerShell" entry, the console window closes the instant the
    # script ends and the error is gone before it can be read. That is where
    # reports of "it just exits halfway" come from. Hold the window here.
    # Pass -NoPause for automated use. Never pause when stdin is redirected
    # (CI, or being called from another script) or the run would hang forever.
    if (-not $NoPause -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        Write-Host ""
        Write-Host "Press Enter to close this window..."
        [void][Console]::ReadLine()
    }
    exit $Code
}

function Get-EnvValue {
    param([Parameter(Mandatory = $true)][string]$Name)
    $line = Get-Content -LiteralPath ".env" -Encoding UTF8 |
        Where-Object { $_ -match "^$([regex]::Escape($Name))=" } |
        Select-Object -Last 1
    if (-not $line) { return $null }
    return ($line -split "=", 2)[1].Trim()
}

function Test-DockerImage {
    param([Parameter(Mandatory = $true)][string]$Reference)
    # "docker images --quiet" prints nothing and exits 0 when the image is absent,
    # so it never writes to stderr. Do not go back to
    # "docker image inspect <ref> *> $null": Windows PowerShell turns redirected
    # native stderr into a terminating NativeCommandError while
    # $ErrorActionPreference is Stop, which aborted this script on every clean host.
    $imageId = docker images --quiet $Reference | Select-Object -First 1
    return -not [string]::IsNullOrWhiteSpace($imageId)
}

function Import-OfflineImages {
    $archive = Join-Path $PSScriptRoot "images\smokefire-images.tar.gz"
    $temporaryArchive = $null

    if (-not (Test-Path -LiteralPath $archive)) {
        $parts = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot "images") `
            -Filter "smokefire-images.tar.gz.part*" -File | Sort-Object Name)
        if ($parts.Count -eq 0) {
            throw "No offline image was found in images\. The GPU bundle needs every smokefire-images.tar.gz.partNN asset from the same Release placed in that folder."
        }

        $temporaryArchive = Join-Path $PSScriptRoot "images\smokefire-images.assembled.tar.gz"
        if (Test-Path -LiteralPath $temporaryArchive) {
            Remove-Item -LiteralPath $temporaryArchive -Force
        }
        $output = [System.IO.File]::Open($temporaryArchive, [System.IO.FileMode]::CreateNew)
        try {
            foreach ($part in $parts) {
                Write-Host "Assembling $($part.Name)..."
                $partStream = [System.IO.File]::OpenRead($part.FullName)
                try { $partStream.CopyTo($output) } finally { $partStream.Dispose() }
            }
        } finally {
            $output.Dispose()
        }
        $archive = $temporaryArchive
    }

    try {
        Write-Host "Loading the images into Docker. This takes several minutes and shows no progress bar."
        docker image load --input $archive
        if ($LASTEXITCODE -ne 0) { throw "Docker refused to load the offline image archive." }
    } finally {
        if ($temporaryArchive -and (Test-Path -LiteralPath $temporaryArchive)) {
            Remove-Item -LiteralPath $temporaryArchive -Force
        }
    }
}

try {
    Write-Host "[1/5] Verifying deployment files..."
    & (Join-Path $PSScriptRoot "verify.ps1")

    Write-Host "[2/5] Checking Docker..."
    docker info | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not reachable. Start Docker Desktop (or the docker service), wait until it reports Running, then run this script again."
    }
    docker compose version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose v2 is not available. Install Compose v2, then run this script again."
    }

    if (-not (Test-Path -LiteralPath ".env")) {
        Copy-Item -LiteralPath ".env.example" -Destination ".env"
        Write-Host "Created .env from .env.example"
    }

    $appImage = Get-EnvValue -Name "SMOKEFIRE_IMAGE"
    if (-not $appImage) { $appImage = "smokefire:1.0.0-cpu" }
    $servicePort = Get-EnvValue -Name "SMOKEFIRE_PORT"
    if (-not $servicePort) { $servicePort = "8600" }
    $go2rtcImage = "alexxit/go2rtc:1.9.9"

    Write-Host "[3/5] Importing the prebuilt smokefire and go2rtc images when needed..."
    $appMissing = -not (Test-DockerImage -Reference $appImage)
    $go2rtcMissing = -not (Test-DockerImage -Reference $go2rtcImage)
    if ($appMissing -or $go2rtcMissing) {
        Import-OfflineImages
    } else {
        Write-Host "Images $appImage and $go2rtcImage are already available."
    }

    Write-Host "[4/5] Starting smokefire..."
    docker compose -p smokefire up -d
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose up failed. The lines above show what Docker reported. A GPU bundle also needs Docker Desktop GPU support and a working NVIDIA driver."
    }

    Write-Host "[5/5] Waiting for readiness (up to 5 minutes)..."
    $readyResponse = $null
    for ($attempt = 1; $attempt -le 60; $attempt++) {
        try {
            $readyResponse = Invoke-RestMethod -Uri "http://127.0.0.1:$servicePort/api/health/ready" -TimeoutSec 3
            break
        } catch {
            Start-Sleep -Seconds 5
        }
    }

    if (-not $readyResponse) {
        Write-Host ""
        Write-Host "Readiness did not pass. Container status and the last 200 log lines follow."
        docker compose -p smokefire ps
        docker compose -p smokefire logs --tail 200 smokefire
        throw "smokefire did not become ready within 5 minutes."
    }

    Write-Host ""
    Write-Host "smokefire 1.0.0 is ready: http://127.0.0.1:$servicePort"
    if ((Get-EnvValue -Name "SMOKEFIRE_UPSTREAM_GO2RTC_ENABLED") -eq "true") {
        Write-Host "Existing go2rtc sync is enabled. Streams are imported from /api/streams automatically."
    }
    Write-Host "Log written to $logPath"
} catch {
    Write-Host ""
    Write-Host "============================================================"
    Write-Host " Deployment failed"
    Write-Host "============================================================"
    Write-Host " Reason: $($_.Exception.Message)"
    Write-Host ""
    Write-Host " Full log: $logPath"
    Write-Host " Send that one file to support. No screenshots needed."
    Write-Host "============================================================"
    Exit-Run 1
}

Exit-Run 0
