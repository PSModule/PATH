Describe 'PATH' {
    Context 'Function: Get-EnvironemntPath' {
        Context 'CurrentUser' {
            It 'Should not throw' {
                $result = Get-EnvironmentPath
                Write-Verbose ($result | Out-String) -Verbose
                $result | Should -BeOfType [System.String]
            }

            It "Should not throw when using '-AsArray'" {
                $result = Get-EnvironmentPath -AsArray
                Write-Verbose ($result | Out-String) -Verbose
                Should -ActualValue $result -BeOfType [System.Object[]]
            }
        }

        Context 'AllUsers' {
            It 'Should not throw' {
                $result = Get-EnvironmentPath -Scope 'AllUsers'
                Write-Verbose ($result | Out-String) -Verbose
                $result | Should -BeOfType [System.String]
            }

            It "Should not throw when using '-AsArray'" {
                $result = Get-EnvironmentPath -Scope 'AllUsers' -AsArray
                Write-Verbose ($result | Out-String) -Verbose
                Should -ActualValue $result -BeOfType [System.Object[]]
            }
        }
    }

    Context 'Function: Add-EnvironmentPath' {
        It 'Should not throw' {
            {
                Add-EnvironmentPath -Path $HOME -Verbose
                Write-Verbose (Get-EnvironmentPath | Out-String) -Verbose
                Write-Verbose (Get-EnvironmentPath -AsArray | Out-String) -Verbose
            } | Should -Not -Throw
        }
    }

    Context 'Function: Repair-EnvironmentPath' {
        It 'Should not throw' {
            {
                Repair-EnvironmentPath -Verbose
                Write-Verbose (Get-EnvironmentPath | Out-String) -Verbose
                Write-Verbose (Get-EnvironmentPath -AsArray | Out-String) -Verbose
            } | Should -Not -Throw
        }
    }

    Context 'Function: Remove-EnvironmentPath' {
        It 'Should not throw' {
            {
                Remove-EnvironmentPath -Path $HOME -Verbose
                Write-Verbose (Get-EnvironmentPath | Out-String) -Verbose
                Write-Verbose (Get-EnvironmentPath -AsArray | Out-String) -Verbose
            } | Should -Not -Throw
        }
    }
}
