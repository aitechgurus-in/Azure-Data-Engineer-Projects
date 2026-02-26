variable "project_name" { default = "nextgen" }
variable "environment" {}
variable "location" { default = "East US" }
variable "storage_replication" { default = "LRS" }
variable "sql_sku" { default = "GP_S_Gen5_1" }
variable "sql_admin_password" { sensitive = true }
variable "openai_model_name" { default = "gpt-4o-mini" }
