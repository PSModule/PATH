#Requires -Module Utilities

function Add-EnvironmentPath {
    <#
    .SYNOPSIS
    Add a path to the PATH environment variable.

    .DESCRIPTION
    Add a path to the PATH environment variable. This command will normalize the path separators.

    .EXAMPLE
    Add-EnvironmentPath -Scope CurrentUser -Path 'C:\Program Files\Git\cmd'

    Add the path 'C:\Program Files\Git\cmd' to the PATH environment variable for the current user.

    .EXAMPLE
    Add-EnvironmentPath -Scope AllUsers -Path 'C:\Program Files\Git\cmd'

    Add the path 'C:\Program Files\Git\cmd' to the PATH environment variable for all users.

    .EXAMPLE
    Add-EnvironmentPath -Scope CurrentUser -Path 'C:\Program Files\Git\cmd', 'C:\Program Files\Git\bin'

    Add the paths 'C:\Program Files\Git\cmd' and 'C:\Program Files\Git\bin' to the PATH environment variable for the current user.

    .EXAMPLE
    Add-EnvironmentPath -Scope CurrentUser -Path 'C:\Program Files\Git\cmd', 'C:\Program Files\Git\bin' -Force

    Add the paths 'C:\Program Files\Git\cmd' and 'C:\Program Files\Git\bin' to the PATH environment variable for the current user. Any invalid paths will be removed.

    .EXAMPLE
    'C:\Program Files\Git\cmd', 'C:\Program Files\Git\bin' | Add-EnvironmentPath -Scope CurrentUser

    Add the paths 'C:\Program Files\Git\cmd' and 'C:\Program Files\Git\bin' to the PATH environment variable for the current user.
    #>
    [CmdletBinding()]
    param(
        # The scope of the environment variable.
        [Parameter()]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string] $Scope = 'CurrentUser',

        # The path to add to the environment variable.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [string[]] $Path,

        # Remove any invalid paths.
        [Parameter()]
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
        $environmentPath = Get-EnvironmentPath -Scope $Scope -AsArray
        Write-Verbose "Add PATH - [$target]"
    }

    process {
        foreach ($envPath in $Path) {
            Write-Verbose "Add PATH - [$target] - [$envPath]"

            $envPathExists = Test-Path $envPath
            if ($envPathExists) {
                Write-Verbose "Add PATH - [$target] - [$envPath] - Path exists - Yes"

                $envPathObject = Get-Item -Path $envPath -ErrorAction SilentlyContinue
                if ($envPath -ceq $envPathObject.FullName) {
                    Write-Verbose "Add PATH - [$target] - [$envPath] - Verify path - Ok"
                } else {
                    $envPath = $envPathObject.FullName
                    Write-Verbose "Add PATH - [$target] - [$envPath] - Verify path - Updated"
                }
            } else {
                if ($Force) {
                    Write-Verbose "Add PATH - [$target] - [$envPath] - Path exists - No - Continuing (Force)"
                } else {
                    Write-Warning "Add PATH - [$target] - [$envPath] - Path exists - No - Skipping (Use -Force to add)"
                    continue
                }
            }

            Write-Verbose "Add PATH - [$target] - [$envPath] - Normalize path"
            $envPath = $envPath.Replace('\', $separatorChar)
            $envPath = $envPath.Replace('/', $separatorChar)
            $envPath = $envPath.TrimEnd($separatorChar)

            $environmentPath += $envPath
            Write-Verbose "Add PATH - [$target] - [$envPath] - Added"
        }
    }

    end {
        $environmentPath = $environmentPath -join ';'

        [System.Environment]::SetEnvironmentVariable('PATH', $environmentPath, [System.EnvironmentVariableTarget]::$target)
        Write-Verbose "Add PATH - [$target] - Done"
    }
}
