[CmdletBinding()]
Param(
    # Path to the module to test.
    [Parameter()]
    [string] $Path
)

Write-Verbose "Path to the module: [$Path]" -Verbose

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

    Context 'Function: Get-EnvironemntPath' {
        It 'Should not throw' {
            { Write-Verbose (Get-EnvironmentPath) -Verbose } | Should -Not -Throw
        }

        It "Should not throw when using '-AsArray'" {
            { Write-Verbose (Get-EnvironmentPath -AsArray) -Verbose } | Should -Not -Throw
        }
    }

    Context 'Function: Add-EnvironmentPath' {
        It 'Should not throw' {
            { Add-EnvironmentPath -Path $HOME -Verbose } | Should -Not -Throw
        }
    }

    Context 'Function: Repair-EnvironmentPath' {
        It 'Should not throw' {
            { Repair-EnvironmentPath -Verbose } | Should -Not -Throw
        }
    }

    Context 'Function: Remove-EnvironmentPath' {
        It 'Should not throw' {
            { Remove-EnvironmentPath -Path $HOME -Verbose } | Should -Not -Throw
        }
    }
}
