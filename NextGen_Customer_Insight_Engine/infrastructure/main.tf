provider "azurerm" {
  features {}
}

resource "random_id" "unique_suffix" {
  byte_length = 4
}

locals {
  unique_string = lower("${var.project_name}${var.environment}${random_id.unique_suffix.hex}")
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

# --- ADLS Gen2 Storage ---
resource "azurerm_storage_account" "st" {
  name                     = substr("st${local.unique_string}", 0, 24)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication
  is_hns_enabled           = true
  
  # FORCE Terraform to wait for the Resource Group to be ready
  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "layers" {
  for_each           = toset(["bronze", "silver", "gold", "external-source"])
  name               = each.key
  storage_account_id = azurerm_storage_account.st.id
}

# --- Databricks ---
resource "azurerm_databricks_workspace" "dbx" {
  name                = "dbx-${var.project_name}-${var.environment}-${random_id.unique_suffix.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
  
  depends_on = [azurerm_resource_group.rg]
}

# --- AI Language Service ---
resource "azurerm_cognitive_account" "language_svc" {
  name                = "aisvc-${local.unique_string}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "TextAnalytics" 
  sku_name            = "S" 
  
  depends_on = [azurerm_resource_group.rg]
}

output "storage_account_name" { value = azurerm_storage_account.st.name }
output "ai_endpoint" { value = azurerm_cognitive_account.language_svc.endpoint }
output "ai_primary_key" { value = azurerm_cognitive_account.language_svc.primary_access_key; sensitive = true }
