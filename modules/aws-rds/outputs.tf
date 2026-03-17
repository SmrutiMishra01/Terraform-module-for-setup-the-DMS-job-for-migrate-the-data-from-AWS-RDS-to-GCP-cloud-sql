output "endpoint" {
  value       = aws_db_instance.source.endpoint
  description = "Full endpoint (host:port) of the RDS instance"
}

output "address" {
  value       = aws_db_instance.source.address
  description = "DNS hostname of the RDS instance"
}

output "port" {
  value       = aws_db_instance.source.port
  description = "Port the RDS instance is listening on"
}

output "username" {
  value       = aws_db_instance.source.username
  description = "Master username for the RDS instance"
}

output "dms_username" {
  value       = "dmsuser"
  description = "The dedicated DMS replication username. See the null_resource output for setup SQL."
}
