Set-StrictMode -Version latest
$ErrorAction = "Stop"

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$x64dbgDir = Join-Path $toolsDir "../../x64dbg/tools"

# Extract apis_def
# Use temp directory to work around bug in Get-ChocolateyUnzip:
# If zip basename and targetdirectory are equal and both are in the same
# directory, ChocolateyUnzip moves the content to the common parent directory
$apisDir = "$toolsDir/apis_def/"
Remove-Item -R $apisDir -ErrorAction SilentlyContinue
Get-ChocolateyUnzip -FileFullPath "$toolsDir/apis_def.zip" -Destination $apisDir


@( "x64", "x32" ) | % {
    $platform = $_
    $pluginExt = @{ "x64"="dp64"; "x32"="dp32"}[$platform]

    # plugin definition
    New-Item -Type Directory "$x64dbgDir/release/$platform/plugins" -ErrorAction SilentlyContinue
    Copy-Item "$toolsDir/xAnalyzer.$pluginExt" "$x64dbgDir/release/$platform/plugins" -Force

    # link to api definition
    $apisDirLnk = "$x64dbgDir/release/$platform/plugins/apis_def"
    $apisDirLnkItem = Get-Item $apisDirLnk -ErrorAction SilentlyContinue
        
    If ($apisDirLnkItem -and $apisDirLnkItem.Attributes -match "ReparsePoint") {
        # link already exists - nothing to do
    } Else {
        If ($apisDirLnkItem) {
            $bak = "$apisDirLnk.bak"
            Remove-Item -R $bak -ErrorAction SilentlyContinue
            Move-Item $apisDirLnkItem $bak
        }
        
        New-Item -Path $apisDirLnk -ItemType SymbolicLink -Value $apisDir
    }
}