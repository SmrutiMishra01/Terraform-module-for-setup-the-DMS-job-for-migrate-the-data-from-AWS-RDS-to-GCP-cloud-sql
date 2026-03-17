aws_region     = "ap-south-1"
gcp_region     = "asia-south1"
gcp_project_id = "internal-sandbox-446612"

# RDS admin (master user) password
db_password = "SuperSecretPassword123!"

# DMS replication user password - used for 'dmsuser'@'%' on RDS
# This user must be created manually after apply (see README for SQL commands)
dms_user_password = "DmsRepl!cati0n#2024"

migration_type = "new"
vpc_cidr      = "10.10.0.0/16"
subnet_cidr_a = "10.10.1.0/24"
subnet_cidr_b = "10.10.2.0/24"