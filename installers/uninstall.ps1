param(
    [ValidateSet("Aside", "Claude", "Agents", "All")]
    [string]$Target,
    [ValidateSet("User", "Project")]
    [string]$Scope,
    [string]$ProjectRoot,
    [Alias("AccountRoot")]
    [string]$AsideAccountRoot = $env:ASIDE_ACCOUNT_ROOT,
    [switch]$Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SkillName = "gas-optimizer"
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")

if ([string]::IsNullOrWhiteSpace($Target)) { $Target = Read-Host "Uninstall target [Aside/Claude/Agents/All]" }
if ([string]::IsNullOrWhiteSpace($Scope)) { $Scope = Read-Host "Uninstall scope [User/Project]" }
$Target = $Target.ToLowerInvariant()
$Scope = $Scope.ToLowerInvariant()
if ($Target -notin @("aside", "claude", "agents", "all")) { throw "Invalid target: $Target" }
if ($Scope -notin @("user", "project")) { throw "Invalid scope: $Scope" }

if ($Scope -eq "project") {
    if ($Target -eq "aside") { throw "Aside installation is account-scoped." }
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Read-Host "Project root" }
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw "Project root not found: $ProjectRoot" }
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}

function Remove-One {
    param([string]$Label, [string]$TargetDir, [string]$BackupRoot)

    $SkillFile = Join-Path $TargetDir "SKILL.md"
    if (-not (Test-Path -LiteralPath $SkillFile -PathType Leaf)) {
        Write-Host "Not installed for ${Label}: $TargetDir"
        return
    }
    $TargetItem = Get-Item -LiteralPath $TargetDir -Force
    if (($TargetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing to remove reparse point or symbolic link: $TargetDir"
    }
    if (-not (Select-String -LiteralPath $SkillFile -Pattern '^name: "gas-optimizer"$' -Quiet)) {
        throw "Target is not GAS-Optimizer: $TargetDir"
    }
    if (-not $Yes.IsPresent) {
        $Answer = Read-Host "Back up and remove $TargetDir? [y/N]"
        if ($Answer -notmatch '^(y|yes)$') { Write-Host "Skipped $Label."; return }
    }

    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $BackupDir = Join-Path $BackupRoot "$Label-$SkillName-uninstall-$Timestamp"
    Copy-Item -LiteralPath $TargetDir -Destination $BackupDir -Recurse -Force
    Remove-Item -LiteralPath $TargetDir -Recurse -Force
    Write-Host "Removed $Label installation. Backup: $BackupDir"
}

function Remove-Aside {
    if ([string]::IsNullOrWhiteSpace($AsideAccountRoot)) { $script:AsideAccountRoot = Join-Path $HOME ".aside\u\0" }
    Remove-One "aside" (Join-Path $AsideAccountRoot "skills\user\$SkillName") (Join-Path $AsideAccountRoot "backups\skills")
}
function Remove-ClaudeUser {
    $Root = if ($env:CLAUDE_SKILLS_ROOT) { $env:CLAUDE_SKILLS_ROOT } else { Join-Path $HOME ".claude\skills" }
    Remove-One "claude" (Join-Path $Root $SkillName) (Join-Path $HOME ".gas-optimizer\backups")
}
function Remove-AgentsUser {
    $Root = if ($env:AGENT_SKILLS_ROOT) { $env:AGENT_SKILLS_ROOT } else { Join-Path $HOME ".agents\skills" }
    Remove-One "agents" (Join-Path $Root $SkillName) (Join-Path $HOME ".gas-optimizer\backups")
}
function Remove-ClaudeProject { Remove-One "claude-project" (Join-Path $ProjectRoot ".claude\skills\$SkillName") (Join-Path $ProjectRoot ".gas-optimizer-backups") }
function Remove-AgentsProject { Remove-One "agents-project" (Join-Path $ProjectRoot ".agents\skills\$SkillName") (Join-Path $ProjectRoot ".gas-optimizer-backups") }

if ($Scope -eq "user") {
    switch ($Target) {
        "aside" { Remove-Aside }
        "claude" { Remove-ClaudeUser }
        "agents" { Remove-AgentsUser }
        "all" { Remove-Aside; Remove-ClaudeUser; Remove-AgentsUser }
    }
} else {
    switch ($Target) {
        "claude" { Remove-ClaudeProject }
        "agents" { Remove-AgentsProject }
        "all" { Remove-ClaudeProject; Remove-AgentsProject }
    }
}
