variable "subnet_id_a" {
  description = "Subnet ID in AZ-a for the RDS DB subnet group (must be in a different AZ from subnet_id_b)"
  type        = string
}

variable "subnet_id_b" {
  description = "Subnet ID in AZ-b for the RDS DB subnet group (AWS requires subnets in at least 2 AZs)"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID for RDS instance"
  type        = string
}

variable "db_password" {
  description = "Password for the RDS master (admin) user"
  type        = string
  sensitive   = true
}

variable "dms_user_password" {
  description = "Password for the dedicated DMS replication user ('dmsuser'). This user needs REPLICATION SLAVE, REPLICATION CLIENT, and SELECT privileges on the source RDS MySQL instance."
  type        = string
  sensitive   = true
  default     = "DmsRepl!cati0n#2024"
}
