# Enable common parameters
[CmdletBinding()] Param()
# Import my-chocolatey config & modules
. $PSScriptRoot/../_root.ps1


$versionInfo = Get-VersionInfoFromGithub `
    -Repo "Maximus5/ConEmu" `
    -EnableRegex `
    -File  "ConEmuPack\.\d+\.7z" `
    -ExtractVersionHook { 
        $version = $versionRaw = $_.tag_name -replace "^v"
        [String]::Join(".", @( $version.Split(".") | %{ [Int]$_ }))
    }

# lazy initialize release notes
$versionInfo.ReleaseNotes = {
    $notes = ""


    $notesUrls = Invoke-GithubApi `
        "/repos/ConEmu/ConEmu.github.io/contents/_posts/" | ?{
            $_.name -match ".*build.*\.md" } | `
            Sort-Object -Property 'name' -Descending | %{
            $_.download_url }    

    Write-Host "Collecting release notes. This might take some while."
    $count = $notesUrls.length
    $emptyLine = ""
    For ($i = 0; $i -lt $count; $i++) {
        Write-Host -NoNewline "`r$emptyLine"
        $url = $notesUrls[$i]
        $status = "($($i+1)/$count) $url"
        $emptyLine = " " * $status.length
        Write-Host -NoNewline "`r$status"
        
        $response = Invoke-WebRequest -Uri $url
        $notes   += $response.Content `
            -replace '---\s*','' `
            -replace 'build:','# build:'
        $notes   += "`n"
    }
    Write-Host "" # quit status line (newline)

    return $notes
}


New-Package -VersionInfo $versionInfo