[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Arguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-UpsunExecutable {
    param(
        [string] $BaseDirectory
    )

    $candidates = @(
        'upsun.exe',
        'upsun-windows-amd64.exe',
        'upsun-windows.exe',
        'upsun-win64.exe'
    )

    foreach ($candidate in $candidates) {
        $candidatePath = Join-Path -Path $BaseDirectory -ChildPath $candidate
        if (Test-Path -LiteralPath $candidatePath) {
            return $candidatePath
        }
    }

    $fallback = Get-ChildItem -Path $BaseDirectory -Filter 'upsun*.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($fallback) {
        return $fallback.FullName
    }

    throw 'Unable to locate upsun executable next to the shim.'
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$target = Find-UpsunExecutable -BaseDirectory $scriptDirectory

& $target @Arguments
exit $LASTEXITCODE
