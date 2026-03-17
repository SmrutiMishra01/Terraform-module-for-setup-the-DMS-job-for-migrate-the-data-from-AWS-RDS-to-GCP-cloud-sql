variable "network_name" {
  description = "Name for the GCP VPC"
  type        = string
  default     = "dms-migration-vpc"
}

variable "subnet_name" {
  description = "Name for the GCP subnetwork"
  type        = string
  default     = "dms-migration-subnet"
}

variable "subnet_cidr" {
  description = "CIDR block for the GCP subnet"
  type        = string
  default     = "10.20.0.0/24"
}

variable "region" {
  description = "GCP region"
  type        = string
}
