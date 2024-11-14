# Every container app needs an environment to run in
resource "azurerm_container_app_environment" "env" {
  name                = "secure-app-env"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
