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
  catch [Net.WebException] {
    [int]$PSItem.Exception.Response.StatusCode
  }
}