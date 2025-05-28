terraform {
  backend "azurerm" {
    resource_group_name  = "rg1"
    storage_account_name = "rg1stg1backend"
    container_name       = "tfstate"
    key                  = "terraform.tfstate" #the tfstate file name
  }
}