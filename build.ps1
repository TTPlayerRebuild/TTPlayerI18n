[CmdletBinding()]
param(
    [string]$BuildDirectory,
    [string]$Generator = 'Visual Studio 18 2026',
    [string[]]$CMakeArguments = @(),
    [switch]$Package,
    [ValidateSet('Release', 'RelWithDebInfo', 'Debug')][string]$Configuration = 'Release',
    [string]$PackageVersion
)
$ErrorActionPreference = 'Stop'
if (-not $BuildDirectory) { $BuildDirectory = Join-Path $PSScriptRoot 'build' }
. (Join-Path $PSScriptRoot 'cmake/version.ps1')
$PackageVersion = (Get-I18nBuildVersion $PackageVersion).Name
function Invoke-CMake([string[]]$Arguments) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & cmake @Arguments 2>&1 | ForEach-Object { $_.ToString() }
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previous }
    if ($code -ne 0) { throw "CMake failed ($code): $Arguments" }
}
Invoke-CMake (@('-S',$PSScriptRoot,'-B',$BuildDirectory,'-G',$Generator,'-A','Win32') + $CMakeArguments +
    @("-DTTP_I18N_BUILD_VERSION=$PackageVersion", '-DBUILD_TESTING=OFF'))
Invoke-CMake @('--build',$BuildDirectory,'--config',$Configuration,'--target','ttp_i18n','--parallel','4')
Assert-I18nFileVersion (Join-Path $BuildDirectory "$Configuration/AddIn/ttp_i18n.dll") $PackageVersion
if (-not $Package) { return }
& (Join-Path $PSScriptRoot 'tools/package.ps1') -BuildDirectory $BuildDirectory -Configuration $Configuration `
    -Destination (Join-Path $BuildDirectory $Configuration) -PackageVersion $PackageVersion
