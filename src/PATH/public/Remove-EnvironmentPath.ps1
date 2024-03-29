#Requires -Modules Admin

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
    (Get-EnvironmentPath -Scope AllUsers -AsArray) | where {$_ -like "$env:USERPROFILE*"} | Remove-EnvironmentPath -Scope AllUsers -Verbose

    Remove all paths from the PATH environment variable for all users that start with the current user's profile path.

    .EXAMPLE
    (Get-EnvironmentPath -Scope CurrentUser -AsArray) |
        where {$_ -like "$env:windir*" -or $_ -like "$env:ProgramFiles*" -or $_ -like "${env:ProgramFiles(x86)}*"} |
        Remove-EnvironmentPath -Scope CurrentUser -Verbose

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

    DynamicParam {
        $runtimeDefinedParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        $parameterName = 'Path'
        $parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $parameterAttribute.Mandatory = $true
        $parameterAttribute.Position = 1
        $parameterAttribute.HelpMessage = 'Name of the font to uninstall.'
        $parameterAttribute.ValueFromPipeline = $true
        $parameterAttribute.ValueFromPipelineByPropertyName = $true
        $attributeCollection.Add($parameterAttribute)

        $parameterValidateSet = Get-EnvironmentPath -Scope $Scope -AsArray
        $validateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($parameterValidateSet)
        $attributeCollection.Add($validateSetAttribute)

        # Adding a parameter alias
        $parameterAlias = 'FullName'
        $aliasAttribute = New-Object System.Management.Automation.AliasAttribute -ArgumentList $parameterAlias
        $attributeCollection.Add($aliasAttribute)

        $runtimeDefinedParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($parameterName, [string[]], $attributeCollection)
        $runtimeDefinedParameterDictionary.Add($parameterName, $runtimeDefinedParameter)
        return $runtimeDefinedParameterDictionary
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
        if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
            $pathSeparator = ';'
        } else {
            $pathSeparator = ':'
        }
        $environmentPath = $environmentPath -join $pathSeparator
        if ($PSCmdlet.ShouldProcess($environmentPath, 'Remove')) {
            [System.Environment]::SetEnvironmentVariable('PATH', $environmentPath, [System.EnvironmentVariableTarget]::$target)
        }
        Write-Verbose "Remove PATH - [$target] - Done"
    }
}
