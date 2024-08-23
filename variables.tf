variable "plt_postgres_db_adm_secret_name" {
  description = "The name of the PostgreSQL server admin user secret name. The vaule will be fetched from KV secret data block."
  type        = string
}

variable "plt_postgres_key_vault_id_primary_zone" {
  description = "The id of the PostgreSQL server primary key vault."
  type        = string
}
/*
variable "plt_postgres_private_end_point_subnet_id" {
  description = "The private endpoint subnet id for postgres sql."
  type        = string
}*/

variable "plt_postgres_cmk_key_id_primary_zone" {
  description = "The primary key vault key id for cmk encryption on postgres."
  type        = string
}

variable "plt_postgres_cmk_key_id_secondary_zone" {
  description = "The secondary key vault key id for cmk encryption on postgres."
  type        = string
  default = null
}

variable "plt_postgres_geo_backup_user_assigned_identity_id" {
  description = "The secodary User Assigned Identity id for cmk encryption on postgres."
  type        = string
  default = null
}

variable "plt_resource_group_name" {
  description = "The name of the resource group in which to create the PostgreSQL server."
  type        = string
  default = ""
}

variable "plt_location" {
  description = "The Azure region where the resources will be created."
  type        = string
  default     = "Southeast Asia"
}

variable "plt_tenant_id" {
  description = "The Tenant ID for the Entra Admin user ids."
  type        = string
  default = ""
}

variable "server_name" {
  description = "The name of the PostgreSQL flexible server."
  type        = string
}

variable "administrator_login" {
  description = "The administrator login user name for the PostgreSQL flexible server."
  type        = string
  default = "psqladmin"
}

variable "postgresql_version" {
  description = "The version of PostgreSQL to use."
  type        = string
  default     = "16"
}

variable "storage_mb" {
  description = "The storage capacity of the server in megabytes."
  type        = number
  default     = 32768
}

variable "sku_name" {
  description = "The SKU name for the PostgreSQL Flexible Server. Format: {PricingTier}_{ComputeType}_{vCores}. Example: GP_Gen5_4"
  type        = string
  default     = "GP_Standard_D2s_v3" # Set your desired default value

  validation {
    condition = contains([
      # General Purpose (GP) series
      "GP_Standard_D2s_v3", "GP_Standard_D4s_v3", "GP_Standard_D8s_v3", "GP_Standard_D16s_v3",
      "GP_Standard_D32s_v3", "GP_Standard_D64s_v3", "GP_Standard_D64s_v3", "GP_Standard_D96s_v3",
      
      # Memory Optimized (MO) series
      "MO_Standard_E2s_v3", "MO_Standard_E4s_v3", "MO_Standard_E8s_v3", "MO_Standard_E16s_v3",
      "MO_Standard_E32s_v3", "MO_Standard_E64s_v3", "MO_Standard_E64s_v3", "MO_Standard_E96s_v3",
      
      # Burstable (B) series
      "B_Standard_B1ms", "B_Standard_B2ms", "B_Standard_B4ms", "B_Standard_B8ms",
      "B_Standard_B1ls", "B_Standard_B2ls", "B_Standard_B4ls", "B_Standard_B8ls" 
    ], var.sku_name)
    error_message = "Invalid sku_name. Must be one of the following: GP_Standard_D2s_v3, GP_Standard_D4s_v3, GP_Standard_D8s_v3, GP_Standard_D16s_v3, GP_Standard_D32s_v3, GP_Standard_D64s_v3, GP_Standard_D96s_v3, MO_Standard_E2s_v3, MO_Standard_E4s_v3, MO_Standard_E8s_v3, MO_Standard_E16s_v3, MO_Standard_E32s_v3, MO_Standard_E64s_v3, MO_Standard_E96s_v3, B_Standard_B1ms, B_Standard_B2ms, B_Standard_B4ms, B_Standard_B8ms, B_Standard_B1ls, B_Standard_B2ls, B_Standard_B4ls, B_Standard_B8ls."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "The environment type: 'production' or 'non-production'"
  type        = string
  default     = "non-production"
}

variable "geo_redundant_backup_enabled" {
  type        = bool
  description = "Enable Geo-Redundant Backup (true or false)."
  default = false
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain backups (7 or 35)."
  default = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "The soft_delete_retention_days value must be between 7 and 35."
  }
}

variable "day_of_week" {
    type = number
    description = "weekdays"
    default = 0 # Sunday
} 
     
variable "start_hour" {
    type = number
    description ="starting hour"
    default = 2 # 2 AM
}

variable "start_minute" {
    type = number
    description = "starting minute"
    default = 0 # 00 minutes
}


variable "plt_postgres_delegated_subnet_id" {
  type        = string
  description = "The subnet ID where the PostgreSQL server will be delegated."
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access (true or false)."
  default = false
}

variable "high_availability_mode" {
  type = string
  description = "High availability mode for the PostgreSQL Flexible Server."
  default = "SameZone"
}

variable "point_in_time_restore_time_in_utc" {
  description = "The point-in-time restore time in UTC."
  type        = string
  default     = null
}

variable "source_server_id" {
  description = "The ID of the source server for restore operations."
  type        = string
  default     = null
}

variable "auto_grow_enabled" {
  description = "Whether auto-grow is enabled for the PostgreSQL Flexible Server."
  type        = bool
  default     = false
}

variable "plt_virtual_network_name" {
  description = "The name of the virtual network."
  type        = string
}

variable "plt_virtual_network_id" {
  description = "The ID of the virtual network to link with the Private DNS Zone."
  type        = string
}

variable "private_dns_zone_name" {
  description = "The name of the private DNS zone."
  type        = string
  default     = "privatelink.postgres.database.azure.com"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default = 7
}

variable "log_checkpoints" {
  description = "Enables or disables logging of checkpoints in PostgreSQL."
  type        = string
  default     = "on"  # Set default to "on" to enable logging of checkpoints
}

variable "connection_throttling" {
  description = "Enables or disables connection throttling in PostgreSQL."
  type        = string
  default     = "on"  # Set default to "on" to enable connection throttling
}
