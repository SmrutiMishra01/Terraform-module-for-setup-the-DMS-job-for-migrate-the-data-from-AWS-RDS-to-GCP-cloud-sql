output "network_id" {
  value = google_compute_network.main.id
}

output "network_self_link" {
  value = google_compute_network.main.self_link
}

output "subnet_id" {
  value = google_compute_subnetwork.main.id
}

output "private_vpc_connection" {
  value       = google_service_networking_connection.private_vpc_connection.id
  description = "Dependency trigger to ensure peering is complete before Cloud SQL creation"
}
