# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-commercial-trainning"
#     storage_account_name = "sttfstatetraining"
#     container_name       = "tfstate"
#     key                  = "training.tfstate"
#     use_azuread_auth     = true
#   }
# }
