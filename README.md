# Description

This repository contains chocolatey package templates together with a bunch of scripts that build  [self-contained](https://chocolatey.org/docs/create-packages#self-contained) packages from the templates, that are based on the latest available software version available.

# Usage

**Important:** The following commands should be run in a VM. After a package has been built, it is installed locally to ensure it's functionality. This might harm your system!

TODO

# Add your own package

1. Add a package folder (called template below) in the root of the repository
2. Add a nuspec template to the template. It uses the razor template language. At least the package id and version must be templated. See the description of the Export-Package cmdlet for details.
    
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
3. Add a `_build.ps1` script to the template and implement at least the `QueryReleaseHook`. ...

# More information
See the documentation of the cmdlets provided by the powershell module `choco-fountain` for further details. Additionally, the package templates contained in this repository are a good starting point!