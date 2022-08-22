terraform {
   required_providers {
    azurerm = "~> 2.11.0"
  }
  backend "remote" {
    # hostname     = "app.terraform.io"
    organization = "<your_terraform-cloud_org>"
    workspaces {
      name = "<your_terraform-cloud_workspace>"
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

  template_body = file("azuredeploy.json")

  parameters = {
    "domain" = "arodomain004"
    "clusterName" = "oa-aro-poc-004"
    "pullSecret" = ""
    "aadClientId" = "00000000-0000-0000-0000-000000000000"
    "aadObjectId" = "00000000-0000-0000-0000-000000000000"
    "aadClientSecret" = "00000000-0000-0000-0000-000000000000"
    "rpObjectId" = "00000000-0000-0000-0000-000000000000"
  }

  deployment_mode = "Incremental"
}