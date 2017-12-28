# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$versionInfo = Get-VersionInfoFromGithub `
    -Repo "ThunderCls/xAnalyzer" `
    -EnableRegex `
    -File @("xAnalyzer.dp32", "xAnalyzer.dp64", "apis_def.zip")

New-Package `
    -VersionInfo $versionInfo `
    -PrepareFilesHook {
        $_.FileUrl | Import-PackageResource -AutoUnzip:$false
    }