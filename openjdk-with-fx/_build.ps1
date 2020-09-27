# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


# Query github API to get url and version of the latest release
$jdkRepo = 'ojdkbuild/ojdkbuild'
$jdkFilename = "java-[0-9]+-openjdk-(?<VERSION>[0-9\.]+-[0-9]).windows\.ojdkbuild\.x86_64\.zip"
$jdkHashfile = "$jdkFilename\.sha256"


# Export the package (subject to _config.ps1)
$vi = Get-VersionInfoFromGithub -Repo $jdkRepo -File $jdkFilename -EnableRegex -Limit 20 -FindMax |
      Add-ChecksumFromGithubAsset -ChecksumFileRegex $jdkHashfile -Algorithm sha256 -Debug
      
# Massage the version identifier
# Chocolatey uses a flavored semver style
#  - "-" separated sufix introduces prerelease information
# Openjdk uses "-" sufix for build information
#  => merge revision and build number
$semverTokens = Get-SemverTokens $vi.Version -DefaultMajorMinorPatch
$revision = [int]$semverTokens.REVISION * 100 + [int]$semverTokens.PRERELEASE
$jdkMajorVersion = $($semverTokens.MAJOR)
$vi.Version = "$($semverTokens.MAJOR).$($semverTokens.MINOR).$($semverTokens.PATCH).$revision"


# Append JavaFX SDK files - find most recent binary release
$fxRepo = "openjdk/jfx"

function build-fxurls($version) {
    $fxShaUrl = "https://download2.gluonhq.com/openjfx/${version}/openjfx-${version}_windows-x64_bin-sdk.zip.sha256"
    
    try {
        write-verbose "Checking if fx build exists: $version"
        Invoke-WebRequest -UseBasicParsing -Method head -Uri $fxShaUrl | Out-Null
        write-verbose "Fx build found: $version"
        
        return @{
            FxZipUrl = "https://download2.gluonhq.com/openjfx/${version}/openjfx-${version}_windows-x64_bin-sdk.zip"
            FxShaUrl = $fxShaUrl
            JmodZipUrl = "https://download2.gluonhq.com/openjfx/${version}/openjfx-${version}_windows-x64_bin-jmods.zip"
            JmodShaUrl = "https://download2.gluonhq.com/openjfx/${version}/openjfx-${version}_windows-x64_bin-jmods.zip.sha256"
        }
    } catch {
        return $null
    }
}

$fxUrls = $null
Invoke-GithubApi `
        -ApiEndpoint "/repos/$fxRepo/git/matching-refs/tags/$jdkMajorVersion" `
        -ApiToken $global:CFGithubToken | %{
    $_.ref -replace "^refs/tags/",""
} | ConvertTo-SortedByVersion -Descending | ?{
    $fxUrls -eq $null
} | %{
    $fxUrls = build-fxurls $_
    if ($fxUrls -eq $null -and $_ -match "\+(0|ga)$") {
        $fxUrls = build-fxurls ($_ -replace "\+(0|ga)$","")
    }
}

if ($fxUrls -eq $null) {
    write-error "Failed to locate matching javafx sdk binary build"
    return
}

$fxSha = Get-ChecksumFromWeb -Url $fxUrls.FxShaUrl -ChecksumType Sha256 -EnableRegex -Filename '.*' -ValueOnly
$jmodSha = Get-ChecksumFromWeb -Url $fxUrls.JmodShaUrl -ChecksumType Sha256 -EnableRegex -Filename '.*' -ValueOnly
$vi.FileUrl = @() + $vi.FileUrl + $fxUrls.FxZipUrl + $fxUrls.JmodZipUrl
$vi.Checksum = @() + $vi.Checksum + "sha256:$fxSha" + "sha256:$jmodSha"


# Build package
New-Package -VersionInfo $vi -AutoUnzip:$false