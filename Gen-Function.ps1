param (
    [string] $VAULTGROUP,
    [string] $VAULTNAME,
    [string] $FUNCTION,
    [string] $AZREGION,
    [string] $zipFilePath = ".\func.zip"  # Path to your local ZIP file
)


$resourceGroupName = $VAULTGROUP
$functionAppName = $FUNCTION
$location = $AZREGION
$keyVault = $VAULTNAME

$ip = Invoke-RestMethod -Uri http://icanhazip.com
$ipAddress = $ip.Trim() + "/32"

# $resourceGroupName = "testersonlives2"
# $functionAppName = "testersonlives2"
# $location = "eastus"
# $keyVault = "gitrdonex666x"

# Define your project folder and new project folder
$originalFolder = "..\..\func"
$newFolder = "..\..\funcadelic"

# Create the new folder
New-Item -ItemType Directory -Path $newFolder -Force

# Move the .csproj and .cs files to the new folder
Copy-Item "$originalFolder\func.csproj" -Destination $newFolder -Force
Copy-Item "$originalFolder\gitrdone.cs" -Destination $newFolder -Force

# # Initialize a new Azure Functions project in the new folder
# az func init $newFolder --worker-runtime dotnet

# Change directory to the new folder
Set-Location -Path $newFolder

# Initialize a new Azure Functions project in the new folder
func init . --worker-runtime dotnet --force
Remove-Item .\funcadelic.csproj

# Add references to Azure Identity and Azure Key Vault
# dotnet add package Azure.Identity --version 1.7.1
# dotnet add package Azure.Security.KeyVault.Secrets --version 4.3.0

# Build and publish your Azure Functions project
dotnet publish --output .\bin\Debug\net6.0\publish

# Zip the publish directory
Compress-Archive -Path .\bin\Debug\net6.0\publish\* -DestinationPath func.zip -Force

# Create a new resource group
az group create --name $resourceGroupName --location $location

# Create a storage account with the same name as the resource group
az storage account create --name $resourceGroupName --resource-group $resourceGroupName --location $location --sku Standard_LRS

# Create an Azure Function App
Write-Output "Creating the function app"
az functionapp create --resource-group $resourceGroupName --name $functionAppName --storage-account $resourceGroupName --consumption-plan-location eastus --functions-version 4 --runtime "DOTNET-ISOLATED"  

Write-Output "Env vars"
az functionapp config appsettings set  --resource-group $resourceGroupName --name $functionAppName --settings KeyVaultUrl="https://$keyVault.vault.azure.net/"

Write-Output "Managed Id"
az functionapp identity assign --name $functionAppName --resource-group $resourceGroupName

# Retrieve the managed identity's object ID and store it in a variable
$managed_identity_object_id = az functionapp identity show --name $functionAppName --resource-group $resourceGroupName --query principalId --output tsv

Write-Output "ID Perms"
# Assign permissions to the managed identity on the Key Vault
az keyvault set-policy --name $keyVault --object-id $managed_identity_object_id --secret-permissions get list

Write-Output "Access rule"
# Set an access rule to allow access to the Azure Function from a specific IP address
az functionapp config access-restriction add --name $functionAppName --resource-group $resourceGroupName --rule-name allowip --action Allow --priority 150 --ip-address $ipAddress

Write-Output "Depoying"
# Deploy your Azure Functions project from the zip file
az functionapp deployment source config-zip --src func.zip --name $functionAppName --resource-group $resourceGroupName

