resource "azurerm_container_app_environment" "this" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Consumption-only workload profile gives serverless scale-to-zero
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }


  tags = var.tags
}
