$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$upsunScript = Join-Path $scriptDir 'upsun-cli.ps1'

if (-not (Test-Path $upsunScript)) {
    throw "Unable to locate the UpSun CLI entry point at '$upsunScript'."
}

$pwsh = Get-Command -Name 'pwsh' -ErrorAction SilentlyContinue
if ($pwsh) {
    & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File $upsunScript @args
} else {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $upsunScript @args
}
