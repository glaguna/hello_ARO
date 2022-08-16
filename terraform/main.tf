terraform {
   required_providers {
    azurerm = "~> 2.11.0"
  }
  backend "remote" {
    # hostname     = "app.terraform.io"
    organization = "personal-mobile"
    workspaces {
      name = "arm-template"
    }
  }
}

provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x.
  # If you're using version 1.x, the "features" block is not allowed.
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.azure_rg
  location = "East US 2"
}

resource "azurerm_template_deployment" "terraform-arm" {
  name                = "terraform-arm-aro-004"
  resource_group_name = azurerm_resource_group.rg.name

  template_body = file("./arm/azuredeploy.json")

  parameters = {
    "storageAccountName" = "tfarmaropoc"
    "storageAccountType" = "Standard_LRS"

  }

  deployment_mode = "Incremental"
}