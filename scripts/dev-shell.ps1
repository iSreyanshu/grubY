$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$VenvDir = Join-Path $RootDir ".venv"
$ReqFile = Join-Path $RootDir "example/requirements.txt"

Set-Location $RootDir

Write-Host "[1/4] Installing Ruby gems..."
bundle install

Write-Host "[2/4] Creating Python virtualenv (.venv)..."
python -m venv $VenvDir

$PipExe = Join-Path $VenvDir "Scripts/pip.exe"
$ActivateScript = Join-Path $VenvDir "Scripts/Activate.ps1"

Write-Host "[3/4] Installing Python requirements..."
& $PipExe install -r $ReqFile

Write-Host "[4/4] Loading environment variables..."
$env:PYTHONPATH = "$RootDir\lib" + ($(if ($env:PYTHONPATH) { ";$env:PYTHONPATH" } else { "" }))
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

  & $ActivateScript
  & $cmd @cmdArgs
  exit $LASTEXITCODE
}

Write-Host "Environment ready."
Write-Host "Run with command passthrough:"
Write-Host "  .\scripts\dev-shell.ps1 --command ruby example\bot.rb"
Write-Host ""
Write-Host "Launching interactive PowerShell with .venv active..."
& $ActivateScript
powershell
