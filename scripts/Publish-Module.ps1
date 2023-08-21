[CmdletBinding()]
param (
    [Parameter()]
    [string] $ModuleName,

    [Parameter()]
    [string] $APIKey
)

$SRCPath = Get-Item -Path .\src\ | Select-Object -ExpandProperty FullName
$env:PSModulePath += ":$SRCPath"
$env:PSModulePath -Split ':'

$Manifest = Invoke-Expression (Get-Content -Path 'C:\Repos\MariusStorhaug\PATH\src\PATH\PATH.psd1' -Raw)
$Manifest.RequiredModules | ForEach-Object {
    $Module = Get-Module -Name $_.ModuleName -ListAvailable
    if ($Module) {
        Write-Verbose "Importing module $($_.ModuleName) from $($Module.Path)"
        Import-Module -Name $Module.Path -Verbose
    }
}

.\scripts\Set-ModuleVersion.ps1 -ModuleName $ModuleName -Verbose
Publish-Module -Path "src/$ModuleName" -NuGetApiKey $APIKey -Verbose
