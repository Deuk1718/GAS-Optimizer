param(
    [string]$AccountRoot = $env:ASIDE_ACCOUNT_ROOT,
    [switch]$Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SkillName = "gas-optimizer"
if ([string]::IsNullOrWhiteSpace($AccountRoot)) {
    $AccountRoot = Join-Path $HOME ".aside\u\0"
}

$TargetDir = Join-Path $AccountRoot "skills\user\$SkillName"
$SkillFile = Join-Path $TargetDir "SKILL.md"
if (-not (Test-Path -LiteralPath $SkillFile -PathType Leaf)) {
    Write-Host "GAS-Optimizer is not installed at: $TargetDir"
    exit 0
}

$TargetItem = Get-Item -LiteralPath $TargetDir -Force
if (($TargetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "Refusing to remove reparse point or symbolic link: $TargetDir"
}
if (-not (Select-String -LiteralPath $SkillFile -Pattern '^name: "gas-optimizer"$' -Quiet)) {
    throw "Target does not contain the expected GAS-Optimizer skill."
}

if (-not $Yes.IsPresent) {
    $Answer = Read-Host "Back up and remove $TargetDir? [y/N]"
    if ($Answer -notmatch '^(y|yes)$') {
        Write-Host "Cancelled."
        exit 0
    }
}

$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$BackupRoot = Join-Path $AccountRoot "backups\skills"
$BackupDir = Join-Path $BackupRoot "$SkillName-uninstall-$Timestamp"
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
Copy-Item -LiteralPath $TargetDir -Destination $BackupDir -Recurse -Force
Remove-Item -LiteralPath $TargetDir -Recurse -Force

Write-Host "GAS-Optimizer removed."
Write-Host "Backup: $BackupDir"
