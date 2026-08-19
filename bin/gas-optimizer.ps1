param(
    [Parameter(Position = 0)]
    [string]$Command,
    [string]$Target,
    [string]$Scope,
    [string]$ProjectRoot,
    [Alias("AccountRoot")]
    [string]$AsideAccountRoot,
    [switch]$Yes,
    [Alias("h")]
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Show-Usage {
    @"
Usage: gas-optimizer <command> [options]

Commands:
  install     Copy the packaged skill into a host location and record it
  status      Show the package version and recorded installations
  sync        Reinstall every recorded destination from this package
  uninstall   Back up and remove a recorded destination
  version     Print the package version

Options:
  --target TARGET                 aside, claude, agents, or all
  --scope SCOPE                   user or project
  --project-root PATH             Required for project scope
  --aside-account-root PATH       Aside account root
  --yes                           Skip uninstall confirmation
  -h, --help                      Show this help

Package managers install only launcher files and package metadata; they must
not create, update, back up, or remove user or project skill directories.
"@
}

function Resolve-PackageRoot {
    $Source = $PSCommandPath
    while ($true) {
        $Item = Get-Item -LiteralPath $Source
        if (($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
            break
        }
        $Source = $Item.Target
    }
    Split-Path -Parent (Split-Path -Parent $Source)
}

function ConvertTo-InstallerToken {
    param(
        [string]$Value,
        [string[]]$Allowed,
        [string]$Kind
    )
    $Normalized = $Value.ToLowerInvariant()
    if ($Allowed -notcontains $Normalized) {
        throw "Error: invalid ${Kind}: $Value"
    }
    return @{
        aside = "Aside"
        claude = "Claude"
        agents = "Agents"
        all = "All"
        user = "User"
        project = "Project"
    }[$Normalized]
}

function Get-ConcreteTargets {
    param([string]$Target, [string]$Scope)
    if ($Target -ne "all") { return @($Target) }
    if ($Scope -eq "user") { return @("aside", "claude", "agents") }
    return @("claude", "agents")
}

function Get-UserSkillsRoot {
    param([string]$EnvironmentValue, [string]$DefaultPath)
    if (-not [string]::IsNullOrWhiteSpace($EnvironmentValue)) {
        return $EnvironmentValue
    }
    return $DefaultPath
}

function Get-DestinationPath {
    param(
        [string]$Target,
        [string]$Scope,
        [string]$ProjectRoot,
        [string]$AsideRoot
    )
    switch ("$Scope`:$Target") {
        "user:agents" {
            return (Join-Path (Get-UserSkillsRoot $env:AGENT_SKILLS_ROOT (Join-Path $HOME ".agents\skills")) "gas-optimizer")
        }
        "user:claude" {
            return (Join-Path (Get-UserSkillsRoot $env:CLAUDE_SKILLS_ROOT (Join-Path $HOME ".claude\skills")) "gas-optimizer")
        }
        "user:aside" {
            $Root = if ($AsideRoot) { $AsideRoot } else { Join-Path $HOME ".aside\u\0" }
            return (Join-Path $Root "skills\user\gas-optimizer")
        }
        "project:agents" { return (Join-Path $ProjectRoot ".agents\skills\gas-optimizer") }
        "project:claude" { return (Join-Path $ProjectRoot ".claude\skills\gas-optimizer") }
        default { throw "Error: cannot resolve destination for target $Target and scope $Scope" }
    }
}

function Get-EmptyRegistry {
    [ordered]@{ schemaVersion = 1; installations = @() }
}

function ConvertTo-RegistryJson {
    param($Registry)
    $Records = @($Registry.installations)
    $Items = @()
    foreach ($Record in $Records) {
        $Items += ($Record | ConvertTo-Json -Depth 8 -Compress)
    }
    return "{`"schemaVersion`":1,`"installations`":[$($Items -join ',')]}"
}

function Read-Registry {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return (Get-EmptyRegistry)
    }
    $Data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($Data.schemaVersion -ne 1) {
        throw "Error: registry is not a schemaVersion 1 installations document: $Path"
    }
    $Data | Add-Member -NotePropertyName installations -NotePropertyValue @($Data.installations) -Force
    return $Data
}

function Write-Registry {
    param(
        [string]$Path,
        $Registry
    )
    $StateHome = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $StateHome -Force | Out-Null
    $Tmp = Join-Path $StateHome ("installations.json.tmp." + [System.Guid]::NewGuid().ToString("N"))
    $Json = ConvertTo-RegistryJson $Registry
    [System.IO.File]::WriteAllText($Tmp, $Json + [Environment]::NewLine)
    Move-Item -LiteralPath $Tmp -Destination $Path -Force
}

