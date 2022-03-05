Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$destdir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
$withDefaultShim = @( "$destdir\git-bash.exe", "$destdir\cmd\git.exe")
$startMenu = @{ LinkName="Git Bash"; TargetPath="$destdir\git-bash.exe" }

# Extract git portable
$portableZip = Get-Item "$destdir/PortableGit-*.7z.exe"
Get-ChocolateyUnzip -FileFullPath $portableZip.FullName -Destination $destdir
Remove-Item $portableZip

# Run portable git post install script: It creates necessary hardlinks
# First to some workarounds needed for the script to run properly during
# chocolatey install.
# Note: The post install script deletes itself causing a non zero exit code
# ("The batch file cannot be found.") which in turn fails the chocolatey
# installation. A temporary copy of the install script can be used as workarounds
# as the file is deleted by (original) name.
Set-Location $destdir
New-Item "dev/shm" -Force -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
New-Item "dev/mqueue" -Force -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
'export PATH="/mingw64/bin:$PATH"' | Out-File etc/post-install/00-path.post -Encoding ASCII

Copy-Item post-install.bat post-install.tmp.bat | Out-Null
& ./post-install.tmp.bat
Remove-Item post-install.tmp.bat


# Only create shims for the files listed in $withDefaultShim
Set-AutoShim -Pattern $withDefaultShim -Invert -Mode Ignore | Out-Null

# Install start menu shortcut
Install-StartMenuLink @startMenu


# Setup default git config
# Config file precedence of git for windows (lowest first):
#            C:\ProgramData\Git\config
#   --system $destdir\mingw64\etc\gitconfig
#   --global $env:USERPROFILE\.gitconfig
#   --local  <Repo>
# C:\ProgramData\Git\config (universal config) is also read by applications
# other than git for windows - namely all libgit2 based software. Hence
# everything that is not specific to git for windows should go to the universal
# config file. This is also what the git for windows installer does - it writes
# its built-in default configuration to the universal config file. We will does
# something similiar here.
$gitcmd = "$destdir/cmd/git.exe"

# Create universal config file if it does not yet exist
$universalConfig = "$env:ProgramData\Git\config"
If (-not (Test-Path $universalConfig)) {
    # Force: Create parent directories
    New-Item -Force $universalConfig
}

# These config keys won't be moved from the system config file to the universal
# config file
$gfwSpecific = @( 'http.sslcainfo' )

# Move built-in defaults to universal config file
$defaults = @{}
& $gitcmd config --system --list | Out-String -Stream | %{
    $item  = $_.Split("=")
    $defaults[$item[0]] = $item[1]
}

# The git for windows installer requests user input regarding the following
# configuration keys. In this nupkg we use custom defaults instead:
#   core.fscache is checked per default during an interactive git for windows 
#   installation. It seems to be an usefull option.
$defaults["core.fscache"] = "true"
#   The git for windows built-in default configuration includes
#   core.autocrlf=true. This enables automatic EOL-conversion. The interactive
#   git for windows installer ask the user to choose the intended configuration.
#   I think, that it's the user's task to properly sanitize line endings. This
#   matches git's implicit default of core.autocrlf=false. Taken into account,
#   that EOL-conversion might even break some binary files, this nupkg uses
#   core.autocrlf as default for new installations.
$defaults["core.autocrlf"] = "false" 

# Apply defaults: Keep existing user-defined configuration
ForEach ($key in $defaults.Keys) {
    If (-not ($gfwSpecific -contains $key)) {
        $value = $defaults[$key]
    
        # Do not overwrite existing universal config keys
        # git config exit codes: 0 - key was found; 1 - key wasn't found
        Try {
            $current = & $gitcmd config -f $universalConfig $key | Out-String
        } Catch {
           # ErrorAction Stop treats $LastExitCode != 0 as error 
        }
        
        If ($LastExitCode -ne 0) {
            # Key does not exist in universal config # => defaults can be
            # applied safely without overwriting any user defined configuration
            & $gitcmd config -f $universalConfig $key $value | Out-Null
        } ElseIf ($current) {
            Write-Warning `
                ("Config key $key already found in $universalConfig`n" + `
                "- leaving configuration as-is: $key=$current")
        } Else {
            Write-Warning `
                ("Config key $key already found in $universalConfig`n" + `
                "- leaving configuration as-is.")
        }
                
        # Remove the config key from the system config file so that it does not
        # hide the configuration from the universal config file
        & $gitcmd config --system --unset-all $key
    }
}