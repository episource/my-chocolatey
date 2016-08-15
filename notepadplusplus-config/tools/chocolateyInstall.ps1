. $PSScriptRoot/chocolateyCommon.ps1

function Update-Config($xml, $xpath, $config) {
    ForEach ($configKey in $config.Keys) {
        $configValue     = $config.$configKey
        $node            = ($xml | Select-Xml $xpath).Node
        $node.$configKey = $configValue
    }
}

If (Test-Path $configModelBackup) {
    Write-Error `
        "config.model.xml has already been changed - uninstall package first!"
    return
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
$xml = [xml](Get-Content $stylersModel)

$fontConfig = @{ 
    fontName = "Consolas"
}

$xpath = "NotepadPlus/GlobalStyles/WidgetStyle[@name='Global override']"
Update-Config $xml $xpath $fontConfig 
    
$xpath = "NotepadPlus/GlobalStyles/WidgetStyle[@name='Default Style']"
Update-Config $xml $xpath $fontConfig 

$xml.Save($stylersModel)