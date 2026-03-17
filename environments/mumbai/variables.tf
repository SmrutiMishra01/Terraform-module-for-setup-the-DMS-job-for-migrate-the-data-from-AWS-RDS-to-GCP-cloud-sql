variable "aws_region" {
  description = "AWS region for source infrastructure (Mumbai)"
  type        = string
  default     = "ap-south-1"
}

variable "gcp_project_id" {
  description = "GCP Project ID where Cloud SQL and DMS resources will be deployed"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for destination infrastructure (Mumbai)"
  type        = string
  default     = "asia-south1"
}

variable "db_password" {
  description = "Password for the RDS master (admin) user and Cloud SQL root user"
  type        = string
  sensitive   = true
}

variable "dms_user_password" {
  description = <<-EOT
    Password for the dedicated DMS replication user ('dmsuser') on the AWS RDS source.
    This user must be created manually after apply with:
      CREATE USER 'dmsuser'@'%' IDENTIFIED BY '<this value>';
      GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'dmsuser'@'%';
      GRANT SELECT ON *.* TO 'dmsuser'@'%';
      FLUSH PRIVILEGES;
  EOT
  type        = string
  sensitive   = true
  default     = "DmsRepl!cati0n#2024"
}

variable "migration_type" {
  description = "Migration scenario: 'new' provisions a fresh Cloud SQL instance; 'existing' targets an existing one"
  type        = string
  default     = "new"

  validation {
    condition     = contains(["new", "existing"], var.migration_type)
    error_message = "migration_type must be either 'new' or 'existing'."
  }
}

variable "existing_cloudsql_instance_name" {
  description = "Name of the existing Cloud SQL instance (required only when migration_type = 'existing')"
  type        = string
  default     = ""
}
