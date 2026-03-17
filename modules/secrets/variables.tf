variable "secret_id" {
  description = "The ID of the secret to create"
  type        = string
  default     = "db-password"
}

variable "secret_data" {
  description = "The secret data (e.g. database password)"
  type        = string
  sensitive   = true
}
