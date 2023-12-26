## Key Vault and Redirector function
Reads in your secrets and deploys a function and key  vault linked with a manged identity. The redirector pulls base64 encoded text files from a chose repo using a github reader-only token. DLLs for graboid go in a repo routed by /assets/ and the aux/appdomain are handled by requests to /adm/. Will ask for a public repo, good place to store your global status file or need something for a ruse.

### Deploy with Azure CLI

```powershell
 # AzCLI Version, no s3
 $params = @{
    VAULTNAME = "testersonlives2"
    VAULTGROUP = "testersonlives2"
    FUNCTION = "testersonlives2"
    AZREGION = "eastus"
    zipFilePath = ".\func.zip" # leave it alone
    tf = $false
    s3enabled = $false 
    az = $true # if az, no tf, and vice versa
    genKeyVault = $true # change to false after you deploy to skip reading in secrets
}
.\Deploy.ps1 @params
```

### Attempt with Custom Domain Name added

```powershell
 # AzCLI Version, no s3
 $params = @{
    DNS = $true
    VAULTNAME = "testersonlives2"
    VAULTGROUP = "testersonlives2"
    FUNCTION = "testersonlives2"
    DOMAINNAME = "example"
    DOMAINSUFFIX = "com"
    AZREGION = "eastus"
    zipFilePath = ".\func.zip" # leave it alone
    tf = $false
    s3enabled = $false 
    az = $true # if az, no tf, and vice versa
    genKeyVault = $true # change to false after you deploy to skip reading in secrets
}
.\Deploy.ps1 @params
```



### Shout-outs
https://github.com/maximivanov/deploy-azure-functions-with-terraform
https://www.maxivanov.io/publish-azure-functions-code-with-terraform/
https://github.com/maximivanov/publish-az-func-code-with-terraform/blob/main/terraform-az-cli/main.tf