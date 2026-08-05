param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("direct", "builtin", "upstream")]
    [string]$Mode,
    [string]$Api,
    [string]$Rtsp
)

$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

if (-not (Test-Path -LiteralPath ".env")) {
    Copy-Item -LiteralPath ".env.example" -Destination ".env"
}

function Set-EnvValue {
    param([string]$Name, [string]$Value)
    $content = @(Get-Content -LiteralPath ".env" -Encoding UTF8)
    $pattern = "^$([regex]::Escape($Name))="
    $found = $false
    for ($index = 0; $index -lt $content.Count; $index++) {
        if ($content[$index] -match $pattern) {
            $content[$index] = "$Name=$Value"
            $found = $true
        }
    }
    if (-not $found) { $content += "$Name=$Value" }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot ".env"), $content, $utf8NoBom)
}

switch ($Mode) {
    "direct" {
        Set-EnvValue "SMOKEFIRE_GO2RTC_ENABLED" "false"
        Set-EnvValue "SMOKEFIRE_UPSTREAM_GO2RTC_ENABLED" "false"
        Write-Host "Direct RTSP mode configured. Add camera/NVR URLs in smokefire."
    }
    "builtin" {
        Set-EnvValue "SMOKEFIRE_GO2RTC_ENABLED" "true"
        Set-EnvValue "SMOKEFIRE_UPSTREAM_GO2RTC_ENABLED" "false"
        Write-Host "Bundled go2rtc mode configured. Cameras added in smokefire will be fanned out automatically."
    }
    "upstream" {
        if (-not $Api -or -not $Rtsp) {
            throw "Upstream mode requires both -Api and -Rtsp, for example http://host.docker.internal:1984 and rtsp://host.docker.internal:8554."
        }
        Set-EnvValue "SMOKEFIRE_GO2RTC_ENABLED" "false"
        Set-EnvValue "SMOKEFIRE_UPSTREAM_GO2RTC_ENABLED" "true"
        Set-EnvValue "SMOKEFIRE_UPSTREAM_GO2RTC_API" $Api.TrimEnd("/")
        Set-EnvValue "SMOKEFIRE_UPSTREAM_GO2RTC_RTSP" $Rtsp.TrimEnd("/")
        Write-Host "Existing go2rtc configured. All main streams from GET /api/streams will be imported automatically."
    }
}

# No "2>$null" here: Windows PowerShell turns redirected native stderr into a
# terminating NativeCommandError while $ErrorActionPreference is Stop. The command
# stays silent and exits 0 when the project is not running, so no redirect is needed.
$running = docker compose -p smokefire ps --status running --quiet smokefire
if ($LASTEXITCODE -eq 0 -and $running) {
    docker compose -p smokefire up -d --force-recreate smokefire
    if ($LASTEXITCODE -ne 0) { throw "Failed to recreate smokefire." }
    Write-Host "smokefire was restarted with the new video source mode."
} else {
    Write-Host "Run .\start.ps1 to start smokefire with this configuration."
}
