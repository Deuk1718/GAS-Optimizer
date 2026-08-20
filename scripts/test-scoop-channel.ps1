Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$RepoVersion = (Get-Content -LiteralPath (Join-Path $RepoRoot "VERSION") -Raw).Trim()
$BucketUrl = "https://github.com/Deuk1718/scoop-gas-optimizer"
$ManifestUrl = "https://raw.githubusercontent.com/Deuk1718/scoop-gas-optimizer/main/gas-optimizer.json"
$ScoopDir = Join-Path ([System.IO.Path]::GetTempPath()) ("gas-optimizer-scoop-" + [System.Guid]::NewGuid().ToString("N"))
$Installer = Join-Path ([System.IO.Path]::GetTempPath()) "install-scoop.ps1"

function Fail {
    param([string]$Message)
    throw "FAIL: $Message"
}

New-Item -ItemType Directory -Path $ScoopDir -Force | Out-Null
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/ScoopInstaller/Install/master/install.ps1" -OutFile $Installer
& $Installer -ScoopDir $ScoopDir -NoProxy

$Scoop = Join-Path $ScoopDir "shims\scoop.cmd"
if (-not (Test-Path -LiteralPath $Scoop -PathType Leaf)) {
    Fail "Scoop shim missing: $Scoop"
}

$env:Path = "$(Join-Path $ScoopDir 'shims');$env:Path"

& $Scoop bucket add gas-optimizer $BucketUrl
if ($LASTEXITCODE -ne 0) {
    Fail "scoop bucket add failed"
}

& $Scoop install gas-optimizer
if ($LASTEXITCODE -ne 0) {
    Fail "scoop install gas-optimizer failed"
}

$Cli = Get-Command gas-optimizer -ErrorAction SilentlyContinue
if (-not $Cli) {
    Fail "gas-optimizer is not on PATH after scoop install"
}

$Observed = (& gas-optimizer version | Out-String).Trim()
$Manifest = Invoke-RestMethod -Uri $ManifestUrl
$Expected = [string]$Manifest.version
if ($Observed -ne $Expected) {
    Fail "gas-optimizer version is '$Observed', expected bucket version '$Expected'"
}
if ($Expected -ne $RepoVersion) {
    Write-Warning "Repo VERSION is $RepoVersion; public Scoop bucket is $Expected. Channel publish happens after a release tag."
}

Write-Output "PASS: scoop installed gas-optimizer $Observed"
