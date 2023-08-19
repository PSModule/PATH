#Requires -Version 7.0

function Get-EnvironmentPath {
    <#
    .SYNOPSIS
    Get the PATH environment variable.

    .DESCRIPTION
    Get the PATH environment variable for the current user or all users.

    .EXAMPLE
    Get-EnvironmentPath -Scope CurrentUser

    Get the PATH environment variable for the current user.

    .EXAMPLE
    Get-EnvironmentPath -Scope AllUsers -AsArray

    Get the PATH environment variable for the current user as an array.
    #>
    [OutputType([string[]], ParameterSetName = 'AsArray')]
    [OutputType([string], ParameterSetName = 'AsString')]
    [CmdletBinding(DefaultParameterSetName = 'AsString')]
    param(
        # The scope of the environment variable.
        [Parameter()]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string] $Scope = 'CurrentUser',

        # Return the environment variable as an array.
        [Parameter(ParameterSetName = 'AsArray')]
        [switch] $AsArray
    )

    $target = if ($Scope -eq 'CurrentUser') {
        [System.EnvironmentVariableTarget]::User
    } else {
        [System.EnvironmentVariableTarget]::Machine
    }

    $environmentPath = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::$target)
    if (-not $AsArray) {
        return $environmentPath
    }
    $environmentPath = $environmentPath.Split(';')
    $environmentPath = $environmentPath | Sort-Object

    return $environmentPath
}

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
            if (-not (Test-Administrator)) {
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
            if (-not (Test-Administrator)) {
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
    (Get-EnvironmentPath -Scope CurrentUser -AsArray) | where {$_ -like "$env:windir*" -or $_ -like "$env:ProgramFiles*" -or $_ -like "${env:ProgramFiles(x86)}*"} | Remove-EnvironmentPath -Scope CurrentUser -Verbose

    Remove all paths from the PATH environment variable for the current user that start with the Windows directory, Program Files directory or Program Files (x86) directory.
    #>
    [CmdletBinding()]
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
            if (-not (Test-Administrator)) {
                throw "Administrator rights are required to modify machine PATH. Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command."
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
        $environmentPath = $environmentPath -join ';'
        [System.Environment]::SetEnvironmentVariable('PATH', $environmentPath, [System.EnvironmentVariableTarget]::$target)
        Write-Verbose "Remove PATH - [$target] - Done"
    }
}

function Test-Role {
    <#
    .SYNOPSIS
    Test if the current context is running as a specified role.

    .DESCRIPTION
    Test if the current context is running as a specified role.

    .EXAMPLE
    Test-Role -Role Administrator

    Test if the current context is running as an Administrator.

    .EXAMPLE
    Test-Role -Role User

    Test if the current context is running as a User.
    #>
    [OutputType([Boolean])]
    [CmdletBinding()]
    param(
        [Security.Principal.WindowsBuiltInRole] $Role = 'Administrator'
    )

    Write-Verbose "Test Role - [$Role]"
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::$Role)
    Write-Verbose "Test Role - [$Role] - [$isAdmin]"
    return $isAdmin
}
