provider "azurerm" {
  features {}
}

# 1. Resource Group (Unique per environment)
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

# 2. SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "${var.sql_server_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
}

# 3. SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = var.sql_sku
  storage_account_type = var.backup_redundancy

  tags = {
    environment = var.environment
    workload    = "Retail-POC"
  }
}

# 4. Firewall Rule (Allow Azure Services)
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
