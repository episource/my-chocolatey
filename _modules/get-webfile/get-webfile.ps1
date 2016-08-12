# Copyright 2016 Philipp Serr (episource)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Based on Version 3.7.3 taken from http://poshcode.org/3226
# Authors: Joel Bennet, Bill Barry, Gwen Dallas, Mike Ling
# Original license: CC0 "No Rights Reserved"
# (see http://poshcode.org/Terms.html)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

Import-Module import-callerpreference

<# 
.SYNOPSIS 
    Downloads a file or page from the web (aka wget for PowerShell).

.DESCRIPTION 
    Downloads a file or page from the web. It supports the Content-Disposition
    header to choose a file name. This is the primary reason to prefer this
    cmdlet over the built-in Invoke-WebRequest for downloading files.

.PARAMETER Url	
    Url pointing specifying the file to be downloaded.

.PARAMETER OutFile
    Path to the downloaded file. If ommited, the file is downloaded to the
    current directory. If pointing to an existing directory, the file is saved
    to that specified directory. In either case the file name is determined
    automatically, respecting the Content-Disposition header.

.PARAMETER Quiet
Turn off the progress reports.

.EXAMPLE 
    Get-WebFile http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml

    Download service-names-port-numbers.xml to the current directory.
    
.EXAMPLE 
    Get-WebFile http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml C:\Temp\Ports.xml

    Download service-names-port-numbers.xml and save as C:\Temp\Ports.xml
    
.NOTES 	
    Get-WebFile (aka wget for PowerShell)	
    History:
    v2016.08.02 - Use VirusTotal to scan files prior to downloading
    v2016.08.01 - Create a powershell module for Get-WebFile
                - Add suppport for ftp
                - Determine file name automatically, if OutFile specifies an
                  existing directory
                - Improve Content-Disposition parsing
                - Rename FileName parameter to OutFile (following the naming
                  used by Invoke-WebRequest)
                - Removed Passthru parameter: Use Invoke-WebRequest if needed
                - Reformat
    v3.7.3      - Checks to see if URL is formatted properly (contains http or
                  https)
    v3.7.2      - Puts a try-catch block around 
                  $writer = new-object System.IO.FileStream and returns/breaks
                  to prevent further execution if fso creation fails (e.g. if
                  path is invalid). 
                  Note: known issue -- Script hangs if you try to connect to a
                  good FQDN (e.g. www.google.com) with a bad port (e.g. 81).
                  It will work fine if you use "http://192.168.1.1:81" but
                  hang/crash if you use "http://www.google.com:81".
    v3.7.1      - Puts a try-catch block around the $request.GetResponse() call
                  to prevent further execution if the page does not exist,
                  cannot connect to server, can't resolve host, etc.
    v3.7        - [int] to [long] to support files larger than 2.0 GB
    v3.6        - Add -Passthru switch to output TEXT files 
    v3.5        - Add -Quiet switch to turn off the progress reports ...
    v3.4        - Add progress report for files which don't report size
    v3.3        - Add progress report for files which report their size
    v3.2        - Use the pure Stream object because StreamWriter is based on
                  TextWriter:
                - it was messing up binary files, and making mistakes with
                  extended characters in text
    v3.1        - Unwrap the filename when it has quotes around it
    v3          - Rewritten completely using HttpWebRequest + HttpWebResponse to
                  figure out the file name, if possible
    v2          - Adds a ton of parsing to make the output pretty
                  added measuring the scripts involved in the command, (uses
                  Tokenizer)

.LINK	
    http://poshcode.org/3226	
