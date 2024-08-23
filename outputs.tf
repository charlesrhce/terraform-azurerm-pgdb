  output "postgresql_flexible_server_id" {
    description = "The ID of the PostgreSQL flexible server."
    value       = azurerm_postgresql_flexible_server.postgresql_flexible_server.id
  }

  output "postgresql_flexible_server_fqdn" {
    description = "The fully qualified domain name of the PostgreSQL flexible server."
    value       = azurerm_postgresql_flexible_server.postgresql_flexible_server.fqdn
  }
  /*
  output "private_endpoint_id" {
    value = azurerm_private_endpoint.postgresql_flexible_server_private_endpoint.*.id
  }*/

  output "umi_id" {
    description = "The ID of the User-Assigned Managed Identity."
    value       = azurerm_user_assigned_identity.umi.id
  }

  output "umi_principal_id" {
    description = "The Principal ID of the User-Assigned Managed Identity."
    value       = azurerm_user_assigned_identity.umi.principal_id
  }

  output "psql_flexible_server_configuration" {
    description = "The configuration of the PostgreSQL server"
    value       = {
      log_checkpoints     = azurerm_postgresql_flexible_server_configuration.log_checkpoints.value,
      connection_throttle_enable = azurerm_postgresql_flexible_server_configuration.connection_throttle_enable.value,
      log_retention_days  = azurerm_postgresql_flexible_server_configuration.log_retention_days.value
    }
  }

  # Output the Key Vault Key ID
  output "key_vault_key_id" {
    description = "The ID of the Key Vault Key used for encryption."
    value       = azurerm_key_vault_key.key_vault_key.id
  }

  # Output the Key Vault Key Name
  output "key_vault_key_name" {
    description = "The name of the Key Vault Key."
    value       = azurerm_key_vault_key.key_vault_key.name
  }

