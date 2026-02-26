provider "azurerm" { features {} }

locals {
  name_suffix = "nextgen-dev"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_suffix}"
  location = "East US"
}

# --- STORAGE (ADLS Gen2) ---
resource "azurerm_storage_account" "st" {
  name                     = "st${replace(local.name_suffix, "-", "")}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "layers" {
  for_each           = toset(["bronze", "silver", "gold", "external-source"])
  name               = each.key
  storage_account_id = azurerm_storage_account.st.id
}

# --- SOURCE SQL DATABASE (Serverless) ---
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-src-${local.name_suffix}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "Password1234!" 
}

resource "azurerm_mssql_database" "db" {
  name      = "sqldb-metadata"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "GP_S_Gen5_1" # Serverless Tier
  min_capacity = 0.5
  auto_pause_delay_in_minutes = 60
}

# --- DATABRICKS & OPENAI ---
resource "azurerm_databricks_workspace" "dbx" {
  name                = "dbx-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
}

resource "azurerm_cognitive_account" "openai" {
  name                = "oai-${local.name_suffix}"
  location            = "East US"
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = "S0"
}

resource "azurerm_cognitive_deployment" "gpt" {
  name                 = "gpt-4o-mini"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  model {
    format = "OpenAI"
    name   = "gpt-4o-mini"
    version = "2024-07-18"
  }
  sku { name = "Standard"; capacity = 10 }
}
