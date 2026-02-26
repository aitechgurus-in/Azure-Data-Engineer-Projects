provider "azurerm" { features {} }

locals {
  name_suffix = "${var.project_name}-${var.environment}"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_suffix}"
  location = var.location
}

# ADLS Gen2 Storage
resource "azurerm_storage_account" "st" {
  name                     = "st${replace(local.name_suffix, "-", "")}"
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

# SQL Serverless Source
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-src-${local.name_suffix}"
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

# Databricks & OpenAI
resource "azurerm_databricks_workspace" "dbx" {
  name                = "dbx-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
}

resource "azurerm_cognitive_account" "openai" {
  name                = "oai-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = "S0"
}

resource "azurerm_cognitive_deployment" "gpt" {
  name                 = var.openai_model_name
  cognitive_account_id = azurerm_cognitive_account.openai.id
  model {
    format = "OpenAI"
    name   = var.openai_model_name
    version = "2024-07-18"
  }
  sku { name = "Standard"; capacity = 10 }
}
