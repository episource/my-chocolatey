# Enable common parameters
[CmdletBinding()] Param()

Set-StrictMode -Version latest
$ErrorAction = "Stop"

# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Retrieve version + url
$dlIndexUrl = "http://www.oracle.com/technetwork/java/javase/downloads/index.html"
$jdkVersion = 8

$dlIndexRaw = Invoke-WebRequest -UseBasicParsing $dlIndexUrl
$dlIndexRaw -match "href=""(?<JDKINDEXURL>/technetwork/java/javase/downloads/jdk${jdkVersion}+-downloads-\d+.html)""" | Out-Null
$dlJdkIndexUrl = "http://www.oracle.com" + $Matches.JDKINDEXURL
$dlJdkIndexRaw = Invoke-WebRequest -UseBasicParsing $dlJdkIndexUrl

$dlJdkIndexRaw -match "\['jdk-(?<VERMAJOR>\d+)u(?<VERPATCH>\d+)-windows-x64.exe'\] = {[^}]*""filepath"":""(?<URL>[^""]+)""[^}]*""SHA256"":""(?<SHA256>[^""]+)""" | Out-Null

$jdkVersion = "$($Matches.VERMAJOR).0.$($Matches.VERPATCH)"
$jdkWin64Url = $Matches.URL
$jdkWin64Sha256 = $Matches.SHA256.ToLower()

write-host $jdkWin64Url


# Use custom download hook to send the license acceptance automatically
$downloadHook = {
    $toolsDir = Join-Path $_.BuildDir "tools"
    
    $file = Get-WebFile -Url $jdkWin64Url -OutFile $toolsDir -Cookies @{ "oraclelicense"="accept-securebackup-cookie" }
    $actualSha256 = (Get-FileHash -Path $file -Algorithm sha256).Hash.ToLower()
    
    if ($actualSha256 -ine $jdkWin64Sha256) {
        Write-Error "File hash validation failed.`nFile: $file`nAlgorithm: sha256`nExpected: $jdkWin64Sha256`nActual: $actualSha256"
        return
    }  
}


# build it
New-Package -VersionInfo @{
    Version  = $jdkVersion
    FileUrl  = $jdkWin64Url
    Cookies  = @{ "oraclelicense"="accept-securebackup-cookie" }
    Checksum = "sha256:$jdkWin64Sha256"
}