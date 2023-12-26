terraform {
  required_providers {
        namecheap = {
      source = "namecheap/namecheap"
      version = "2.1.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      # Root module should specify the maximum provider version
      # The ~> operator is a convenient shorthand for allowing only patch releases within a specific minor release.
      version = "~> 2.26"
    }
  }
}

provider "namecheap" {
  user_name   = data.azurerm_key_vault_secret.namecheap_user_name.value
  api_user    = data.azurerm_key_vault_secret.namecheap_api_user.value
  api_key     = data.azurerm_key_vault_secret.namecheap_api_key.value
  client_ip   = data.azurerm_key_vault_secret.namecheap_client_ip.value
  use_sandbox = false
}

data "azurerm_key_vault" "existing" {
  name                = "<<<VAULTNAME>>>"
  resource_group_name = "<<<VAULTGROUP>>>"  # Replace with your resource group name
}

data "azurerm_key_vault_secret" "namecheap_user_name" {
  name         = "namecheap-user-name"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "namecheap_client_ip" {
  name         = "namecheap-client-ip"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "namecheap_api_user" {
  name         = "namecheap-api-user"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "namecheap_api_key" {
  name         = "namecheap-api-key"
  key_vault_id = data.azurerm_key_vault.existing.id
}

# provider "azurerm" {
#   features {}
# }

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy = true
      recover_soft_deleted_keys          = true
    }
  }
}

resource "azurerm_resource_group" "resource_group" {
  name = "${var.project}-${var.environment}-resource-group"
  location = var.location
}

resource "azurerm_storage_account" "storage_account" {
  name = "${var.project}${var.environment}storage"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = var.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_application_insights" "application_insights" {
  name                = "${var.project}-${var.environment}-application-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  application_type    = "ASP.NET"
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.project}-${var.environment}-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  kind                = "FunctionApp"
  reserved = true
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

data "archive_file" "file_function_app" {
  type        = "zip"
  source_dir  = "../func"
  output_path = "func.zip"
}




resource "azurerm_function_app" "function_app" {
  name                       = "${var.project}-${var.environment}-function-app"
  resource_group_name        = azurerm_resource_group.resource_group.name
  location                   = var.location
  app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id

 

  app_settings = {
    "KeyVaultUrl"       = "https://<<VAULTNAME>>>.vault.azure.net/",
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.application_insights.instrumentation_key,
  }
  os_type = "linux"
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  version                    = "~3"



  lifecycle {
    ignore_changes = [
      app_settings["KeyVaultUrl"],
    ]
  }
}