function Get-PackageVersion {
    param([string]$VersionFile)
    if (-not (Test-Path -LiteralPath $VersionFile -PathType Leaf)) {
        throw "Error: VERSION file not found at $VersionFile"
    }
    (Get-Content -LiteralPath $VersionFile -Raw).Trim()
}

function Invoke-Installer {
    param(
        [string]$ScriptPath,
        [string]$Target,
        [string]$Scope,
        [string]$ProjectRoot,
        [string]$AsideRoot,
        [switch]$Yes
    )
    $Splat = @{
        Target = (ConvertTo-InstallerToken $Target @("aside", "claude", "agents", "all") "target")
        Scope = (ConvertTo-InstallerToken $Scope @("user", "project") "scope")
    }
    if ($Scope -eq "project") { $Splat.ProjectRoot = $ProjectRoot }
    if ($AsideRoot) { $Splat.AsideAccountRoot = $AsideRoot }
    if ($Yes) { $Splat.Yes = $true }
    & $ScriptPath @Splat
}

function Read-RequiredChoice {
    param(
        [string]$Current,
        [string]$Prompt,
        [string]$FlagName
    )
    if ($Current) { return $Current }
    if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        return (Read-Host $Prompt).ToLowerInvariant()
    }
    throw "Error: $FlagName is required in non-interactive mode."
}

function Complete-TargetScope {
    param($Parsed, [string]$Action)
    $Parsed.Target = Read-RequiredChoice $Parsed.Target "$Action target [aside/claude/agents/all]: " "--target"
    $Parsed.Scope = Read-RequiredChoice $Parsed.Scope "$Action scope [user/project]: " "--scope"
    [void](ConvertTo-InstallerToken $Parsed.Target @("aside", "claude", "agents", "all") "target")
    [void](ConvertTo-InstallerToken $Parsed.Scope @("user", "project") "scope")
    if ($Parsed.Scope -eq "project") {
        if ($Parsed.Target -eq "aside") {
            throw "Error: Aside installation is account-scoped; use --scope user."
        }
        if (-not $Parsed.ProjectRoot) {
            if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
                $Parsed.ProjectRoot = Read-Host "Project root"
            } else {
                throw "Error: --project-root is required for project scope."
            }
        }
        if (-not (Test-Path -LiteralPath $Parsed.ProjectRoot -PathType Container)) {
            throw "Error: project root not found: $($Parsed.ProjectRoot)"
        }
    }
}

function Test-RecordMatch {
    param($Record, $Parsed)
    if ($Parsed.Target -and $Parsed.Target -ne "all" -and $Record.target -ne $Parsed.Target) { return $false }
    if ($Parsed.Scope -and $Record.scope -ne $Parsed.Scope) { return $false }
    if ($Parsed.ProjectRoot) {
        $RecordProject = [string]$Record.projectRoot
        if ($RecordProject -ne $Parsed.ProjectRoot) { return $false }
    }
    return $true
}

function Get-RecordStatus {
    param($Record, [string]$Version)
    if (-not (Test-Path -LiteralPath (Join-Path $Record.path "SKILL.md") -PathType Leaf)) {
        return "missing"
    }
    if ($Record.installedVersion -eq $Version) { return "current" }
    return "stale"
}

