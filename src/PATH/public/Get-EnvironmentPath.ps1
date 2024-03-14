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
    if ($IsWindows) {
        $pathSeparator = ';'
    } else {
        $pathSeparator = ':'
    }
    $environmentPath = $environmentPath.Split($pathSeparator)
    $environmentPath = $environmentPath | Sort-Object

    return $environmentPath
}
