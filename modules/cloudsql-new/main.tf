resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "main" {
  name             = "${var.instance_name}-${random_id.db_name_suffix.hex}"
  database_version = var.database_version
  region           = var.region

  settings {
    tier              = var.tier
    availability_type = "ZONAL" # Cost-optimized for demo; use REGIONAL for production

    # ---------------------------------------------------------------------------
    # Database Flags required by Google Cloud DMS for CDC (Change Data Capture)
    # ---------------------------------------------------------------------------
    database_flags {
      name  = "binlog_format"
      value = "ROW"
    }

    database_flags {
      name  = "binlog_row_image"
      value = "FULL"
    }

    # ---------------------------------------------------------------------------
    # Backup Configuration
    # Must be enabled on Cloud SQL so binary logs are retained
    # ---------------------------------------------------------------------------
    backup_configuration {
      enabled            = true
      binary_log_enabled = true # Enables binary logging on Cloud SQL (needed for DMS CDC)
      start_time         = "03:00"
    }

    # ---------------------------------------------------------------------------
    # IP Configuration
    # ---------------------------------------------------------------------------
    ip_configuration {
      # Enable public IPv4 so that DMS (via static_ip_connectivity) can reach Cloud SQL.
      # For production, combine with authorized_networks restrictions.
      ipv4_enabled    = true
      private_network = var.network_id

      # Allow the DMS service to connect from its public egress IPs.
      # DMS for asia-south1 uses the IP ranges documented at:
      # https://cloud.google.com/database-migration/docs/mysql/network
      # For demo purposes we allow all; restrict to DMS IPs in production.
      authorized_networks {
        name  = "allow-dms-public"
        value = "0.0.0.0/0"
      }
    }

    maintenance_window {
      day          = 7 # Sunday
      hour         = 4
      update_track = "stable"
    }
  }

  deletion_protection = false # Set to true in production

  # NOTE: The private_vpc_connection dependency is handled at the environment level
  # by passing private_vpc_connection as an explicit input only after it is ready.
  # Terraform's implicit dependency graph handles the ordering automatically.
}

resource "google_sql_database" "default" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "root" {
  name     = "root"
  instance = google_sql_database_instance.main.name
  password = var.db_password
  host     = "%"
}
