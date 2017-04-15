# Description

This repository contains chocolatey package templates together with a bunch of scripts that build  [self-contained](https://chocolatey.org/docs/create-packages#self-contained) packages from the templates, that are based on the latest available software version available.

## Prerequisites
The package templates target a software's 64Bit version if available. Don't expect the packages to work for non x64 systems.

The build scripts have been tested with Windows 10, only. It might work with older windows versions if powershell 5 is available.

# Usage

## Update all packages
**Important:** The following command should be run in a VM. After the packages have been built, they are installed locally to ensure their functionality. This might harm your system!
`./_build.ps1`
This will build, test and deploy package templates for which a new software version has been found. Administrative privileges are required for the test installation.

## Update all packages without testing
`./_build.ps1 -NoTest`
This will build and deploy package templates for which a new software version has been found. Tests will be skipped, hence this command does not require administrative privileges and should it should be generally safe to run on a production system.

## Build a single package
`./<pkgid>/_build.ps1`
This will build a single package only. It won't be tested and deployed to the local package repository.

# Configuration

Take a look at `_config.ps1` for a list of available configuration options. The defaults should work out of the box, however. Nevertheless it might be a good idea to add your VirusTotal.com API key to the private configuration file `_config.private.ps1` (ignored by .gitignore). This will enable VirusTotal.com virus checking. See `_config.ps1` for details.

# Add your own package

1. Add a package folder (called template below) in the root of the repository
2. Add a nuspec template to the template. It uses the razor template language. Build context information is available via the @Package template variable. See the description of the New-Package cmdlet for details.
    
    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <!-- Do not remove this test for UTF-8: if “O” doesn’t appear as greek uppercase omega letter enclosed in quotation marks, you should use an editor that supports UTF-8, not this one. -->
    <package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
      <metadata>
        <id>@Package.id</id>
        <version>@Package.version</version>
        <!-- ... --->
      </metadata>
      <!-- ... --->
    </package>
    ```
3. Add a `_build.ps1` script to the template and invoke the New-Package cmdlet. The `_build.ps1` script should invoke the New-Package passing a VersionInfo argument.

    ```
    # Enable common parameters
    [CmdletBinding()] Param()
    # Import my-chocolatey config & modules
    . $PSScriptRoot/../_root.ps1

    # See the documentation of the New-Package cmdlet for details.
    $vi = @{
        Version  = $version
        FileUrl  = $fileUrl
        Checksum = "$algorithm:$hash"
    }
    New-Package -VersionInfo $vi
    ```

Note: It's also possible to build static nuspec templates. In this case step 3 is optional. Nevertheless a minimal build script is still handy to simplify building a single package from the command prompt.

# More information
See the documentation of the cmdlets provided by the powershell module `choco-factory` for further details. Additionally, the package templates contained in this repository are a good starting point!

# Tips

* Since v0.10.5 chocolatey asks for elevation when executed in the context of an unelevated admin account. It does so, whether administrative permissions are required or not. This behavior can be configured by tweaking `C:\ProgramData\chocolatey\choco.exe.manifest`. See comments within that file for further information.