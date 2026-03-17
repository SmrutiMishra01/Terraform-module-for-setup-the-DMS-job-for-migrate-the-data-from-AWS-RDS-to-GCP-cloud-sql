output "instance_name" {
  value       = google_sql_database_instance.main.name
  description = "Name of the Cloud SQL instance"
}

output "instance_connection_name" {
  value       = google_sql_database_instance.main.connection_name
  description = "Connection name of the form project:region:instance - used by Cloud SQL proxy and DMS"
}

output "private_ip_address" {
  value       = google_sql_database_instance.main.private_ip_address
  description = "Private IP address of the Cloud SQL instance (within VPC)"
}

output "public_ip_address" {
  value       = google_sql_database_instance.main.public_ip_address
  description = "Public IP address of the Cloud SQL instance (used by DMS with static_ip_connectivity)"
}
