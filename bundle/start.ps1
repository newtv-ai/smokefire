$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

Write-Host "[1/5] Verifying deployment files..."
& (Join-Path $PSScriptRoot "verify.ps1")

Write-Host "[2/5] Checking Docker..."
docker info | Out-Null
docker compose version | Out-Null

if (-not (Test-Path -LiteralPath ".env")) {
    Copy-Item -LiteralPath ".env.example" -Destination ".env"
    Write-Host "Created .env from .env.example"
}

Write-Host "[3/5] Importing the prebuilt image when needed..."
$imageExists = docker image ls --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -eq "smokefire:1.0.0-cpu" }
if (-not $imageExists) {
    docker image load --input ".\images\smokefire-1.0.0-cpu.tar.gz"
    if ($LASTEXITCODE -ne 0) { throw "Docker image import failed." }
} else {
    Write-Host "Image smokefire:1.0.0-cpu is already available."
}

Write-Host "[4/5] Starting smokefire..."
docker compose -p smokefire up -d
if ($LASTEXITCODE -ne 0) { throw "docker compose up failed." }

Write-Host "[5/5] Waiting for readiness (up to 5 minutes)..."
$ready = $false
for ($attempt = 1; $attempt -le 60; $attempt++) {
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:8600/api/health/ready" -TimeoutSec 3
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    } catch {
        Start-Sleep -Seconds 5
    }
}

if (-not $ready) {
    docker compose -p smokefire ps
    docker compose -p smokefire logs --tail 200 smokefire
    throw "smokefire did not become ready within 5 minutes."
}

Write-Host "smokefire 1.0.0 is ready: http://127.0.0.1:8600"
