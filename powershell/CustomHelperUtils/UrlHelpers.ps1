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

# Source: https://powershellmagazine.com/2013/01/29/pstip-retrieve-a-redirected-url/
# Usage:
#	  PS C:\> Get-UrlRedirect -Url 'http://go.microsoft.com/fwlink/?LinkID=210601'
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