variable "project_name" {
  type    = string
  default = "nextgen"
}

variable "environment" {
  type        = string
  description = "The environment (dev or prod)"
}

variable "location" {
  type    = string
  default = "East US"
}

# Storage Configuration
variable "storage_replication" {
  type        = string
  description = "LRS for dev, GRS for prod"
}

# SQL Configuration
variable "sql_sku" {
  type        = string
  description = "SKU for SQL Database"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

# OpenAI Configuration
variable "openai_model_name" {
  type    = string
  default = "gpt-4o-mini"
}
