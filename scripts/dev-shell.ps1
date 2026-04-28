$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot

Set-Location $RootDir

Write-Host "[1/2] Installing Ruby gems..."
bundle install

Write-Host "[2/2] Loading environment variables..."
$env:RUBYLIB = "$RootDir\lib" + ($(if ($env:RUBYLIB) { ";$env:RUBYLIB" } else { "" }))

if ($args.Count -gt 0 -and $args[0] -eq "--command") {
  if ($args.Count -lt 2) {
    throw "Use: .\scripts\dev-shell.ps1 --command <cmd> [args]"
  }
  $cmd = $args[1]
  $cmdArgs = @()
  if ($args.Count -gt 2) {
    $cmdArgs = $args[2..($args.Count - 1)]
  }

  & $cmd @cmdArgs
  exit $LASTEXITCODE
}

Write-Host "Environment ready."
Write-Host "Run with command passthrough:"
Write-Host "  .\scripts\dev-shell.ps1 --command ruby example\bot.rb"
Write-Host ""
Write-Host "Launching interactive PowerShell..."
powershell
