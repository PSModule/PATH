# PATH

A PowerShell module to manage the PATH environment variable on Windows.

## Prerequisites

This module only supports Windows operating systems.

## Installation

To install the module simply run the following command in a PowerShell terminal.

```powershell
Install-PSResource -Name PATH
Import-Module -Name PATH
```

## Usage

You can use the module to Get, Add, Remove and Repair the PATH environment variable.

### Get the PATH environment variable

The `Get-EnvironmentPath` cmdlet returns the PATH environment variable.

```powershell
Get-EnvironmentPath
```

To get the PATH environment variable for the system, use the `-Scope AllUsers` parameter.

```powershell
Get-EnvironmentPath -Scope AllUsers
```

### Add a directory to the PATH environment variable

The `Add-EnvironmentPath` cmdlet adds a directory to the PATH environment variable.

```powershell
Add-EnvironmentPath -Path 'C:\Program Files\MyApp'
```

To add a directory to the PATH environment variable for the system, use the `-Scope AllUsers` parameter.

```powershell
Add-EnvironmentPath -Path 'C:\Program Files\MyApp' -Scope AllUsers
```

### Remove a directory from the PATH environment variable

The `Remove-EnvironmentPath` cmdlet removes a directory from the PATH environment variable.

```powershell
Remove-EnvironmentPath -Path 'C:\Program Files\MyApp' # Tab completion is supported
```

To remove a directory from the PATH environment variable for the system, use the `-Scope AllUsers` parameter.

```powershell
Remove-EnvironmentPath -Path 'C:\Program Files\MyApp' -Scope AllUsers
```

### Repair the PATH environment variable

The `Repair-EnvironmentPath` cmdlet repairs the PATH environment variable by removing duplicate entries and non-existing directories.

```powershell
Repair-EnvironmentPath
```

To repair the PATH environment variable for the system, use the `-Scope AllUsers` parameter.

```powershell
Repair-EnvironmentPath -Scope AllUsers
```

## Contributing

Coder or not, you can contribute to the project! We welcome all contributions.

### For Users

If you don't code, you still sit on valuable information that can make this project even better. If you experience that the
product does unexpected things, throw errors or is missing functionality, you can help by submitting bugs and feature requests.
Please see the issues tab on this project and submit a new issue that matches your needs.

### For Developers

If you do code, we'd love to have your contributions. Please read the [Contribution guidelines](CONTRIBUTING.md) for more information.
You can either help by picking up an existing issue or submit a new one if you have an idea for a new feature or improvement.
