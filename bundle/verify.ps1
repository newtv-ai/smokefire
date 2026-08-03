$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

if (-not (Test-Path -LiteralPath "SHA256SUMS")) {
    throw "SHA256SUMS is missing."
}

$checked = 0
Get-Content -LiteralPath "SHA256SUMS" -Encoding UTF8 | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith("#")) { return }
    $parts = $line -split "\s+", 2
    if ($parts.Count -ne 2) { throw "Invalid SHA256SUMS line: $line" }
    $expected = $parts[0].ToLowerInvariant()
    $relative = $parts[1].Trim().Replace("/", "\")
    if (-not (Test-Path -LiteralPath $relative -PathType Leaf)) {
        throw "Missing file: $relative"
    }
    $actual = (Get-FileHash -LiteralPath $relative -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected) {
        throw "SHA-256 mismatch: $relative"
    }
    $checked++
    Write-Host "OK  $relative"
}

if ($checked -eq 0) { throw "SHA256SUMS did not contain any files." }
Write-Host "Verified $checked files."
