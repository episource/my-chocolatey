# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$versionRegex         = 'Latest Version:\s*[^v]*v(?<VERSION>\d+(\.\d+){1,2})'
$zipSha1Regex         = '<b>Without Installer \(ZIP\):</b>\s*(?<SHA1>[0-9a-fA-F]{40})'
#$downloadUrlTemplate  = 'https://binaryfortressdownloads.com/Download/BFSFiles/103/FileSeek-$rawVersion.zip'
$downloadUrlTemplate = 'https://www.binaryfortress.com/Data/Download/?package=fileseek&noinstall=1&log=103' #redirect to current version
$downloadHtmlResponse = Invoke-WebRequest -UseBasicParsing `
    -Uri "https://www.fileseek.ca/Download/"
    
If (-not ($downloadHtmlResponse.Content -match $versionRegex)) {
    Throw "Failed to parse fileseek download page: version not found"
}
$rawVersion   = $Matches.VERSION
$versionParts = $rawVersion.Split('.')
While ($versionParts.length -lt 3) {
    $versionParts += 0
}
$fileUrl = $ExecutionContext.InvokeCommand.ExpandString($downloadUrlTemplate)


If (-not ($downloadHtmlResponse.Content -match $zipSha1Regex)) {
    Throw "Failed to parse fileseek download page: checksum not found"
}
$sha1 = $Matches.SHA1


$changesRegex        = "(?si)(?<CHANGELOG><h1.+FileSeek Change Log</h1>.+First public version</li>\s*</ul>)"
$changesHtmlResponse = Invoke-WebRequest -UseBasicParsing `
    -Uri "https://www.fileseek.ca/ChangeLog/"
If (-not ($changesHtmlResponse.Content -match $changesRegex)) {
    Throw "Failed to parse fileseek download page: changelog not found"
}
$changelog = $Matches.CHANGELOG `
    -replace '<h1[^>]*>([^<]+)</h1>','# $1' `
    -replace '<h2[^>]*>([^<]+)</h2>','## $1' `
    -replace '<ul[^>]*>\s*','' `
    -replace '</ul>','' `
    -replace '<li>',' * ' `
    -replace '</li>','' `
    -replace '&bull;','-' `


New-Package @{
    Version      = [String]::Join(".", $versionParts)
    FileUrl      = $fileUrl
    Checksum     = "sha1:$sha1"
    ReleaseNotes = $changelog
}