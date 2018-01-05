Set-StrictMode -Version latest
$ErrorAction = "Stop"


function Set-ConfigItem($file, $section, $option, $value, $commentLines) {
    $nl = "`r`n"
    
    $sectionX = [Regex]::Escape($section)
    $optionX = [Regex]::Escape($option)
    
    $ini = Get-Content $file | Out-String
    
    $sectionPattern = "^[ \t]*\[$sectionX\][ \t]*\r?$"
    if (-not ($ini -match "(?ms)$sectionPattern")) {
        $ini += "$nl$nl[$section]$nl"
    }
    
    $optionPattern = "(?ms)(?<HEAD>$sectionPattern[^[]*)^(?<OPT_LINE>[ \t]*$optionX[ \t]*=[^\n\r]*)"
    if ($ini -match $optionPattern) {
        $ini = $ini -replace $optionPattern,"$($Matches["HEAD"])$option=$value"
    } else {
        $comment = [String]::Join("$nl;", $commentLines)
        if (-not [String]::IsNullOrEmpty($comment)) {
            $comment = "$nl;$comment"
        }
        $ini = $ini -replace "(?ms)$sectionPattern","[$section]$comment$nl$option=$value"
    }
    
    $ini.Trim() | Out-File $file -Encoding utf8
}


$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$greenshotDir = Join-Path $toolsDir "../../greenshot/tools"
$defaultIni = "$greenshotDir/greenshot-defaults.ini"
$fixedIni = "$greenshotDir/greenshot-fixed.ini"

Set-ConfigItem $fixedIni "Core" "UpdateCheckInterval" `
    "0" `
    "How many days between every update check? (0=no checks)"
Set-ConfigItem $defaultIni "Core" "ExcludePlugins" `
    "Box Plugin,Confluence Plugin,Dropbox Plugin,Flickr Plugin,Imgur Plugin,Jira Plugin,Office Plugin,Photobucket Plugin,Picasa-Web Plugin" `
    "Comma separated list of Plugins which are NOT allowed."
Set-ConfigItem $defaultIni "Core" "OutputFileFormat" `
    "png" `
    "Default file type for writing screenshots. (bmp, gif, jpg, png, tiff)"
Set-ConfigItem $defaultIni "Core" "Destinations" `
    "Editor,Clipboard" `
    "Which destinations? Possible options (more might be added by plugins) are: Editor, FileDefault, FileWithDialog, Clipboard, Printer, EMail, Picker"
Set-ConfigItem $defaultIni "Core" "Destinations" `
    "PNG,DIB" `
    "Specify which formats we copy on the clipboard? Options are: PNG, HTML, HTMLDATAURL and DIB"