param(
    # Define all parameters that might be used
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKET,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETKEY,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETREGION,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETENDPOINT,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$AZREGION,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$AZENV,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$VAULTNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$VAULTGROUP,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAINNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAINSUFFIX,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$FUNCTION,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$genKeyVault,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$az,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$zipFilePath,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$tf,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$approve,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$reconfigure,
    
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$migrate,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$forceCopy,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [bool]$s3enabled = $true

)

# Define a helper function to run each script
function Run-ScriptWithParams {
    param($ScriptPath, $Params)
    & $ScriptPath @Params
}

# Prepare parameter sets for each script
$ParamsKeyVault = @{
    VAULTNAME = $VAULTNAME
    VAULTGROUP = $VAULTGROUP

}

$ParamsGitRDone = @{
    BUCKET = $BUCKET
    BUCKETKEY = $BUCKETKEY
    BUCKETREGION = $BUCKETREGION
    BUCKETENDPOINT = $BUCKETENDPOINT
    DOMAINNAME = $DOMAINNAME
    DOMAINSUFFIX = $DOMAINSUFFIX
    FUNCTION = $FUNCTION
    AZREGION = $AZREGION
    AZENV = $AZENV
    VAULTNAME = $VAULTNAME
    VAULTGROUP = $VAULTGROUP
}

# Check and create .\Deploy directory if it doesn't exist
$deployPath = ".\Deploy"
if(Test-Path $deployPath) { Remove-Item $deployPath -Recurse -Force}
# Remove-Item $deployPath\* -Recurse -Force

if (-not (Test-Path -Path $deployPath)) {
    New-Item -ItemType Directory -Path $deployPath -Force
}

if ($genKeyVault)
{ Run-ScriptWithParams ".\Gen-KeyVault.ps1" $ParamsKeyVault }

# Generate templated project
Run-ScriptWithParams ".\Gen-GitRDone.ps1" $ParamsGitRDone

# Remove backend.tf if we don't want to use s3, will prevent init from picking it up
if (!($s3enabled))
{
    Remove-Item .\Deploy\template\backend.tf -Force
}

# Change directory to .\Deploy and run terraform init
Set-Location -Path .\Deploy\template


# if terraform, if s3enabled, if type of init, if auto-approve
if ($tf) {
    if ($s3enabled) {
        $AWS_ACCESS_KEY_ID = Read-Host "Enter DigitalOcean S3 Key ID" -AsSecureString
        $AWS_SECRET_ACCESS_KEY = Read-Host "Enter DigitalOcean S3 Secret Access Key" -AsSecureString

        # Convert SecureString to Plain Text (for temporary use)
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AWS_ACCESS_KEY_ID)
        $PlainAWS_ACCESS_KEY_ID = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AWS_SECRET_ACCESS_KEY)
        $PlainAWS_SECRET_ACCESS_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        # Configure AWS CLI
        aws configure set aws_access_key_id $PlainAWS_ACCESS_KEY_ID --profile digitalocean
        aws configure set aws_secret_access_key $PlainAWS_SECRET_ACCESS_KEY --profile digitalocean
        aws configure set default.region us-east-1 --profile digitalocean

        $env:AWS_PROFILE = "digitalocean"

        if ($reconfigure) {
            terraform init -reconfigure
        }
        if ($migrate) {
            terraform init -migrate-state
        }
        if ($forceCopy) {
            terraform init -force-copy
        }

        terraform plan

        if ($approve) {
            terraform apply --auto-approve
        } else {
            terraform apply
        }
    }
}
if($az){
    $params = @{
    VAULTNAME = $VAULTNAME
    VAULTGROUP = $VAULTGROUP
    FUNCTION = $FUNCTION 
    AZREGION = $AZREGION
    zipFilePath = ".\func.zip" # relative to 
    }
    # Set-Location ..\..\
    ..\..\Gen-Function.ps1 @params
}



# $ParamsGitRDone = @{
#     BUCKET = $BUCKET
#     BUCKETKEY = $BUCKETKEY
#     BUCKETREGION = $BUCKETREGION
#     BUCKETENDPOINT = $BUCKETENDPOINT
#     DOMAINNAME = $DOMAINNAME
#     DOMAINSUFFIX = $DOMAINSUFFIX
#     FUNCTION = $FUNCTION
#     AZREGION = $AZREGION
#     AZENV = $AZENV
#     VAULTNAME = $VAULTNAME
#     VAULTGROUP = $VAULTGROUP
# }
# .\Deploy.ps1
