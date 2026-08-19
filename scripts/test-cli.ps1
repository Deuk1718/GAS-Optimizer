Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$Cli = Join-Path $RepoRoot "bin\gas-optimizer.ps1"
$Version = (Get-Content -LiteralPath (Join-Path $RepoRoot "VERSION") -Raw).Trim()
$TmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("gas-optimizer-cli-" + [System.Guid]::NewGuid().ToString("N"))

function Fail {
    param([string]$Message)
    throw "FAIL: $Message"
}

function Assert-UnderTemp {
    param([string]$Path)
    $Resolved = [System.IO.Path]::GetFullPath($Path)
    $Temp = [System.IO.Path]::GetFullPath($TmpRoot)
    if (-not $Resolved.StartsWith($Temp, [System.StringComparison]::OrdinalIgnoreCase)) {
        Fail "path escaped isolated temp root: $Path"
    }
}

function Invoke-Cli {
    param([string[]]$CliArguments)
    $Pwsh = (Get-Process -Id $PID).Path
    $Output = & $Pwsh -NoProfile -File $Cli @CliArguments
    if ($LASTEXITCODE -ne 0) {
        Fail "gas-optimizer $($CliArguments -join ' ') exited with $LASTEXITCODE"
    }
    return $Output
}

function Read-Registry {
    if (-not (Test-Path -LiteralPath $script:Registry -PathType Leaf)) {
        Fail "registry missing: $script:Registry"
    }
    Get-Content -LiteralPath $script:Registry -Raw | ConvertFrom-Json
}

function Assert-NoRealUserPaths {
    Assert-UnderTemp $env:HOME
    Assert-UnderTemp $env:USERPROFILE
    Assert-UnderTemp $env:GAS_OPTIMIZER_HOME
    Assert-UnderTemp $env:CLAUDE_SKILLS_ROOT
    Assert-UnderTemp $env:AGENT_SKILLS_ROOT
    Assert-UnderTemp $env:ASIDE_ACCOUNT_ROOT
    if (Test-Path -LiteralPath $script:Registry -PathType Leaf) {
        $RegistryData = Read-Registry
        foreach ($Record in @($RegistryData.installations)) {
            Assert-UnderTemp $Record.path
        }
    }
}

function Assert-RegistryCount {
    param([int]$Expected)
    $RegistryData = Read-Registry
    if ($RegistryData.schemaVersion -ne 1) {
        Fail "registry schemaVersion is not 1"
    }
    if (@($RegistryData.installations).Count -ne $Expected) {
        Fail "registry does not contain $Expected record(s)"
    }
    Assert-NoRealUserPaths
    return $RegistryData
}

function Assert-SingleRecord {
    param(
        [string]$ExpectedTarget,
        [string]$ExpectedScope,
        [string]$ExpectedPath
    )
    $RegistryData = Assert-RegistryCount 1
    $Record = @($RegistryData.installations)[0]
    if ($Record.target -ne $ExpectedTarget) { Fail "registry target mismatch: $($Record.target)" }
    if ($Record.scope -ne $ExpectedScope) { Fail "registry scope mismatch: $($Record.scope)" }
    if ($Record.path -ne $ExpectedPath) { Fail "registry path mismatch: $($Record.path)" }
    if ($Record.installedVersion -ne $Version) { Fail "registry installedVersion mismatch: $($Record.installedVersion)" }
}

function Assert-Contains {
    param([string]$Output, [string]$Needle)
    if (-not $Output.Contains($Needle)) {
        Fail "expected output to contain '$Needle'; got: $Output"
    }
}

