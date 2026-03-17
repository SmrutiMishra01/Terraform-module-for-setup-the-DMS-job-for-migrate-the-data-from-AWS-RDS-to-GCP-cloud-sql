variable "instance_name" {
  description = "Name for the Cloud SQL instance"
  type        = string
  default     = "dms-migration-dest"
}

variable "database_version" {
  description = "The MySQL version to use"
  type        = string
  default     = "MYSQL_8_0"
}

variable "region" {
  description = "The region of the Cloud SQL resource"
  type        = string
}

variable "tier" {
  description = "The machine type to use"
  type        = string
  default     = "db-f1-micro"
}

variable "network_id" {
  description = "The VPC network ID to which the instance is connected"
  type        = string
}

variable "db_password" {
  description = "Password for the root user"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "appdb"
}

variable "private_vpc_connection" {
  description = "Dependency to ensure VPC peering is complete prior to instantiation"
  type        = string
}
