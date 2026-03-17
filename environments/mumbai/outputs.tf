output "aws_rds_endpoint" {
  value       = module.aws_rds.endpoint
  description = "The endpoint of the AWS RDS source instance."
}

output "cloudsql_instance_name" {
  value       = local.target_cloudsql_instance
  description = "The target Cloud SQL instance name in GCP."
}

output "migration_job_name" {
  value       = module.dms.migration_job_name
  description = "The generated DMS Migration Job name."
}

output "migration_instructions" {
  value = <<EOT
To start the migration, open your terminal and run the following command:

gcloud database-migration migration-jobs start rds-to-cloudsql --region asia-south1 --project ${var.gcp_project_id}
EOT
}
