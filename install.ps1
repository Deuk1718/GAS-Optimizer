param(
    [string]$AccountRoot = $env:ASIDE_ACCOUNT_ROOT
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SkillName = "gas-optimizer"
$SourceDir = Join-Path $PSScriptRoot "skill\$SkillName"

if ([string]::IsNullOrWhiteSpace($AccountRoot)) {
    $AccountRoot = Join-Path $HOME ".aside\u\0"
}

if (-not (Test-Path -LiteralPath (Join-Path $SourceDir "SKILL.md") -PathType Leaf)) {
    throw "Packaged skill not found at $SourceDir"
}

if (-not (Test-Path -LiteralPath $AccountRoot -PathType Container)) {
    throw "Aside account root not found: $AccountRoot. Start Aside once, or pass -AccountRoot with the correct path."
}

$SkillsRoot = Join-Path $AccountRoot "skills\user"
$TargetDir = Join-Path $SkillsRoot $SkillName
$BackupRoot = Join-Path $AccountRoot "backups\skills"
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$TempDir = Join-Path $SkillsRoot ".$SkillName.install.$PID"

if (Test-Path -LiteralPath $TargetDir) {
    $TargetItem = Get-Item -LiteralPath $TargetDir -Force
    if (($TargetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing to replace reparse point or symbolic link: $TargetDir"
    }
}

New-Item -ItemType Directory -Path $SkillsRoot -Force | Out-Null
if (Test-Path -LiteralPath $TempDir) {
    Remove-Item -LiteralPath $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Copy-Item -Path (Join-Path $SourceDir "*") -Destination $TempDir -Recurse -Force

$SkillFile = Join-Path $TempDir "SKILL.md"
if (-not (Select-String -LiteralPath $SkillFile -Pattern '^name: "gas-optimizer"$' -Quiet)) {
    Remove-Item -LiteralPath $TempDir -Recurse -Force
    throw "Packaged SKILL.md failed the name check."
}

if (Test-Path -LiteralPath $TargetDir) {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $BackupDir = Join-Path $BackupRoot "$SkillName-$Timestamp"
    Copy-Item -LiteralPath $TargetDir -Destination $BackupDir -Recurse -Force
    Write-Host "Existing installation backed up to: $BackupDir"
    Remove-Item -LiteralPath $TargetDir -Recurse -Force
}

Move-Item -LiteralPath $TempDir -Destination $TargetDir

$RequiredFiles = @(
    "SKILL.md",
    "references\quality-rubric.md",
    "assets\analysis-plan-template.html"
)
foreach ($Required in $RequiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $TargetDir $Required) -PathType Leaf)) {
        throw "Installation is incomplete; missing $Required"
    }
}

$Version = (Get-Content -LiteralPath (Join-Path $PSScriptRoot "VERSION") -Raw).Trim()
Write-Host "GAS-Optimizer $Version installed successfully."
Write-Host "Location: $TargetDir"
Write-Host "Restart Aside or start a new session to refresh skill discovery."
