# Note: this package does not install powershell. It simply checks whether a
# compatible version is already installed.
$wantedVersion    = [Version]$env:chocolateyPackageVersion.Split("+-")[0]
$installedVersion = [Version]$PSVersionTable.PSVersion

If ($installedVersion -lt $wantedVersion) {
    Throw "The installed powershell version $installedVersion is older " + `
        "then the required version $wantedVersion."
} ElseIf ($installedVersion.Major -ne $wantedVersion.Major) {
    Throw "The installed powershell version $installedVersion is not " + `
        "compatible with this package: The major version must be " + `
        "$($installedVersion.Major)"
}