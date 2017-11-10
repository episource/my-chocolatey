. $PSScriptRoot/chocolateyCommon.ps1

function Update-Config($xml, $xpath, $config) {
    ForEach ($configKey in $config.Keys) {
        $configValue     = $config.$configKey
        $node            = ($xml | Select-Xml $xpath).Node
        $node.$configKey = $configValue
    }
}


# Revert previous modifications first
& $PSScriptRoot/chocolateyUninstall.ps1

# Newer notepad++ installation no longer include a default config.model.xml
If (-not (Test-Path -Path $configModel)) {
    Copy-Item "$destdir/config.model.xml" $configModel
}

# Update configuration (config.model.xml)
Copy-Item -Path $configModel -Destination $configModelBackup
$xml = [xml](Get-Content $configModel)

$xpath = "NotepadPlus/GUIConfigs/GUIConfig[@name='TabSetting']"
$tabSetting = @{ 
    replaceBySpace = "yes"
}
Update-Config $xml $xpath $tabSetting 
    
$xpath = "NotepadPlus/GUIConfigs/GUIConfig[@name='ScintillaPrimaryView']"
$primaryView = @{ 
    Wrap         = "yes"
    edge         = "line"
    edgeNbColumn = "80"
}
Update-Config $xml $xpath $primaryView 

$xpath = "NotepadPlus/GUIConfigs/GUIConfig[@name='NewDocDefaultSettings']"
$newDocDefaults = @{ 
    format = "2"
}
Update-Config $xml $xpath $newDocDefaults 

$xml.Save($configModel)

# Update configuration (stylers.model.xml)
Copy-Item -Path $stylersModel -Destination $stylersModelBackup
$xml = [xml](Get-Content $stylersModel | %{ 
    $_ -replace 'name="TAG { <TITLE HEIGHT=100> }"','name="TAG { &lt;TITLE HEIGHT=100&gt; }"'} )

$fontConfig = @{ 
    fontName = "Consolas"
}

$xpath = "NotepadPlus/GlobalStyles/WidgetStyle[@name='Global override']"
Update-Config $xml $xpath $fontConfig 
    
$xpath = "NotepadPlus/GlobalStyles/WidgetStyle[@name='Default Style']"
Update-Config $xml $xpath $fontConfig 

$xml.Save($stylersModel)


# Update configuration (shortcuts.xml)
Copy-Item -Path $shortcuts -Destination $shortcutsBackup
$xml = [xml](Get-Content $shortcuts)

$keysToAddXml = [xml]@"
<KeysToAdd>
    <!-- SCI_LINEDELETE: Ctrl+D (custom), Ctrl+Shift+L (default) -->
    <ScintKey ScintID="2338" menuCmdID="0" Ctrl="yes" Alt="no" Shift="yes" Key="76">
        <NextKey Ctrl="yes" Alt="no" Shift="no" Key="68" />
    </ScintKey>
    <!-- SCI_LINEDELETE: Ctrl+D (custom), Ctrl+Shift+L (default) -->
    <ScintKey ScintID="2469" menuCmdID="42010" Ctrl="yes" Alt="no" Shift="yes" Key="68" />
</KeysToAdd>
"@
$keysToAdd = $xml.ImportNode($keysToAddXml.KeysToAdd, $true)

$scintillaKeysNode = $xml.SelectSingleNode("NotepadPlus/ScintillaKeys")
ForEach ($keyNode in $keysToAdd.ChildNodes) {
    $scintId = $keyNode | Select-Object -ExpandProperty ScintID `
        -ErrorAction SilentlyContinue
    If ($scintId) {
        $existingNode = $xml.SelectSingleNode(
            "NotepadPlus/ScintillaKeys/ScintKey[@ScintID='$scintId']")
        If ($existingNode) {
            $existingNode.ParentNode.RemoveChild($existingNode) | Out-Null
        }
    }
    
    $scintillaKeysNode.AppendChild($keyNode.Clone()) | Out-Null
}

$xml.Save($shortcuts)