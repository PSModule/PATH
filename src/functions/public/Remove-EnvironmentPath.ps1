#Requires -Modules Admin, DynamicParams

function Remove-EnvironmentPath {
    <#
    .SYNOPSIS
    Remove a path from the PATH environment variable.

    .DESCRIPTION
    Remove a path from the PATH environment variable. This command will normalize the path separators.

    .EXAMPLE
    Remove-EnvironmentPath -Scope CurrentUser -Path 'C:\Program Files\Git\cmd'

    Remove the path 'C:\Program Files\Git\cmd' from the PATH environment variable for the current user.

    .EXAMPLE
    Remove-EnvironmentPath -Scope AllUsers -Path 'C:\Program Files\Git\cmd'

    Remove the path 'C:\Program Files\Git\cmd' from the PATH environment variable for all users.

    .EXAMPLE
    Remove-EnvironmentPath -Scope CurrentUser -Path 'C:\Program Files\Git\cmd', 'C:\Program Files\Git\bin'

    Remove the paths 'C:\Program Files\Git\cmd' and 'C:\Program Files\Git\bin' from the PATH environment variable for the current user.

    .EXAMPLE
    'C:\Program Files\Git\cmd', 'C:\Program Files\Git\bin' | Remove-EnvironmentPath -Scope CurrentUser

    Remove the paths 'C:\Program Files\Git\cmd' and 'C:\Program Files\Git\bin' from the PATH environment variable for the current user.

    .EXAMPLE
    (Get-EnvironmentPath -Scope AllUsers -AsArray) | where {$_ -like "$env:USERPROFILE*"} | Remove-EnvironmentPath -Scope AllUsers

    Remove all paths from the PATH environment variable for all users that start with the current user's profile path.

    .EXAMPLE
    (Get-EnvironmentPath -Scope CurrentUser -AsArray) |
        where {$_ -like "$env:windir*" -or $_ -like "$env:ProgramFiles*" -or $_ -like "${env:ProgramFiles(x86)}*"} |
        Remove-EnvironmentPath -Scope CurrentUser

    Remove all paths from the PATH environment variable for the current user that start with the Windows directory,
    Program Files directory or Program Files (x86) directory.

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The scope of the environment variable.
        [Parameter()]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string] $Scope = 'CurrentUser'
    )

    dynamicparam {
        $DynamicParamDictionary = New-DynamicParamDictionary

        $dynPath = @{
            Name                            = 'Path'
            Alias                           = 'FullName'
            Type                            = [string[]]
            Mandatory                       = $true
            HelpMessage                     = 'Name of the font to uninstall.'
            ValueFromPipeline               = $true
            ValueFromPipelineByPropertyName = $true
            ValidateSet                     = if ([string]::IsNullOrEmpty($Scope)) {
                Get-EnvironmentPath -Scope 'CurrentUser' -AsArray
            } else {
                Get-EnvironmentPath -Scope $Scope -AsArray
            }
            DynamicParamDictionary          = $DynamicParamDictionary
        }
        New-DynamicParam @dynPath

        return $DynamicParamDictionary
    }

    begin {
        $target = if ($Scope -eq 'CurrentUser') {
            [System.EnvironmentVariableTarget]::User
        } else {
            [System.EnvironmentVariableTarget]::Machine
            if (-not (IsAdmin)) {
                $errorMessage = @'
Administrator rights are required to modify machine PATH.
Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command.
'@
                throw $errorMessage
            }
        }
        $environmentPath = Get-EnvironmentPath -Scope $Scope -AsArray
        Write-Verbose "Remove PATH - [$target]"
    }

    process {
        $Path = $PSBoundParameters['Path']
        foreach ($envPath in $Path) {
            Write-Verbose "Remove PATH - [$target] - [$envPath]"
            $environmentPath = $environmentPath | Where-Object { $_ -ne $envPath }
            Write-Warning "Remove PATH - [$target] - [$envPath] - Removed"
        }
    }

    end {
        $pathSeparator = [System.IO.Path]::PathSeparator
        $environmentPath = $environmentPath -join $pathSeparator
        $environmentPath = $environmentPath.Trim($pathSeparator)
        $environmentPath = $environmentPath + $pathSeparator

        if ($PSCmdlet.ShouldProcess($environmentPath, 'Remove')) {
            [System.Environment]::SetEnvironmentVariable('PATH', $environmentPath, [System.EnvironmentVariableTarget]::$target)
        }
        Write-Verbose "Remove PATH - [$target] - Done"
    }
}
