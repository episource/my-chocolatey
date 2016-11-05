# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$projectUrl = "http://schinagl.priv.at/nt/hardlinkshellext/hardlinkshellext.html"
$setupUrl = "http://schinagl.priv.at/nt/hardlinkshellext/HardLinkShellExt_X64.exe"


$currentVersion = $null
$changes = @()

$r = Invoke-WebRequest $projectUrl
# The current history layout is:
# <tr>
#   <td>...<a name="history">...</td>
#
#   <td><table>
#     Repeated for each version:
#       <tr><td>[release date]</td><td>[Version]<ul>[changes]</ul></td></tr>
# ...

$historyContainer = $r.ParsedHtml.getElementsByName("history")[0]
While ($historyContainer.tagName -ne "tr") {
    $historyContainer = $historyContainer.parentElement
}
$historyContainer = $historyContainer.getElementsByTagName("table")[0]

ForEach ($versionRow in $historyContainer.getElementsByTagName("tr")) {
    $cells = $versionRow.getElementsByTagName("td")
    $rawDateString = $cells[0].InnerText

    If ($rawDateString -like '*in progress*') {
        continue
    }

    $dt = [DateTime] ($rawDateString -replace '(?<M>\w+)\s+(?<D>\d+)\w+,?\s+(?<Y>\d+)','${Y}-${M}-${D}')

    If (-not ($cells[1].InnerText -match "Version (?<VERSION>\d+(?:\.\d+)+)")) {
        Throw "Download page layout changed."
    }

    $version = $Matches.VERSION
    If (-not $currentVersion) {
        $currentVersion = $version
    }
    

    If ($version -ne "1.00") {
        # Initial version has no changes!
        $desc = $cells[1].getElementsByTagName("ul")[0].InnerHTML.Trim() `
            -replace '<li>'," * " -replace '<[^<>]+>' -replace "(?m)`n?^(\s*)$`n?",''
    } Else {
        $desc = " * Initial version"
    }

    $title = $dt -f "# $version (yyyy-MM-dd)"
    $changes += @("# $version ($($dt.ToString('yyyy-MM-dd')))`n$desc")
}

$notes = [String]::Join("`n`n", $changes)


New-Package @{
    Version      = $currentVersion
    ReleaseNotes = $notes
    
    # The download url needs to be different for each version for the download
    # caching to work properly!
    FileUrl      = "$setupUrl#$currentVersion"
}