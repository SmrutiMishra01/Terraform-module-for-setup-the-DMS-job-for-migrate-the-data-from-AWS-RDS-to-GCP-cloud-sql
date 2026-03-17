variable "region" {
  description = "GCP region for DMS resources (e.g. asia-south1)"
  type        = string
}

# ---------------------
# Source (AWS RDS)
# ---------------------
variable "source_host" {
  description = "Public DNS hostname of the AWS RDS source instance"
  type        = string
}

variable "source_port" {
  description = "MySQL port on the source RDS instance"
  type        = number
  default     = 3306
}

variable "source_username" {
  description = "MySQL username for the DMS replication user on the source RDS (should be 'dmsuser' with REPLICATION SLAVE, REPLICATION CLIENT, SELECT privileges)"
  type        = string
  default     = "dmsuser"
}

variable "source_password" {
  description = "Password for the DMS replication user on the source RDS"
  type        = string
  sensitive   = true
}

# ---------------------
# Destination (Cloud SQL)
# ---------------------
variable "destination_cloudsql_id" {
  description = "Cloud SQL instance connection name or instance ID used by DMS (e.g. project:region:instance)"
  type        = string
}

variable "destination_username" {
  description = "MySQL username on the destination Cloud SQL instance (default: root)"
  type        = string
  default     = "root"
}

variable "destination_password" {
  description = "Password for the destination Cloud SQL user"
  type        = string
  sensitive   = true
}

# ---------------------
# Migration Job
# ---------------------
variable "job_name" {
  description = "Identifier for the DMS migration job (used as connection profile IDs + job ID)"
  type        = string
  default     = "rds-to-cloudsql"
}
