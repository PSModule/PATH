Describe 'PATH' {
    Context 'Module' {
        It 'The module should be available' {
            Get-Module -Name 'PATH' -ListAvailable | Should -Not -BeNullOrEmpty
            Write-Verbose (Get-Module -Name 'PATH' -ListAvailable | Out-String) -Verbose
        }
        It 'The module should be imported' {
            { Import-Module -Name 'PATH' } | Should -Not -Throw
        }
    }
}
