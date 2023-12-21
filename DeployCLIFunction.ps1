param (
    [string] $VAULTGROUP = "myResourceGroup",
    [string] $FUNCTION = "myfunctionapp",
    [string] $runtime = "dotnet",  # Specify the .NET runtime
    [string] $zipFilePath = ".\func.zip"  # Path to your local ZIP file
)

# Create a new resource group
az group create --name $resourceGroupName --location eastus

# Create an Azure Function App
az functionapp create --resource-group $resourceGroupName --name $functionAppName --consumption-plan-location eastus --runtime $runtime

# Deploy your Azure Function code from the local ZIP file
az functionapp deployment source config-zip --src $zipFilePath --name $functionAppName --resource-group $resourceGroupName
