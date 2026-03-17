terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# ---------------------------------------------------------------------------
# AWS Foundation (Source Side)
# ---------------------------------------------------------------------------

module "aws_network" {
  source        = "../../modules/aws-network"
  region        = var.aws_region
  vpc_cidr      = var.vpc_cidr
  subnet_cidr_a = var.subnet_cidr_a
  subnet_cidr_b = var.subnet_cidr_b
}

module "aws_rds" {
  source            = "../../modules/aws-rds"
  subnet_id_a       = module.aws_network.subnet_id_a
  subnet_id_b       = module.aws_network.subnet_id_b
  security_group_id = module.aws_network.rds_security_group_id
  db_password       = var.db_password
  dms_user_password = var.dms_user_password
}

# ---------------------------------------------------------------------------
# GCP Foundation (Destination Side)
# ---------------------------------------------------------------------------

module "gcp_network" {
  source      = "../../modules/gcp-network"
  region      = var.gcp_region
  subnet_cidr = "10.20.0.0/24"
}

module "secrets" {
  source      = "../../modules/secrets"
  secret_id   = "dms-db-password"
  secret_data = var.db_password
}

# ---------------------------------------------------------------------------
# Cloud SQL Destination
# ---------------------------------------------------------------------------

module "cloudsql_new" {
  source                 = "../../modules/cloudsql-new"
  count                  = var.migration_type == "new" ? 1 : 0
  region                 = var.gcp_region
  network_id             = module.gcp_network.network_id
  db_password            = var.db_password
  private_vpc_connection = module.gcp_network.private_vpc_connection
}

module "cloudsql_existing" {
  source        = "../../modules/cloudsql-existing"
  count         = var.migration_type == "existing" ? 1 : 0
  instance_name = var.existing_cloudsql_instance_name
}

locals {
  # DMS cloud_sql_id requires the full connection name: project:region:instance
  # NOT just the instance name — use instance_connection_name output
  target_cloudsql_instance = var.migration_type == "new" ? module.cloudsql_new[0].instance_connection_name : module.cloudsql_existing[0].instance_connection_name
}

# ---------------------------------------------------------------------------
# Database Migration Service
# ---------------------------------------------------------------------------
# The DMS source uses 'dmsuser' (a dedicated replication user) NOT the admin
# account. See the null_resource output in modules/aws-rds/main.tf for the
# SQL commands to create this user after the RDS instance is provisioned.
# ---------------------------------------------------------------------------

module "dms" {
  source = "../../modules/dms"

  region = var.gcp_region

  # Source: AWS RDS accessed via public internet (static_ip_connectivity)
  source_host     = module.aws_rds.address
  source_port     = module.aws_rds.port
  source_username = "dmsuser"         # Dedicated replication user (NOT admin)
  source_password = var.dms_user_password

  # Destination: Cloud SQL instance
  destination_cloudsql_id = local.target_cloudsql_instance
  destination_username    = "root"
  destination_password    = var.db_password

  job_name = "rds-to-cloudsql"
}
