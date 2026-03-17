output "secret_id" {
  value       = google_secret_manager_secret.default.secret_id
  description = "ID of the created Secret Manager secret"
}

output "secret_version_id" {
  value       = google_secret_manager_secret_version.default.id
  description = "ID of the specific version of the secret containing the DB password"
}
