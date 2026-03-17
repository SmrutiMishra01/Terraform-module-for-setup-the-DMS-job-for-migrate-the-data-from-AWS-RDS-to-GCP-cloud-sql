variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "db_password" {
  description = "Database password (used for both RDS and Cloud SQL)"
  type        = string
  sensitive   = true
}

variable "migration_type" {
  description = "Migration scenario: 'new' or 'existing' Cloud SQL instance"
  type        = string
  default     = "new"
  validation {
    condition     = contains(["new", "existing"], var.migration_type)
    error_message = "migration_type must be either 'new' or 'existing'."
  }
}

variable "existing_cloudsql_instance_name" {
  description = "Name of the existing Cloud SQL instance (required if migration_type is 'existing')"
  type        = string
  default     = ""
}
