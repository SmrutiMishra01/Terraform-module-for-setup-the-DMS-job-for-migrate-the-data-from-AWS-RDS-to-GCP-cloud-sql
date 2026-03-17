output "instance_name" {
  value = data.google_sql_database_instance.existing.name
}

output "instance_ip_address" {
  value       = data.google_sql_database_instance.existing.private_ip_address
  description = "The IPv4 address assigned for the existing master instance."
}

output "instance_connection_name" {
  value = data.google_sql_database_instance.existing.connection_name
}
