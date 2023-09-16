#Requires -Modules Utilities

function Repair-EnvironmentPath {
    <#
    .SYNOPSIS
    Repair the PATH environment variable.

    .DESCRIPTION
    Repair the PATH environment variable. This command will remove any invalid paths and normalize the path separators.

    .EXAMPLE
    Repair-EnvironmentPath -Scope CurrentUser

    Repair the PATH environment variable for the current user.

    .EXAMPLE
    Repair-EnvironmentPath -Scope AllUsers

    Repair the PATH environment variable for all users.

    .EXAMPLE

    Repair-EnvironmentPath -Scope CurrentUser -Force

    Repair the PATH environment variable for the current user. Any invalid paths will be removed.

    .EXAMPLE

    Repair-EnvironmentPath -Scope AllUsers -Force

    Repair the PATH environment variable for all users. Any invalid paths will be removed.

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        # The scope of the environment variable.
        [Parameter()]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string] $Scope = 'CurrentUser',

        # Remove any invalid paths.
        [switch] $Force
    )

    begin {
        $separatorChar = [IO.Path]::DirectorySeparatorChar

        $target = if ($Scope -eq 'CurrentUser') {
            [System.EnvironmentVariableTarget]::User
        } else {
            [System.EnvironmentVariableTarget]::Machine
            if (-not (IsAdmin)) {
                throw "Administrator rights are required to modify machine PATH. Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command."
            }
        }
        $environmentPaths = Get-EnvironmentPath -Scope $Scope -AsArray
        Write-Verbose "Repair PATH - [$target]"
        $repairedEnvironmentPaths = @()
    }

    process {
        foreach ($envPath in $environmentPaths) {
            Write-Verbose "Repair PATH - [$target] - [$envPath]"
            $environmentPathExists = Test-Path $envPath

            if ($environmentPathExists) {
                Write-Verbose "Repair PATH - [$target] - [$envPath] - Path exists - Yes"
                $envPathObject = Get-Item -Path $envPath -ErrorAction SilentlyContinue
                if ($envPath -ceq $envPathObject.FullName) {
                    Write-Verbose "Repair PATH - [$target] - [$envPath] - Verify path - Ok"
                } else {
                    $envPath = $envPathObject.FullName
                    Write-Verbose "Repair PATH - [$target] - [$envPath] - Verify path - Updated"
                }
            } else {
                if ($Force) {
                    Write-Warning "Repair PATH - [$target] - [$envPath] - Path exists - No - Removeing (Force)"
                    continue
                } else {
                    Write-Warning "Repair PATH - [$target] - [$envPath] - Path exists - No - Continuing (Use -Force to remove))"
                }
            }

            Write-Verbose "Repair PATH - [$target] - [$envPath] - Normalize path"
            $envPath = $envPath.Replace('\', $separatorChar)
            $envPath = $envPath.Replace('/', $separatorChar)
            $envPath = $envPath.TrimEnd($separatorChar)

            $repairedEnvironmentPaths += $envPath
            Write-Verbose "Repair PATH - [$target] - [$envPath] - Repaired"
        }
    }

    end {
        $repairedEnvironmentPaths = $repairedEnvironmentPaths | Sort-Object -Unique
        $repairedEnvironmentPaths = $repairedEnvironmentPaths -join ';'

        [System.Environment]::SetEnvironmentVariable('PATH', $repairedEnvironmentPaths, [System.EnvironmentVariableTarget]::$target)
        Write-Verbose "Repair PATH - [$target] - Done"
    }
}
