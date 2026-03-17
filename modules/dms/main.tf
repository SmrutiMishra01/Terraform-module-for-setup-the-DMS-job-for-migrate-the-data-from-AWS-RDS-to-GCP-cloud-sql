# Source Connection Profile (AWS RDS)
resource "google_database_migration_service_connection_profile" "source" {
  provider              = google-beta
  location              = var.region
  connection_profile_id = "${var.job_name}-source"
  display_name          = "AWS RDS Source"
  
  mysql {
    host     = var.source_host
    port     = var.source_port
    username = var.source_username
    password = var.source_password
  }
}

# Destination Connection Profile (Cloud SQL)
resource "google_database_migration_service_connection_profile" "destination" {
  provider              = google-beta
  location              = var.region
  connection_profile_id = "${var.job_name}-dest"
  display_name          = "Cloud SQL Destination"

  mysql {
    host         = "10.20.0.10" # Placeholder IP, overridden by cloud_sql_id routing
    port         = 3306
    username     = "root"
    password     = var.destination_password
    cloud_sql_id = var.destination_cloudsql_id
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "dms_bucket" {
  name          = "dms-dump-bucket-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true
}

resource "google_database_migration_service_migration_job" "migration" {
  provider         = google-beta
  location         = var.region
  migration_job_id = var.job_name
  display_name     = "RDS to Cloud SQL Migration"
  type             = "CONTINUOUS"
  
  source      = google_database_migration_service_connection_profile.source.name
  destination = google_database_migration_service_connection_profile.destination.name
  
  dump_path = "gs://${google_storage_bucket.dms_bucket.name}"

  vpc_peering_connectivity {
    vpc = var.vpc_network_id
  }
}
