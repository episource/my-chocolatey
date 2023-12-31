# Configure package creation here

# A working directory for building packages is created below CFBuildRoot and the
# final chocolatey packages are exported to CFBuildRoot
$global:CFBuildRoot = "$PSScriptRoot/_build"

# Only packages not found in CFRepository are build. Once a new package has been
# build and passes some simple install tests, it is deployed to CFRepository.
$global:CFRepository = "$PSScriptRoot/_repo"

# Files downloaded by New-Package's default extract files hook are cached if
# $global:CFCacheDir is set
$global:CFCacheDir = "$PSScriptRoot/_cache"

# The config variable CFNoScan can be used to disable virus scans. By default
# all package content is scanned with MS Defender. If a VirusTotal.com api key
# is provided (see config.private.ps1 below), files from the web are even
# scanned prior to downloading.
# $global:CFNoScan = false

# Sensitive configuration options (mainly API keys/tokens) are configured in a
# separate configuration file to be excluded from git.
# The following configuration variables should be moved to this private
# configuration file:
#   global:CFVtApiKey    : VirusTotal.com API key. Lookup the key in
#                          your VirusTotal.com community account preferences. 
#   global:CFGithubToken : The github token used to do authenticated API
#                          requests. Providing such a token increases the rate
#                          limit.
#   global:CFRepoToken   : Chocolatey / Nexus repository token
$privateConfigPath = "$PSScriptRoot/_config.private.ps1"
If (Test-Path -Path $privateConfigPath) {
    . $privateConfigPath
}

# Make sure, that all tls protocols are supported, excluding insecure Ssl3
[Net.ServicePointManager]::SecurityProtocol = 0
[Net.SecurityProtocolType].GetEnumNames() | ?{
    $_ -ne "SystemDefault" -and $_ -ne "Ssl3" } | %{
    [Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]$_ 
}