#>	
function Get-WebFile {
	[cmdletbinding()]    
	param( 
    	[Parameter(Position=0,
		Mandatory=$true,
		HelpMessage="URL to download.")]
        [Alias("Uri")]
		[string]$Url = (Read-Host "The URL to download"),		
		
		[Parameter(Position=1,
		Mandatory=$false,
		HelpMessage="Download file to this path.")]
      	[Object]$OutFile = $null,	
        
        [Parameter(
        Mandatory=$false,
        HelpMessage="Provide an VirusTotal.com API key to enable virus scanning for https.")]
        [String]$VtApiKey = $null,
		
		[Parameter(HelpMessage="Turn off the progress reports.")]
      	[switch]$Quiet
	)
    Import-CallerPreference -AdditionalPreferences "ProgressBarId"
    
    $ProgressBarId = $ProgressBarId + 1
    $ProgressBarActivity = "Downloading $Url"
    Write-Progress -Activity $ProgressBarActivity `
            -Id $ProgressBarId -ParentId ($ProgressBarId - 1) -PercentComplete 0
    
    $vtResult = $null
	if ($Url -match "^https?://") {
        If ($VTApiKey -ne $null -and $VtApiKey -ne "") {
            $vtResult = $null
            Try {
                $vtResult = Get-VtScan -ApiKey $VtApiKey -Url $url
            } Catch {
                Write-Warning "VirusTotal.com scan did not provide any results:`n$_"
            }
                
            If ($vtResult) {
                If ($vtResult.positives -eq 0) {
                    Write-Verbose (
                        "No threat found!`n -> $Url`n" +
                        "VirusTotal.com positives: " +
                            "$($vtResult.positives)/$($vtResult.totalScans)`n" +
                        "Detailed VirusTotal.com reports:`n" +
                        " -> File: $($vtResult.permalink)`n" +
                        " -> Url : $($vtResult.urlPermalink)"
                    )
                } Else {
                    Write-Warning -WarningAction Inquire (
                        "Threat found!`n -> $Url`n" +
                        "VirusTotal.com positives: " +
                            "$($vtResult.positives)/$($vtResult.totalScans)`n" +
                        "Detailed VirusTotal.com reports:`n" +
                        " -> File: $($vtResult.permalink)`n" +
                        " -> Url : $($vtResult.urlPermalink)`n" +
                        "Please check detailed report! Press [H] if unsure."
                    )
                }
            }
        }
    
   		$request = [System.Net.HttpWebRequest]::Create($Url)
        
        #http://stackoverflow.com/questions/518181/too-many-automatic-redirections-were-attempted-error-message-when-using-a-httpw
        $request.CookieContainer = New-Object System.Net.CookieContainer
	} elseif ($Url -match "^ftp://") {
        If ($VTApiKey -ne $null) {
            Write-Warning "VirusTotal.com does not scan ftp-urls."
        }
    
        $request = [System.Net.FtpWebRequest]::Create($Url)
        $request.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
        $request.UsePassive = $true
        $request.UseBinary = $true
    } else {  
   		Write-Error "Connection protocol not specified or not supported. Recommended action: Try again using protocol (for example 'http://$Url') instead. Function aborting..."
		return
   	}
	
	try {
		$response = $request.GetResponse()
		Write-Verbose "Response Status: $($response.StatusCode) ContentType: $($response.ContentType) CharacterSet: $($response.CharacterSet)"
   	} catch {
  		Write-Error $_.Exception.Message
   		return
	}
 
    try {
        $location = Get-Location | Convert-Path
        
        if ( $OutFile -and -not (Split-Path $OutFile) ) {
            $OutFile = Join-Path $location $OutFile
        } 
        
        $outDir = $location
        if ($OutFile -ne $null -and (Test-Path -PathType "Container" $OutFile)){
            $outDir = $OutFile
            $OutFile = $null
        }
        
        if ($OutFile -eq $null) {
            $fileName = $null
            $contentDispositionHeader = $response.Headers["Content-Disposition"]
            if ($contentDispositionHeader -ne $null) {
                $contentDisposition = New-Object `
                    System.Net.Mime.ContentDisposition $contentDispositionHeader
                $fileName = $contentDisposition.FileName
            }        
            
            if ($fileName -eq $null) {
                $fileName = Split-Path -Leaf -Path $Url
            }
            
            if (-not $fileName -eq ( Split-Path -Leaf -Path $fileName) ) {
                Write-Error "Illegal filename: $fileName"
                return
            }
                
            $OutFile = Join-Path $OutDir $fileName
        }
     
        if ( ($response.StatusCode -eq 200) `
                -or ($response.StatusCode -eq [System.Net.FtpStatusCode]::OpeningData)) {
            $outStream = New-Object System.IO.FileStream $OutFile, Create
        
            try {
                [long]$goal = $response.ContentLength
                $responseStream = $response.GetResponseStream()
          
                [byte[]]$buffer = New-Object byte[] 4096
                [long]$total = [long]$count = 0
                do {
                    $count = $responseStream.Read($buffer, 0, $buffer.Length);
                    if ($OutFile) {
                        $outStream.Write($buffer, 0, $count);
                    } 
                    
                    $total += $count
                    if ($goal -gt 0) {
                        Write-Progress -Activity $ProgressBarActivity `
                            -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                            -Status "Saving $total of $goal bytes..." `
                            -PercentComplete (($total/$goal)*100)
                    } else {
                        Write-Progress -Activity $ProgressBarActivity `
                            -Id $ProgressBarId -ParentId ($ProgressBarId - 1) `
                            "Saving $total bytes..."
                    }
                } while ($count -gt 0)
            } catch {
                Write-Error $_.Exception.Message
                return
            } finally {
                $outStream.Close()
            }
            
            If ($vtResult -ne $null) {
                $expected = $vtResult.sha256.ToLower()
                $actual   = (Get-FileHash -Path $OutFile -Algorithm sha256). `
                    Hash.ToLower()
                
                If ($expected -ne $actual) {
                    Write-Warning -WarningAction Inquire (
                        "The sha256 hash of the downloaded file does not " + 
                        "match the hash reported by VirusTotal.com!`n" +
                        "Expected : $expected`n" +
                        "Actual   : $actual`n"
                    )
                }
            }
        }
    } finally {
        $response.Close()
        Write-Progress -Activity $ProgressBarActivity `
            -Id $ProgressBarId -ParentId ($ProgressBarId - 1) -Completed
    }
    
   	return  Get-Item $OutFile
}