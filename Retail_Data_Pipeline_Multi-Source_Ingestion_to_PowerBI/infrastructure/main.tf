provider "azurerm" {
  features {}
}

# Adjusted: Using api4.ipify.org to FORCE an IPv4 address.
# This prevents the "FirewallRuleNotIPv4Address" error on IPv6 enabled networks.
data "http" "my_public_ip" {
  url = "https://api4.ipify.org"
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Azure SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = var.server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  public_network_access_enabled = true
}

# 3. Azure SQL Database (Basic + Sample Data)
resource "azurerm_mssql_database" "sql_db" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = "Basic" 
  sample_name    = "AdventureWorksLT"
  
  # Adjusted: Set to "Local" to satisfy Terraform's requirement for LRS
  storage_account_type = "Local"

  tags = {
    environment = var.workload_env
  }
}

# 4. Networking: Allow Azure Services
# (Internal Azure backbone connectivity for ADF/Databricks)
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# 5. Networking: Add Current Client IP
# (External connectivity for your local machine)
resource "azurerm_mssql_firewall_rule" "client_ip" {
  name             = "ClientIPAddress"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = chomp(data.http.my_public_ip.response_body)
  end_ip_address   = chomp(data.http.my_public_ip.response_body)
}

# 6. Security: Microsoft Defender
resource "azurerm_mssql_server_security_alert_policy" "defender" {
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mssql_server.sql_server.name
  state               = "Enabled"
}
