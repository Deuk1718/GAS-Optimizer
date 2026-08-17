param(
    [ValidateSet("Aside", "Claude", "Agents", "All")]
    [string]$Target,
    [ValidateSet("User", "Project")]
    [string]$Scope,
    [string]$ProjectRoot,
    [Alias("AccountRoot")]
    [string]$AsideAccountRoot = $env:ASIDE_ACCOUNT_ROOT
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SkillName = "gas-optimizer"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$SourceDir = Join-Path $RepoRoot "skill\$SkillName"
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")

if (-not (Test-Path -LiteralPath (Join-Path $SourceDir "SKILL.md") -PathType Leaf)) {
    throw "Packaged skill not found at $SourceDir"
}
if (-not (Select-String -LiteralPath (Join-Path $SourceDir "SKILL.md") -Pattern '^name: "gas-optimizer"$' -Quiet)) {
    throw "Packaged SKILL.md failed the name check."
}

if ([string]::IsNullOrWhiteSpace($Target)) {
    $Target = Read-Host "Install target [Aside/Claude/Agents/All]"
}
if ([string]::IsNullOrWhiteSpace($Scope)) {
    $Scope = Read-Host "Install scope [User/Project]"
}
$Target = $Target.ToLowerInvariant()
$Scope = $Scope.ToLowerInvariant()
if ($Target -notin @("aside", "claude", "agents", "all")) { throw "Invalid target: $Target" }
if ($Scope -notin @("user", "project")) { throw "Invalid scope: $Scope" }

if ($Scope -eq "project") {
    if ($Target -eq "aside") { throw "Aside installation is account-scoped; use -Scope User." }
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Read-Host "Project root"
    }
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
        throw "Project root not found: $ProjectRoot"
    }
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}

function Install-One {
    param([string]$Label, [string]$SkillsRoot, [string]$BackupRoot)

    $TargetDir = Join-Path $SkillsRoot $SkillName
    $TempDir = Join-Path $SkillsRoot ".$SkillName.install.$PID.$Label"
    if (Test-Path -LiteralPath $TargetDir) {
        $TargetItem = Get-Item -LiteralPath $TargetDir -Force
        if (($TargetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Refusing to replace reparse point or symbolic link: $TargetDir"
        }
    }

    New-Item -ItemType Directory -Path $SkillsRoot -Force | Out-Null
    if (Test-Path -LiteralPath $TempDir) { Remove-Item -LiteralPath $TempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    Copy-Item -Path (Join-Path $SourceDir "*") -Destination $TempDir -Recurse -Force

    $RequiredFiles = @(
        "SKILL.md",
        "references\quality-rubric.md",
        "references\capability-matrix.md",
        "assets\analysis-plan-template.html"
    )
    foreach ($Required in $RequiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $TempDir $Required) -PathType Leaf)) {
            Remove-Item -LiteralPath $TempDir -Recurse -Force
            throw "Packaged installation is missing $Required"
        }
    }

    if (Test-Path -LiteralPath $TargetDir) {
        New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
        $BackupDir = Join-Path $BackupRoot "$Label-$SkillName-$Timestamp"
        Copy-Item -LiteralPath $TargetDir -Destination $BackupDir -Recurse -Force
        Write-Host "Existing $Label installation backed up to: $BackupDir"
        Remove-Item -LiteralPath $TargetDir -Recurse -Force
    }

    Move-Item -LiteralPath $TempDir -Destination $TargetDir
    Write-Host "Installed for ${Label}: $TargetDir"
}

function Install-Aside {
    if ([string]::IsNullOrWhiteSpace($AsideAccountRoot)) { $script:AsideAccountRoot = Join-Path $HOME ".aside\u\0" }
    if (-not (Test-Path -LiteralPath $AsideAccountRoot -PathType Container)) {
        throw "Aside account root not found: $AsideAccountRoot"
    }
    Install-One "aside" (Join-Path $AsideAccountRoot "skills\user") (Join-Path $AsideAccountRoot "backups\skills")
}
function Install-ClaudeUser {
    $Root = if ($env:CLAUDE_SKILLS_ROOT) { $env:CLAUDE_SKILLS_ROOT } else { Join-Path $HOME ".claude\skills" }
    Install-One "claude" $Root (Join-Path $HOME ".gas-optimizer\backups")
}
function Install-AgentsUser {
    $Root = if ($env:AGENT_SKILLS_ROOT) { $env:AGENT_SKILLS_ROOT } else { Join-Path $HOME ".agents\skills" }
    Install-One "agents" $Root (Join-Path $HOME ".gas-optimizer\backups")
}
function Install-ClaudeProject { Install-One "claude-project" (Join-Path $ProjectRoot ".claude\skills") (Join-Path $ProjectRoot ".gas-optimizer-backups") }
function Install-AgentsProject { Install-One "agents-project" (Join-Path $ProjectRoot ".agents\skills") (Join-Path $ProjectRoot ".gas-optimizer-backups") }

if ($Scope -eq "user") {
    switch ($Target) {
        "aside" { Install-Aside }
        "claude" { Install-ClaudeUser }
        "agents" { Install-AgentsUser }
        "all" { Install-Aside; Install-ClaudeUser; Install-AgentsUser }
    }
} else {
    switch ($Target) {
        "claude" { Install-ClaudeProject }
        "agents" { Install-AgentsProject }
        "all" { Write-Host "Project scope installs Claude and shared Agent Skills targets; Aside remains account-scoped."; Install-ClaudeProject; Install-AgentsProject }
    }
}

$Version = (Get-Content -LiteralPath (Join-Path $RepoRoot "VERSION") -Raw).Trim()
Write-Host "GAS-Optimizer $Version installation completed."
Write-Host "Restart or reload the selected agent host if the skill is not discovered immediately."
