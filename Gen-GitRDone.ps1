param(

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKET,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETKEY,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETREGION,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETENDPOINT,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAINNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAINSUFFIX,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$FUNCTION,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$AZREGION,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$AZENV,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$VAULTNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$VAULTGROUP
        
)

# Function to replace placeholders in a file
function Replace-PlaceholderInFile {
    param($filePath, $placeholder, $value)
    Write-Output "Replacing $placeholder with $value in $filePath"
    (Get-Content $filePath) -replace "<<<$placeholder>>>", $value | Set-Content $filePath
}

# Clean and Create Deploy directory
$deployPath = ".\Deploy"
if(Test-Path $deployPath) { Remove-Item $deployPath -Recurse -Force}
if (-not (Test-Path -Path $deployPath)) {
    New-Item -ItemType Directory -Path $deployPath -Force
}

# Copy the entire "template" folder to .\Deploy
$templateFolderPath = ".\template"
if (Test-Path $templateFolderPath) {
    $destinationFolderPath = Join-Path $deployPath "template"
    Copy-Item -Path $templateFolderPath -Destination $destinationFolderPath -Recurse -Force
}

# Replace placeholders in .cs files within the copied "template" folder
if (Test-Path $destinationFolderPath) {
    $terrafiles = Get-ChildItem -Path $destinationFolderPath -Filter "*.tf" -File
    foreach ($terrafile in $terrafiles) {
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "AZREGION" -value $AZREGION
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "FUNCTION" -value $FUNCTION
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "AZENV" -value $AZENV
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "VAULTNAME" -value $VAULTNAME
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "VAULTGROUP" -value $VAULTGROUP
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "BUCKET" -value $BUCKET 
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "BUCKETKEY" -value $BUCKETKEY 
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "BUCKETREGION" -value $BUCKETREGION 
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "BUCKETENDPOINT" -value $BUCKETENDPOINT
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "DOMAINNAME" -value $DOMAINNAME
        Replace-PlaceholderInFile -filePath $terrafile.FullName -placeholder "DOMAINSUFFIX" -value $DOMAINSUFFIX 
    }
} else {
    Write-Output "No template folder found"
}

# Replace placeholders in .tfvars files within the copied "template" folder
if (Test-Path $destinationFolderPath) {
    $tfvarsFiles = Get-ChildItem -Path $destinationFolderPath -Filter "*.tfvars" -File
    foreach ($tfvarsFile in $tfvarsFiles) {
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "AZREGION" -value $AZREGION
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "FUNCTION" -value $FUNCTION
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "AZENV" -value $AZENV
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "VAULTNAME" -value $VAULTNAME
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "VAULTGROUP" -value $VAULTGROUP
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "BUCKET" -value $BUCKET 
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "BUCKETKEY" -value $BUCKETKEY 
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "BUCKETREGION" -value $BUCKETREGION 
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "BUCKETENDPOINT" -value $BUCKETENDPOINT
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "DOMAINNAME" -value $DOMAINNAME
        Replace-PlaceholderInFile -filePath $tfvarsFile.FullName -placeholder "DOMAINSUFFIX" -value $DOMAINSUFFIX    
    }
} else {
    Write-Output "No template folder found"
}
