# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1

$changesUrl       = "https://www.jam-software.de/treesize/changes.shtml"
$downloadLoginUrl = "https://www.jam-software.de/customers/directDownload.php"
$downloadUrl      = "https://www.jam-software.de/customers/includes/getDownload.php"


$license = Get-Variable "CFLicenseTreeSizePro" -ErrorAction SilentlyContinue
If (-not $license) {
    Throw "Missing license for JamSoftware Treesize Professional. Can't build..."
}

$changesResponse = Invoke-WebRequest $changesUrl
$changesDom      = $changesResponse.ParsedHtml.getElementById("changes")

$currentVersionTitle = $changesDom.getElementsByClassName("f_Heading2")[0].InnerText
If (-not ($currentVersionTitle `
        -match "Änderungen in V(?<VERSION>\d+(?:\.\d+){1,2})")) {
    Throw "Page layout changed!"
}
$currentVersion = $Matches.Version

$changes = $changesDom.innerHTML `
    -replace "`n","" `
    -replace "<h2[^<>]*>","`n`n# " `
    -replace "&nbsp;"," " `
    -replace "•","`n * " `
    -replace "<[^<>]*>","" `
    -replace "( |\t)+"," "


New-Package -VersionInfo @{
        Version      = $currentVersion
        ReleaseNotes = $changes
    } -PrepareFilesHook {
        $license = $global:CFLicenseTreeSizePro
    
        $loginPageResponse = Invoke-WebRequest $downloadLoginUrl `
            -SessionVariable directDownloadSession
        
        
        $loginData = [HashTable]::new($loginPageResponse.Forms['login'].Fields)
        $loginData['directDownloadUsername'] = $license.UserId
        $loginData['directDownloadKey']      = $license.LicenseKey
        
        $loginResponse = Invoke-WebRequest $downloadLoginUrl -Method Post `
            -Body $loginData -WebSession $directDownloadSession
            
            
        $downloadForm = $loginResponse.Forms | ?{
                $_.Fields['DirectDownload_Client_Id'] -ne $null `
                    -and $_.Fields['DirectDownload_Order_Item_Id'] -ne $null 
            } | Select-Object -First 1
        If (-not $downloadForm) {
            Throw "Direct download login failed: Wrong license data or download page changed."
        }
        
        $availableDownloads = `
            $loginResponse.ParsedHtml.getElementsByName('Download_Id')
        $downloadTitleRegex = 'Version[^\d]*(?<VERSION>\d+(\.\d+){1,2})[^\d].*((?<ARCH>\d{2})Bit)'
        $x64Download = $availableDownloads.item() | %{ 
                If ($_.InnerHTML -match $downloadTitleRegex) {
                    return @{ 
                        Version = $Matches.VERSION
                        Arch    = $Matches.ARCH
                        Id      = $_.value 
                    }
                } Else {
                    return @{ Version = ""; Arch = ""}
                }  
            } | ?{ $_.Arch -eq 64 } | Select-object -First 1
        If (-not $x64Download) {
            Throw "No x64 download found. Download page changed!?"
        }    
        
        $vp = ($_.Version -replace '(?:\+|-).*$').Split(".")
        $expectedVersion = "$($vp[0]).$($vp[1])$($vp[2])"
        If ($x64Download.Version -ne $expectedVersion) {
            Throw "Package version does not match the download page's version: $expectedVersion != $($x64Download.Version)"
        }
        
        
        $downloadData = [HashTable]::new($downloadForm.Fields)
        $downloadData['Download_Id'] = $x64Download.Id
        $downloadResponse = Invoke-WebRequest $downloadUrl -Method Post `
            -Body $downloadData -WebSession $directDownloadSession `
            -OutFile "tools\TreeSize-x64-Full.exe" -PassThru
            
        If ($downloadResponse.Headers['Content-Type'] `
                -ne "application/download") {
            Throw "Failed to download TreeSize Professional: Download page changed!?"
        }
    }