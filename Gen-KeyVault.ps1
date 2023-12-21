param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$VAULTGROUP,

    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$VAULTNAME
)

$group = "$VAULTGROUP"
$vault = "$VAULTNAME"
$ip = Invoke-RestMethod -Uri http://icanhazip.com
$ipAddress = $ip.Trim() + "/32"

# Define secret names
$secretNames = @("namecheap-user-name", "namecheap-api-user", "namecheap-api-key", "namecheap-client-ip", "dllToken", "dllRepo", "ghUsername", "auxToken", "auxRepo", "publicRepo")

# Read each secret and store as a secure string
$secrets = @{}
foreach ($name in $secretNames) {
    $secureString = Read-Host "Enter value for $name" -AsSecureString
    $secrets[$name] = $secureString
}

# Create resource group and keyvault, network rule for your IP only
az group create --name $group --location eastus
az keyvault create --name $vault --resource-group $group --location eastus 
$access = az keyvault network-rule add --name $vault --resource-group $group --ip-address $ipAddress

# Add each secret to the key vault
foreach ($secretName in $secretNames) {
    $secureString = $secrets[$secretName]
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    $secretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    Write-Output "Adding $secretName to key vault"
    $scrt =  az keyvault secret set --vault-name $vault --name $secretName --value $secretValue

    # Clear converted plain text secret from memory
    Remove-Variable -Name secretValue
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}
