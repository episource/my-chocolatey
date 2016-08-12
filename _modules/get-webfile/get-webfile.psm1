# Get-WebFile Version 3.7.3 taken from http://poshcode.org/3226
# Authors: Joel Bennet, Bill Barry, Gwen Dallas, Mike Ling
# License: CC0 "No Rights Reserved" (see http://poshcode.org/Terms.html)

function Get-WebFile {
<# 
	.SYNOPSIS 
	Downloads a file or page from the web.
	
	.DESCRIPTION 
	Downloads a file or page from the web (aka wget for PowerShell).
	
	.PARAMETER URL	
	The URL to download.
	
	.PARAMETER FileName
	Download file path.
	If ommitted, the name is autmaitcally determined and
	downloaded to the current directory.
	
	.PARAMETER Passthru
	Output text files to the pipeline.
	
	NOTE: Content type must be text/html, text/xml, 
	
	 Content
	
	.PARAMETER Quiet
	Turn off the progress reports.
	
	.EXAMPLE 
	Get-WebFile http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml
	
	Download service-names-port-numbers.xml to the current directory.
	
	.EXAMPLE 
	Get-WebFile http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml C:\Temp\Ports.xml
	
	Download service-names-port-numbers.xml and save as C:\Temp\Ports.xml
	
	.NOTES 	
	Get-WebFile by Gwen Dallas (aka wget for PowerShell)	
	History:
	v3.7.3 - Checks to see if URL is formatted properly (contains http or https)
	v3.7.2 - Puts a try-catch block around $writer = new-object System.IO.FileStream and returns/breaks to 
             prevent further execution if fso creation fails (e.g. if path is invalid). Note: known issue --
             Script hangs if you try to connect to a good FQDN (e.g. www.google.com) with a bad port (e.g. 81).
             It will work fine if you use "http://192.168.1.1:81" but hang/crash if you use 
             "http://www.google.com:81".
	v3.7.1 - Puts a try-catch block around the $request.GetResponse() call to prevent further execution if
             the page does not exist, cannot connect to server, can't resolve host, etc.
	v3.7 -   [int] to [long] to support files larger than 2.0 GB
	v3.6 -   Add -Passthru switch to output TEXT files 
	v3.5 -   Add -Quiet switch to turn off the progress reports ...
	v3.4 -   Add progress report for files which don't report size
	v3.3 -   Add progress report for files which report their size
	v3.2 -   Use the pure Stream object because StreamWriter is based on TextWriter:
             it was messing up binary files, and making mistakes with extended characters in text
	v3.1 -   Unwrap the filename when it has quotes around it
	v3   -   Rewritten completely using HttpWebRequest + HttpWebResponse to figure out the file name, if possible
	v2   -   Adds a ton of parsing to make the output pretty
             added measuring the scripts involved in the command, (uses Tokenizer)
	
	.LINK	
	http://poshcode.org/3219	
#>	
	[cmdletbinding()]    
	param( 
    	[parameter(Position=0,
		Mandatory=$true,
		HelpMessage="URL to download.")]
		[string]$URL = (Read-Host "The URL to download"),		
		
		[parameter(Position=1,
		Mandatory=$false,
		HelpMessage="Download file path.")]
      	[Object]$FileName = $null,		
		
		[parameter(HelpMessage="Output text files.")]
		[switch]$Passthru,
		
		[parameter(HelpMessage="Turn off the progress reports.")]
      	[switch]$Quiet
	)
	
	if ($url.Contains("http")) {
   		$request = [System.Net.HttpWebRequest]::Create($url)
	} 
	else {  
   		$URL_Format_Error = [string]"Connection protocol not specified. Recommended action: Try again using protocol (for example 'http://" + $url + "') instead. Function aborting..."
   		Write-Error $URL_Format_Error
		return
   	}
	
	#http://stackoverflow.com/questions/518181/too-many-automatic-redirections-were-attempted-error-message-when-using-a-httpw
	$request.CookieContainer = New-Object System.Net.CookieContainer

	try {
		$responce = $request.GetResponse()
		Write-Verbose "Responce Status: $($responce.StatusCode) ContentType: $($responce.ContentType) CharacterSet: $($responce.CharacterSet)"
   	}
   	catch {
   		Write-Error $error[0].Exception.InnerException.Message
   		return
	}
 
   	if ( $FileName -and -not (Split-Path $FileName) ) {
		$FileName = Join-Path (Get-Location -PSProvider "FileSystem") $FileName
   	} 
   	elseif ((-not $Passthru -and ($FileName -eq $null)) -or (($FileName -ne $null) -and (Test-Path -PathType "Container" $FileName))) {
    	[string]$FileName = ([regex]'(?i)filename=(.*)$').Match( $responce.Headers["Content-Disposition"] ).Groups[1].Value
      	$FileName = $FileName.Trim("\/""'")
      	if ( -not $FileName ) {
        	$FileName = $responce.ResponseUri.Segments[-1]
         	$FileName = $FileName.Trim("\/")
         	if(-not $FileName) { 
            	$FileName = Read-Host "Please provide a file name"
         	}
         	$FileName = $FileName.trim("\/")
         	if( -not ([IO.FileInfo]$FileName).Extension) {
            	$FileName = $FileName + "." + $responce.ContentType.Split(";")[0].Split("/")[1]
         	}
      	}
      	$FileName = Join-Path (Get-Location -PSProvider "FileSystem") $FileName
   	}
   	if ( $Passthru ) {	
		try {	
			#Can't encode if character set is $null (e.g. where ContentType is application/xml)
			if ( $responce.CharacterSet ) { 
				$encoding = [System.Text.Encoding]::GetEncoding( $responce.CharacterSet )
      			[string]$output = ""
			} else {								
				Write-Warning "Can't output ContentType: $($responce.ContentType) to the pipeline."
				$Passthru = $false
			}
	   	}
	   	catch {
	   		Write-Error $error[0].Exception.InnerException.Message
	   		return
		}
   	}
 
	if ( $responce.StatusCode -eq 200 ) {
   		[long]$goal = $responce.ContentLength
      	$reader = $responce.GetResponseStream()
      	if ($FileName) {
        	try {
         		$writer = New-Object System.IO.FileStream $FileName, "Create"
         	}
         	catch {
         		Write-Error $error[0].Exception.InnerException.Message
         		return
         	}
      	}
      	[byte[]]$buffer = New-Object byte[] 4096
      	[long]$total = [long]$count = 0
      	do {
        	$count = $reader.Read($buffer, 0, $buffer.Length);
         	if ($FileName) {
            	$writer.Write($buffer, 0, $count);
         	} 
         	if ($Passthru) {
            	$output += $encoding.GetString($buffer,0,$count)
         	} elseif (-not $Quiet) {
            	$total += $count
            	if ($goal -gt 0) {
               		Write-Progress "Downloading $url" "Saving $total of $goal" -id 0 -PercentComplete (($total/$goal)*100)
            	} else {
               		Write-Progress "Downloading $url" "Saving $total bytes..." -id 0
            	}
         	}
      	} while ($count -gt 0)
      
      	$reader.Close()
      	if ($FileName) {
        	$writer.Flush()
         	$writer.Close()
      	}
      	if ($Passthru) { $output }
   	}
   	$responce.Close()
   	if ( $FileName ) { Get-Item $FileName }
}#end