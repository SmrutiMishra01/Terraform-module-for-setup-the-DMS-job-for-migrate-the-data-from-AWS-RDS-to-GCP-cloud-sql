output "migration_job_name" {
  value = google_database_migration_service_migration_job.migration.name
}

output "migration_job_id" {
  value = google_database_migration_service_migration_job.migration.id
}