function Invoke-GasOptimizer {
    $PackageRoot = Resolve-PackageRoot
    $Installer = Join-Path $PackageRoot "installers\install.ps1"
    $Uninstaller = Join-Path $PackageRoot "installers\uninstall.ps1"
    $VersionFile = Join-Path $PackageRoot "VERSION"
    $StateHome = if ($env:GAS_OPTIMIZER_HOME) { $env:GAS_OPTIMIZER_HOME } else { Join-Path $HOME ".gas-optimizer" }
    $RegistryPath = Join-Path $StateHome "installations.json"

    if ($Help -or [string]::IsNullOrWhiteSpace($Command) -or $Command -in @("-h", "--help", "help")) {
        Show-Usage
        return 0
    }

    if ($Command -eq "version") {
        Write-Output (Get-PackageVersion $VersionFile)
        return 0
    }

    $Parsed = @{
        Target = $(if ($Target) { $Target.ToLowerInvariant() } else { "" })
        Scope = $(if ($Scope) { $Scope.ToLowerInvariant() } else { "" })
        ProjectRoot = $(if ($ProjectRoot) { $ProjectRoot } else { "" })
        AsideRoot = $(if ($AsideAccountRoot) { $AsideAccountRoot } elseif ($env:ASIDE_ACCOUNT_ROOT) { $env:ASIDE_ACCOUNT_ROOT } else { "" })
        Yes = [bool]$Yes
    }

    switch ($Command) {
        "install" {
            if (-not (Test-Path -LiteralPath (Join-Path $PackageRoot "skill\gas-optimizer\SKILL.md") -PathType Leaf)) {
                throw "Error: packaged skill not found at $PackageRoot\skill\gas-optimizer"
            }
            Complete-TargetScope $Parsed "Install"
            Invoke-Installer -ScriptPath $Installer -Target $Parsed.Target -Scope $Parsed.Scope -ProjectRoot $Parsed.ProjectRoot -AsideRoot $Parsed.AsideRoot
            $Registry = Read-Registry $RegistryPath
            $Version = Get-PackageVersion $VersionFile
            $InstalledAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
            $Kept = @($Registry.installations)
            foreach ($Target in (Get-ConcreteTargets $Parsed.Target $Parsed.Scope)) {
                $Path = Get-DestinationPath -Target $Target -Scope $Parsed.Scope -ProjectRoot $Parsed.ProjectRoot -AsideRoot $Parsed.AsideRoot
                $Kept = @($Kept | Where-Object { $_.path -ne $Path })
                $Kept += [pscustomobject]@{
                    target = $Target
                    scope = $Parsed.Scope
                    path = $Path
                    projectRoot = $(if ($Parsed.Scope -eq "project") { $Parsed.ProjectRoot } else { $null })
                    accountRoot = $(if ($Target -eq "aside") { $(if ($Parsed.AsideRoot) { $Parsed.AsideRoot } else { Join-Path $HOME ".aside\u\0" }) } else { $null })
                    installedVersion = $Version
                    installedAt = $InstalledAt
                }
            }
            $Registry.installations = @($Kept)
            Write-Registry $RegistryPath $Registry
        }
        "status" {
            $Version = Get-PackageVersion $VersionFile
            Write-Output "packageVersion: $Version"
            $Registry = Read-Registry $RegistryPath
            $Printed = $false
            foreach ($Record in @($Registry.installations)) {
                if (-not (Test-RecordMatch $Record $Parsed)) { continue }
                $Printed = $true
                Write-Output "target: $($Record.target)"
                Write-Output "scope: $($Record.scope)"
                Write-Output "path: $($Record.path)"
                Write-Output "installedVersion: $($Record.installedVersion)"
                Write-Output "status: $(Get-RecordStatus $Record $Version)"
            }
            if (-not $Printed) {
                Write-Output "No matching installations."
            }
        }
        "sync" {
            $Registry = Read-Registry $RegistryPath
            if (@($Registry.installations).Count -eq 0) {
                Write-Output "No recorded installations."
                return 0
            }
            $Version = Get-PackageVersion $VersionFile
            $InstalledAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
            foreach ($Record in @($Registry.installations)) {
                $ProjectRoot = [string]$Record.projectRoot
                $AsideRoot = [string]$Record.accountRoot
                Invoke-Installer -ScriptPath $Installer -Target $Record.target -Scope $Record.scope -ProjectRoot $ProjectRoot -AsideRoot $AsideRoot
                $Record.installedVersion = $Version
                $Record.installedAt = $InstalledAt
            }
            Write-Registry $RegistryPath $Registry
        }
        "uninstall" {
            Complete-TargetScope $Parsed "Uninstall"
            $Registry = Read-Registry $RegistryPath
            Invoke-Installer -ScriptPath $Uninstaller -Target $Parsed.Target -Scope $Parsed.Scope -ProjectRoot $Parsed.ProjectRoot -AsideRoot $Parsed.AsideRoot -Yes:$Parsed.Yes
            $Kept = @()
            foreach ($Record in @($Registry.installations)) {
                $SkillFile = Join-Path $Record.path "SKILL.md"
                if ((Test-RecordMatch $Record $Parsed) -and -not (Test-Path -LiteralPath $SkillFile -PathType Leaf)) {
                    continue
                }
                $Kept += $Record
            }
            $Registry.installations = @($Kept)
            Write-Registry $RegistryPath $Registry
        }
        default {
            throw "Error: unknown command: $Command"
        }
    }
    return 0
}

$script:ExitCode = 0
try {
    $script:ExitCode = Invoke-GasOptimizer
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    $script:ExitCode = 1
}

$global:LASTEXITCODE = $script:ExitCode
exit $script:ExitCode
