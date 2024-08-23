#These are default left from Azure to choose depending upon the region.
#replication_role
#zone
#create_mode

data "azurerm_key_vault_secret" "postgres_admin_password" {
  name         = var.plt_postgres_db_adm_secret_name
  key_vault_id = var.plt_postgres_key_vault_id_primary_zone
}

 /* #create private dns zone rg
resource "azurerm_resource_group" "dns_rg" {
  name     = var.dns_rg_name
  location = var.plt_location

  tags = var.tags
}*/

#create postgresql private dns zone
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = var.private_dns_zone_name
  resource_group_name = var.plt_resource_group_name
}

#create postgressql vnet private link with postgresql private dns zone
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_virtual_network_link" {
  name                  = "${var.plt_virtual_network_name}-link"
  resource_group_name   = var.plt_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.plt_virtual_network_id
  registration_enabled = false
}
/*
#create private endpoint for postgresql when public connection is enabled and private endpoint is also enabled
resource "azurerm_private_endpoint" "postgresql_flexible_server_private_endpoint" {
  count = var.public_network_access_enabled == true ? 1 : 0
  name                = "${var.server_name}-private-endpoint"
  resource_group_name = var.plt_resource_group_name
  location            = var.plt_location
  subnet_id           = var.plt_postgres_private_end_point_subnet_id

  private_service_connection {
    name                           = "${var.server_name}-psc"
    private_connection_resource_id = azurerm_postgresql_flexible_server.postgresql_flexible_server.id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }

    private_dns_zone_group {
    name                 = "${var.server_name}-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone.id]
  }

  tags = var.tags

  depends_on = [azurerm_postgresql_flexible_server.postgresql_flexible_server]
}
*/
#code block for random string generation
provider "random" {
  # No specific configuration needed for the random provider
}

# Generate a random string to ensure uniqueness
resource "random_string" "unique_suffix" {
  length  = 8
  special = false
  upper   = false
  lower   = true
  numeric  = true
}

resource "azurerm_key_vault_key" "key_vault_key" {
  name         = "${var.server_name}-${random_string.unique_suffix.result}"
  key_vault_id = var.plt_postgres_key_vault_id_primary_zone
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

#create user managed identity for cmk encryption on postgresql
resource "azurerm_user_assigned_identity" "umi" {
     
    name = "${var.server_name}-${random_string.unique_suffix.result}"
    location = var.plt_location
    resource_group_name = var.plt_resource_group_name
}

#assign the user managed identity with appropriate roles on key vault to fetch and encrypt using key vault key
resource "azurerm_role_assignment" "umi_key_vault_crypto_service_encryption_user" { 
principal_id = azurerm_user_assigned_identity.umi.principal_id 
role_definition_name = "Key Vault Crypto Service Encryption User" 
scope  = azurerm_key_vault_key.key_vault_key.resource_id
#scope = var.plt_postgres_key_vault_id_primary_zone
depends_on = [
    azurerm_user_assigned_identity.umi, azurerm_key_vault_key.key_vault_key
    ]
}

resource "azurerm_postgresql_flexible_server_configuration" "log_checkpoints" {
  name      = "log_checkpoints"
  server_id = azurerm_postgresql_flexible_server.postgresql_flexible_server.id
  value     = var.log_checkpoints
  depends_on = [ 
    azurerm_postgresql_flexible_server.postgresql_flexible_server,
    azurerm_key_vault_key.key_vault_key,
    azurerm_role_assignment.umi_key_vault_crypto_service_encryption_user
  ]
}

resource "azurerm_postgresql_flexible_server_configuration" "connection_throttle_enable" {
  name      = "connection_throttle.enable"
  server_id =azurerm_postgresql_flexible_server.postgresql_flexible_server.id
  value     = var.connection_throttling
  depends_on = [ 
    azurerm_postgresql_flexible_server.postgresql_flexible_server,
    azurerm_key_vault_key.key_vault_key,
    azurerm_role_assignment.umi_key_vault_crypto_service_encryption_user
  ]
}

resource "azurerm_postgresql_flexible_server_configuration" "log_retention_days" {
  name      = "logfiles.retention_days"
  server_id = azurerm_postgresql_flexible_server.postgresql_flexible_server.id
  value     = var.log_retention_days
  depends_on = [ 
    azurerm_postgresql_flexible_server.postgresql_flexible_server,
    azurerm_key_vault_key.key_vault_key,
    azurerm_role_assignment.umi_key_vault_crypto_service_encryption_user
  ]
}

#create postgresql flexible server
resource "azurerm_postgresql_flexible_server" "postgresql_flexible_server" {
  name                = var.server_name
  resource_group_name = var.plt_resource_group_name
  location            = var.plt_location
  administrator_login = var.administrator_login
  administrator_password = data.azurerm_key_vault_secret.postgres_admin_password.value

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                 = var.plt_tenant_id
  }

  backup_retention_days = var.backup_retention_days

  customer_managed_key {
    #key_vault_key_id                   = var.plt_postgres_cmk_key_id_primary_zone
    key_vault_key_id                   = azurerm_key_vault_key.key_vault_key.id
    primary_user_assigned_identity_id  = azurerm_user_assigned_identity.umi.id
    geo_backup_key_vault_key_id = var.geo_redundant_backup_enabled ? var.plt_postgres_cmk_key_id_secondary_zone : null
    geo_backup_user_assigned_identity_id = var.geo_redundant_backup_enabled ? var.plt_postgres_geo_backup_user_assigned_identity_id : null
  }

  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  #only gets created with vnet integration.
  delegated_subnet_id = var.public_network_access_enabled == false ? var.plt_postgres_delegated_subnet_id : null

  #only gets created with vnet integration.
  private_dns_zone_id = var.public_network_access_enabled == false ? azurerm_private_dns_zone.private_dns_zone.id : null
  
  #only private access with vnet integration
  public_network_access_enabled = false

/*
  high_availability {
    mode            = var.sku_name == "Burstable" ? null : var.high_availability_mode
    zone_redundant  = var.sku_name == "Burstable" ? false : var.zone_redundant
  }*/

dynamic "high_availability" {
  for_each = startswith(var.sku_name, "B_") ? [] : [1]  # Exclude high availability for burstable SKUs
  content {
    mode = var.high_availability_mode
  }
}

  identity {
    type = "UserAssigned"
    #identity_ids = [azurerm_user_assigned_identity.umi.id, var.plt_postgres_geo_backup_user_assigned_identity_id] # Use this variable if specifying user-assigned identities
    identity_ids = [azurerm_user_assigned_identity.umi.id] # Use this variable if specifying user-assigned identities
  }

  maintenance_window {
    day_of_week = var.day_of_week
    start_hour = var.start_hour
    start_minute = var.start_minute
  }

  point_in_time_restore_time_in_utc = var.point_in_time_restore_time_in_utc
  sku_name            = var.sku_name  # Define sku_name as an attribute
  source_server_id    = var.source_server_id
  auto_grow_enabled   = var.auto_grow_enabled
  storage_mb          = var.storage_mb
  version             = var.postgresql_version
  tags = var.tags

  lifecycle {
    ignore_changes = [
        high_availability[0].standby_availability_zone,
        zone
    ]
  }
  
}
