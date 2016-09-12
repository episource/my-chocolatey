# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$versionInfo = Get-VersionInfoFromSourceforge `
    -Project "conemu" `
    -Filter  "/Stable/ConEmuPack\.(?<VERSION>\d+)\.7z"

# Expand version string: e.g. 160904 -> 16.09.04
$version             = $versionInfo.Version
$versionInfo.Version = ""
If ($version.length -ne 6) {
    Throw "Unsupported ConEmu version string: $version"
}
For ($i = 0; $i -lt 3; $i++) {
    If ($i -gt 0) {
        $versionInfo.Version += "."
    }
    $versionInfo.Version     += $version.Substring(2 * $i, 2).TrimStart("0")
}


# Query release notes
$notes = ""

# -UseBasicParsing makes .Links freeze when querying _posts!?
$notesListResponse = Invoke-WebRequest `
    "https://github.com/ConEmu/ConEmu.github.io/tree/master/_posts"
$notesUrls = $notesListResponse.Links | ?{ 
    $_.PSObject.Properties['title'] -and $_.title -match ".*build.*\.md" 
} | Sort-Object -Property 'title' -Descending | %{
    "https://github.com" + $_.href -replace "/blob/","/raw/" }

Write-Host "Collecting release notes. This might take some while."
$count = $notesUrls.length
$emptyLine = ""
For ($i = 0; $i -lt $count; $i++) {
    Write-Host -NoNewline "`r$emptyLine"
    $url = $notesUrls[$i]
    $status = "($($i+1)/$count) $url"
    $emptyLine = " " * $status.length
    Write-Host -NoNewline "`r$status"
    
    $response = Invoke-WebRequest -UseBasicParsing -Uri $url
    $notes   += $response.Content `
        -replace '---\s*','' `
        -replace 'build:','# build:'
    $notes   += "`n"
}
Write-Host "" # quit status line (newline)

$versionInfo.ReleaseNotes = $notes


New-Package -VersionInfo $versionInfo