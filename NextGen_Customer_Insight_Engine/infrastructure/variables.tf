variable "project_name" { 
  default = "nextgen" 
}

variable "environment" {
  type = string
}

variable "location" { 
  default = "eastus2" # Suggested to use eastus2 as it often has better trial availability
}

variable "storage_replication" { 
  default = "LRS" 
}
