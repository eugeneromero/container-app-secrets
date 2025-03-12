# We need the client configuration to get the tenant ID to put the KV in
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  # Name must be globally unique
  name                = "secure-app-kv-235q54"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

# Allow the current user to create secrets
resource "azurerm_key_vault_access_policy" "me" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete"
  ]
}

# We use a user-assigned identity to avoid a chicken-and-egg problem
resource "azurerm_user_assigned_identity" "app" {
  name                = "secrets-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Allow the app to get secrets from the key vault
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app.principal_id

  secret_permissions = ["Get"]
}

data "azurerm_key_vault_secret" "app_secret" {
  name         = "super-secret"
  key_vault_id = azurerm_key_vault.kv.id
}
