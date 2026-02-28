variable "project_name" {
  type    = string
  default = "retail-project"
}

variable "environment" {
  type        = string
  description = "dev or prod"
}

variable "location" {
  type    = string
  default = "West US 2"
}

variable "sql_server_name" {
  type    = string
}

variable "database_name" {
  type    = string
}

variable "admin_username" {
  type    = string
  default = "adminuser"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sql_sku" {
  type        = string
  description = "Basic, GP_S_Gen5_1, etc."
}

variable "backup_redundancy" {
  type        = string
  description = "LRS, GRS, or ZRS"
}
