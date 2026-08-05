$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

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
            throw "Offline image archive is missing from images/."
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
        docker image load --input $archive
        if ($LASTEXITCODE -ne 0) { throw "Docker image import failed." }
    } finally {
        if ($temporaryArchive -and (Test-Path -LiteralPath $temporaryArchive)) {
            Remove-Item -LiteralPath $temporaryArchive -Force
        }
    }
}

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
if ($LASTEXITCODE -ne 0) { throw "docker compose up failed." }

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
    docker compose -p smokefire ps
    docker compose -p smokefire logs --tail 200 smokefire
    throw "smokefire did not become ready within 5 minutes."
}

Write-Host "smokefire 1.0.0 is ready: http://127.0.0.1:$servicePort"
if ((Get-EnvValue -Name "SMOKEFIRE_UPSTREAM_GO2RTC_ENABLED") -eq "true") {
    Write-Host "Existing go2rtc sync is enabled. Streams are imported from /api/streams automatically."
}
