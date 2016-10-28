# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$fileListUrl = "http://download.videolan.org/vlc/last/win64"
$fileList = Invoke-Webrequest -UseBasicParsing $fileListUrl

$zipRegex = "vlc-(?<VERSION>\d+(?:\.\d+){1,2})-win64\.zip"
$zipUrl = $null
$sha256Url = $null
$version = $null

ForEach ($link in $fileList.Links) {
    $href = $link.href
    
    If ($href -match "$zipRegex$") {
        $zipUrl = "$fileListUrl/$href"
        $version = $Matches.VERSION
    }
    
    If ($href -match "$zipRegex\.sha256$") {
        $sha256Url = "$fileListUrl/$href"
        $version = $Matches.VERSION
    }
}

If (-not $zipUrl -or -not $sha256Url -or -not $version) {
    Throw "Failed to retrieve version information."
}


$sha256Response = Get-ChecksumFromWeb -Url $sha256Url -Filename '.*' -EnableRegex
$sha256 = "sha256:$($sha256Response.Checksum)"


New-Package @{
    Version = $version
    FileUrl = $zipUrl
    Checksum = $sha256
}