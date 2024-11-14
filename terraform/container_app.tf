resource "azurerm_container_app" "app" {
  name                         = "secure-app"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  # Required to access the app from the internet
  ingress {
    external_enabled = true
    target_port      = 8080

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    # Volume to share data between init and app containers 
    volume {
      name         = "www"
      storage_type = "EmptyDir"
    }

    # This container creates the index.html file with the secrets from the environment variables
    init_container {
      name   = "populate-www"
      image  = "busybox:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      args = [
        "sh",
        "-c",
        <<-HTML
          cat <<EOF > /app/index.html
          <!DOCTYPE html>
          <html>
          <body>
            <h1>Not at all Secret Value:</h1>
            <h1>$${NOT_SECRET_VALUE}</h1>
            <br>
            <h1>Somewhat Secret Value:</h1>
            <h1>$${BETTER_SECRET_VALUE}</h1>
            <br>
            <h1>Super Secret Value:</h1>
            <h1>$${SUPER_SECRET_VALUE}</h1>
          </body>
          </html>
          EOF
        HTML
      ]

      volume_mounts {
        name = "www"
        path = "/app"
      }

      env {
        name  = "NOT_SECRET_VALUE"
        value = "very unsafe"
      }

      env {
        name        = "BETTER_SECRET_VALUE"
        secret_name = "stored-secret-value"
      }

      env {
        name        = "SUPER_SECRET_VALUE"
        secret_name = "kv-secret-value"
      }
    }

    # This container serves the index.html file
    container {
      name   = "serve-www"
      image  = "bitnami/nginx:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      volume_mounts {
        name = "www"
        path = "/app"
      }
    }
  }

  # Secret stored in the container app itself
  secret {
    name  = "stored-secret-value"
    value = "this is not in the app code"
  }

  # Secret stored in Azure Key Vault
  # We use a user-assigned identity to avoid a chicken-and-egg problem
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  secret {
    name                = "kv-secret-value"
    identity            = azurerm_user_assigned_identity.app.id
    key_vault_secret_id = data.azurerm_key_vault_secret.app_secret.versionless_id
  }

  # Make sure the app can access the secrets in the Key Vault before starting
  depends_on = [azurerm_key_vault_access_policy.app]
}

# Output the URL of the app
output "fqdn" {
  value = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}
