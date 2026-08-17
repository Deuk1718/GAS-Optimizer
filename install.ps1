param(
    [ValidateSet("Aside", "Claude", "Agents", "All")]
    [string]$Target,
    [ValidateSet("User", "Project")]
    [string]$Scope,
    [string]$ProjectRoot,
    [Alias("AccountRoot")]
    [string]$AsideAccountRoot = $env:ASIDE_ACCOUNT_ROOT
)

& (Join-Path $PSScriptRoot "installers\install.ps1") @PSBoundParameters
exit $LASTEXITCODE
