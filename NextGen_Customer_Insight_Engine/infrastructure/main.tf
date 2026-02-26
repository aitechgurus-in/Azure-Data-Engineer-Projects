# infrastructure/main.tf

provider "azurerm" {
  features {}
}

# 1. Generate a random suffix to ensure globally unique names for Storage and AI Services
resource "random_id" "unique_suffix" {
  byte_length = 4
}

locals {
  # Names must be lowercase and alphanumeric for storage
  unique_string = lower("${var.project_name}${var.environment}${random_id.unique_suffix.hex}")
}

# 2. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

# 3. ADLS Gen2 Storage Account
resource "azurerm_storage_account" "st" {
  name                     = substr("st${local.unique_string}", 0, 24)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication
  is_hns_enabled           = true # Essential for ADLS Gen2 / Databricks
}

# 4. Storage Containers (Medallion Layers + Landing Zone)
resource "azurerm_storage_data_lake_gen2_filesystem" "layers" {
  for_each           = toset(["bronze", "silver", "gold", "external-source"])
  name               = each.key
  storage_account_id = azurerm_storage_account.st.id
}

# 5. Azure Databricks Workspace
resource "azurerm_databricks_workspace" "dbx" {
  name                = "dbx-${var.project_name}-${var.environment}-${random_id.unique_suffix.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
}

# 6. Azure AI Language Service (Instant Access for Trial Accounts)
resource "azurerm_cognitive_account" "language_svc" {
  name                = "aisvc-${local.unique_string}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "TextAnalytics" 
  sku_name            = "S" 
}

# --- OUTPUTS ---
# These will be needed to configure your Databricks Notebooks

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
