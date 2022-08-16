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

  template_body = file("azuredeploy.json")

  parameters = {
    "domain" = "arodomain004"
    "clusterName" = "oa-aro-poc-004"
    "pullSecret" = ""
    "aadClientId" = "941382f5-be9d-42a4-b1e2-b9eb152f1e05"
    "aadObjectId" = "7ac88d5a-36aa-4af0-bf4f-2f34e5754cce"
    "aadClientSecret" = "2X9go9BAYryazU~qtyx5DByh0PKZB7_o7_"
    "rpObjectId" = "50c17c64-bc11-4fdd-a339-0ecd396bf911"
  }

  deployment_mode = "Incremental"
}