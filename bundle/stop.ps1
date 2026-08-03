$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot
docker compose -p smokefire down
if ($LASTEXITCODE -ne 0) { throw "docker compose down failed." }
Write-Host "smokefire stopped. The smokefire-data volume was preserved."