try {
    New-Item -ItemType Directory -Path $TmpRoot -Force | Out-Null
    $env:HOME = Join-Path $TmpRoot "home"
    $env:USERPROFILE = $env:HOME
    $env:GAS_OPTIMIZER_HOME = Join-Path $TmpRoot "state"
    $env:CLAUDE_SKILLS_ROOT = Join-Path $TmpRoot "user-claude\skills"
    $env:AGENT_SKILLS_ROOT = Join-Path $TmpRoot "user-agents\skills"
    $env:ASIDE_ACCOUNT_ROOT = Join-Path $TmpRoot "aside-account"
    foreach ($Path in @($env:HOME, $env:GAS_OPTIMIZER_HOME, $env:CLAUDE_SKILLS_ROOT, $env:AGENT_SKILLS_ROOT, $env:ASIDE_ACCOUNT_ROOT)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    $script:Registry = Join-Path $env:GAS_OPTIMIZER_HOME "installations.json"

    $VersionOutput = (Invoke-Cli -CliArguments @("version")) -join "`n"
    Assert-Contains $VersionOutput $Version
    Assert-NoRealUserPaths

    $AgentsPath = Join-Path $env:AGENT_SKILLS_ROOT "gas-optimizer"
    Invoke-Cli -CliArguments @("install", "--target", "agents", "--scope", "user") | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $AgentsPath "SKILL.md") -PathType Leaf)) {
        Fail "user agents install did not create $AgentsPath"
    }
    Assert-SingleRecord agents user $AgentsPath

    $StatusOutput = (Invoke-Cli -CliArguments @("status", "--target", "agents", "--scope", "user")) -join "`n"
    Assert-Contains $StatusOutput "current"
    Assert-Contains $StatusOutput $AgentsPath
    Assert-SingleRecord agents user $AgentsPath

    $Sentinel = Join-Path $AgentsPath "STALE-FILE"
    Set-Content -LiteralPath $Sentinel -Value "stale"
    Invoke-Cli -CliArguments @("sync") | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $AgentsPath "SKILL.md") -PathType Leaf)) {
        Fail "sync did not reinstall the agents record"
    }
    if (Test-Path -LiteralPath $Sentinel) {
        Fail "sync retained stale content instead of reinstalling"
    }
    $BackupRootCandidates = @(
        Join-Path $env:GAS_OPTIMIZER_HOME "backups",
        Join-Path $env:HOME ".gas-optimizer\backups"
    )
    $SyncBackup = $BackupRootCandidates |
        Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
        ForEach-Object { Get-ChildItem -LiteralPath $_ -Recurse -File -Filter "STALE-FILE" -ErrorAction SilentlyContinue } |
        Select-Object -First 1
    if (-not $SyncBackup) {
        Fail "sync did not back up the prior agents installation"
    }
    Assert-SingleRecord agents user $AgentsPath

    Invoke-Cli -CliArguments @("uninstall", "--target", "agents", "--scope", "user", "--yes") | Out-Null
    if (Test-Path -LiteralPath $AgentsPath) {
        Fail "uninstall did not remove $AgentsPath"
    }
    $UninstallBackup = $BackupRootCandidates |
        Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
        ForEach-Object { Get-ChildItem -LiteralPath $_ -Recurse -File -Filter "SKILL.md" -ErrorAction SilentlyContinue } |
        Select-Object -First 1
    if (-not $UninstallBackup) {
        Fail "uninstall did not back up the removed agents installation"
    }
    Assert-RegistryCount 0 | Out-Null

    $ProjectRoot = Join-Path $TmpRoot "project"
    New-Item -ItemType Directory -Path $ProjectRoot -Force | Out-Null
    $ProjectAgentsPath = Join-Path $ProjectRoot ".agents\skills\gas-optimizer"
    Invoke-Cli -CliArguments @("install", "--target", "agents", "--scope", "project", "--project-root", $ProjectRoot) | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectAgentsPath "SKILL.md") -PathType Leaf)) {
        Fail "project agents install did not create $ProjectAgentsPath"
    }
    Assert-SingleRecord agents project $ProjectAgentsPath

    $ProjectStatus = (Invoke-Cli -CliArguments @("status", "--target", "agents", "--scope", "project", "--project-root", $ProjectRoot)) -join "`n"
    Assert-Contains $ProjectStatus "current"
    Assert-Contains $ProjectStatus $ProjectAgentsPath

    Invoke-Cli -CliArguments @("uninstall", "--target", "agents", "--scope", "project", "--project-root", $ProjectRoot, "--yes") | Out-Null
    if (Test-Path -LiteralPath $ProjectAgentsPath) {
        Fail "project agents uninstall did not remove $ProjectAgentsPath"
    }
    Assert-RegistryCount 0 | Out-Null
    Assert-NoRealUserPaths

    Write-Host "PASS: gas-optimizer CLI lifecycle contract"
}
finally {
    if (Test-Path -LiteralPath $TmpRoot) {
        Remove-Item -LiteralPath $TmpRoot -Recurse -Force
    }
}
