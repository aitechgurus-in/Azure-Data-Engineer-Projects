provider "azurerm" {
  features {}
}

# Adjusted: Using api4.ipify.org to FORCE an IPv4 address.
data "http" "my_public_ip" {
  url = "https://api4.ipify.org"
}

# Used to generate a unique suffix for Storage and ADF names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
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
  
  storage_account_type = "Local"

  tags = {
    environment = var.workload_env
  }
}

# 4. Networking: Allow Azure Services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# 5. Networking: Add Current Client IP
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

# 7. Storage Account (ADLS Gen2)
resource "azurerm_storage_account" "adls" {
  name                     = "pocstorage${random_string.suffix.result}" 
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true 

  tags = {
    environment = var.workload_env
  }
}

# 8. Data Lake Filesystem (Container: retail)
resource "azurerm_storage_data_lake_gen2_filesystem" "retail" {
  name               = "retail"
  storage_account_id = azurerm_storage_account.adls.id
}

# 9. Directories: Silver and Gold
resource "azurerm_storage_data_lake_gen2_path" "base_folders" {
  for_each           = toset(["silver", "gold"])
  path               = each.key
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.retail.name
  storage_account_id = azurerm_storage_account.adls.id
  resource           = "directory"
}

# 10. Directories: Bronze Subfolders
resource "azurerm_storage_data_lake_gen2_path" "bronze_subfolders" {
  for_each           = toset(["customer", "product", "store", "transaction"])
  path               = "bronze/${each.key}"
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.retail.name
  storage_account_id = azurerm_storage_account.adls.id
  resource           = "directory"
}

# =========================================================================
# NEW ADDITIONS: AZURE DATA FACTORY
# =========================================================================

# 11. Azure Data Factory
resource "azurerm_data_factory" "adf" {
  name                = "pocadf${random_string.suffix.result}" # Ensures uniqueness
  location            = "West US 2"                            # Explicitly requested region
  resource_group_name = azurerm_resource_group.rg.name

  # Enabling Managed Identity is best practice for connecting ADF to ADLS/SQL later
  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.workload_env
  }
}
