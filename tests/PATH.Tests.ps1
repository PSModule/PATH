[CmdletBinding()]
Param(
    # Path to the module to test.
    [Parameter()]
    [string] $Path
)

Describe 'PATH' {
    Context 'Module' {
        It 'The module should be available' {
            Get-Module -Name 'PATH' -ListAvailable | Should -Not -BeNullOrEmpty
            Write-Verbose (Get-Module -Name 'PATH' -ListAvailable | Out-String) -Verbose
        }
        It 'The module should be imported' {
            { Import-Module -Name 'PATH' -Verbose -RequiredVersion 999.0.0 -Force } | Should -Not -Throw
        }
    }
}
