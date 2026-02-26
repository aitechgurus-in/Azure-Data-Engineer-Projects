# infrastructure/main.tf

provider "azurerm" {
  features {}
}

# 1. Generate a random suffix to ensure global uniqueness
resource "random_id" "unique_suffix" {
  byte_length = 4
}

locals {
  # Names must be lowercase and alphanumeric for storage
  unique_string = "${var.project_name}${var.environment}${random_id.unique_suffix.hex}"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

# 2. ADLS Gen2 Storage (Using unique suffix)
resource "azurerm_storage_account" "st" {
  name                     = substr("st${local.unique_string}", 0, 24)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "layers" {
  for_each           = toset(["bronze", "silver", "gold", "external-source"])
  name               = each.key
  storage_account_id = azurerm_storage_account.st.id
}

# 3. SQL Server (Using unique suffix to avoid name conflicts)
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-src-${local.unique_string}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "db" {
  name      = "sqldb-metadata"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = var.sql_sku
  
  auto_pause_delay_in_minutes = 60
  min_capacity                = 0.5
}

# 4. Databricks
resource "azurerm_databricks_workspace" "dbx" {
  name                = "dbx-${var.project_name}-${var.environment}-${random_id.unique_suffix.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
}

# 5. Azure AI Language Service
resource "azurerm_cognitive_account" "language_svc" {
  name                = "aisvc-${local.unique_string}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "TextAnalytics" 
  sku_name            = "S" 
}

# --- OUTPUTS (Crucial for your notebooks) ---
output "storage_account_name" {
  value = azurerm_storage_account.st.name
}

output "ai_endpoint" {
  value = azurerm_cognitive_account.language_svc.endpoint
}

output "ai_primary_key" {
  value     = azurerm_cognitive_account.language_svc.primary_access_key
  sensitive = true
}
