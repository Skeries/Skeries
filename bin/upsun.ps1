param(
    [Parameter(ValueFromRemainingArguments=$true)]
    $args
)

# Try to run the Linux script via WSL if available
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    wsl bash -lc "$(wslpath -a '$(Split-Path -Parent $MyInvocation.MyCommand.Path)')/../scripts/upsun $args"
    exit $LASTEXITCODE
} else {
    Write-Host "This shim expects WSL to be installed on Windows."
    Write-Host "Alternatively, install Upsun natively on a Linux machine or run this repository inside WSL." 
    exit 1
}
