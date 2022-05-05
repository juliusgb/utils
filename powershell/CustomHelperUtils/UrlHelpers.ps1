# Usage:
#   $Url='https://community.chocolatey.org/api/v2'
#   $statusCode = Get-UrlStatusCode $Url
function Get-UrlStatusCode {
  param (
    [string] $Url
  )
  try {
    Invoke-WebRequest -Uri $Url -UseBasicParsing | Select-Object statuscode,statusdescription,content
  }
  catch [Net.HttpWebRequest] {
    # display whole exception
    $PSItem.Exception
  }
}

# Usage:
#	  PS C:\> Get-UrlRedirect -Url 'http://go.microsoft.com/fwlink/?LinkID=210601'
# Source: https://powershellmagazine.com/2013/01/29/pstip-retrieve-a-redirected-url/
Function Get-UrlRedirect {
    Param (
        [Parameter(Mandatory=$true)]
        [String]$Url
    )

    $request = [System.Net.WebRequest]::Create($url)
    $request.AllowAutoRedirect=$false
    $response=$request.GetResponse()

    If ($response.StatusCode -eq "Found") {
        $response.GetResponseHeader("Location")
    }
}

# I need this when I had to gather all URLs to be safelisted.
# Source:  https://stackoverflow.com/a/45593554
# Usage: Get-UrlRedirectionTargets -Enumerate http://microsoft.com/about
<#
.SYNOPSIS
Gets a URL's redirection target(s).

.DESCRIPTION
Given a URL, determines its redirection target(s), as indicated by responses
with 3xx HTTP status codes.

If the URL is not redirected, it is output as-is.

By default, the ultimate target URL is determined (if there's a chain of
redirections), but the number of redirections that are followed is limited
to 50 by default, which you may change with -MaxRedirections.

-Enumerate enumerates the redirection chain and returns an array of URLs.

.PARAMETER Url
The URL whose redirection target to determine.
You may supply multiple URLs via the pipeline.

.PARAMETER MaxRedirections
Limits the number of redirections that are followed, 50 by default.
If the limit is exceeded, a non-terminating error is reported.

.PARAMETER Enumerate
Enumerates the chain of redirections, if applicable, starting with
the input URL itself, and outputs it as an array.

If the number of actual redirections doesn't exceed the specified or default
-MaxRedirections value, the entire chain up to the ultimate target URL is
enumerated.
Otherwise, a warning is issued to indicate that the ultimate target URL wasn't
reached.

All URLs are output in absolute form, even if the targets are defined as
relative URLs.

Note that, in order to support multiple input URLs via the pipeline, each
array representing a redirection chain is output as a *single* object, so
with multiple input URLs you'll get an array of arrays as output.

.EXAMPLE
> Get-UrlRedirectionTargets http://cnn.com
http://www.cnn.com

.EXAMPLE
> Get-UrlRedirectionTargets -Enumerate http://microsoft.com/about
http://microsoft.com/about
https://microsoft.com/about
https://www.microsoft.com/about
https://www.microsoft.com/about/
https://www.microsoft.com/about/default.aspx
https://www.microsoft.com/en-us/about/

.NOTES
This function uses the [System.Net.HttpWebRequest] .NET class and was 
inspired by http://www.powershellmagazine.com/2013/01/29/pstip-retrieve-a-redirected-url/
#>
Function Get-UrlRedirectionTargets {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory, ValueFromPipeline)] [Uri] $Url,
    [switch] $Enumerate,
    [int] $MaxRedirections = 50 # Use same default as [System.Net.HttpWebRequest]
  )
  process {
    try {
      if ($Enumerate) { 
        # Enumerate the whole redirection chain, from input URL to ultimate target,
        # assuming the max. count of redirects is not exceeded.
        # We must walk the chain of redirections one by one.
        # If we disallow redirections, .GetResponse() fails and we must examine
        # the exception's .Response object to get the redirect target.
        $nextUrl = $Url
        $urls = @( $nextUrl.AbsoluteUri ) # Start with the input Uri
        $ultimateFound = $false
        # Note: We add an extra loop iteration so we can determine whether
        #       the ultimate target URL was reached or not.
        foreach($i in 1..$($MaxRedirections+1)) {
          Write-Verbose "Examining: $nextUrl"
          $request = [System.Net.HttpWebRequest]::Create($nextUrl)
          $request.AllowAutoRedirect = $False
          try {
            $response = $request.GetResponse()
            # Note: In .NET *Core* the .GetResponse() for a redirected resource
            #       with .AllowAutoRedirect -eq $False throws an *exception*.
            #       We only get here on *Windows*, with the full .NET Framework.
            #       We either have the ultimate target URL, or a redirection
            #       whose target URL is reflected in .Headers['Location']
            #       !! Syntax `.Headers.Location` does NOT work.
            $nextUrlStr = $response.Headers['Location']
            $response.Close()
            # If the ultimate target URL was reached (it was already
            # recorded in the previous iteration), and if so, simply exit the loop.
            if (-not $nextUrlStr) {
              $ultimateFound = $true
              break
            }
          } 
          catch [System.Net.WebException] {
            # The presence of a 'Location' header implies that the
            # exception must have been triggered by a HTTP redirection 
            # status code (3xx). 
            # $_.Exception.Response.StatusCode contains the specific code
            # (as an enumeration value that can be case to [int]), if needed.
            # !! Syntax `.Headers.Location` does NOT work.
            $nextUrlStr = try { $_.Exception.Response.Headers['Location'] } catch {}
            # Not being able to get a target URL implies that an unexpected
            # error ocurred: re-throw it.
            if (-not $nextUrlStr) { Throw }
          }
          Write-Verbose "Raw target: $nextUrlStr"
          if ($nextUrlStr -match '^https?:') { # absolute URL
            $nextUrl = $prevUrl = [Uri] $nextUrlStr
          } 
          else { # URL without scheme and server component
            $nextUrl = $prevUrl = [Uri] ($prevUrl.Scheme + '://' + $prevUrl.Authority + $nextUrlStr)
          }
          if ($i -le $MaxRedirections) { $urls += $nextUrl.AbsoluteUri }          
        }
        # Output the array of URLs (chain of redirections) as a *single* object.
        Write-Output -NoEnumerate $urls
        if (-not $ultimateFound) { 
          Write-Warning "Enumeration of $Url redirections ended before reaching the ultimate target." 
        }
      } 
      else { 
        # Resolve just to the ultimate target,
        # assuming the max. count of redirects is not exceeded.
        # Note that .AllowAutoRedirect defaults to $True.
        # This will fail, if there are more redirections than the specified 
        # or default maximum.
        $request = [System.Net.HttpWebRequest]::Create($Url)
        if ($PSBoundParameters.ContainsKey('MaxRedirections')) {
          $request.MaximumAutomaticRedirections = $MaxRedirections
        }
        $response = $request.GetResponse()
        # Output the ultimate target URL.
        # If no redirection was involved, this is the same as the input URL.
        $response.ResponseUri.AbsoluteUri
        $response.Close()
      }
    } 
    catch {
      Write-Error $_ # Report the exception as a non-terminating error.
    }
  } # process  
}