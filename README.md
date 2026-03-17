# Database Migration Service: AWS RDS → Google Cloud SQL (MySQL)

This Terraform project automates the full infrastructure stack for migrating a MySQL database from **AWS RDS** to **Google Cloud SQL** using **Google Cloud Database Migration Service (DMS)** with continuous CDC replication.

## Architecture

```
AWS (ap-south-1)                          GCP (asia-south1)
─────────────────────────────             ───────────────────────────────────
VPC (10.10.0.0/16)                        VPC (custom, 10.20.0.0/24)
  └─ Public Subnet (10.10.1.0/24)           └─ Private Service Connection
       └─ RDS MySQL 8.0 (db.t3.micro)            └─ Cloud SQL MySQL 8.0
            publicly_accessible = true                 binary_log_enabled = true
            binlog_format       = ROW                  binlog_format      = ROW
            binlog_row_image    = FULL                 binlog_row_image   = FULL
            binlog_checksum     = NONE                 ipv4_enabled       = true
                 │                                          │
                 └──────────────────────────────────────────┘
                          Google Cloud DMS
                    (static_ip_connectivity)
                    [Full Load + CDC Continuous]
```

## Module Overview

| Module | Provider | Purpose |
|---|---|---|
| `aws-network` | AWS | VPC, public subnet, IGW, route table, Security Group (port 3306) |
| `aws-rds` | AWS | RDS MySQL 8.0 with binary logging parameter group + replication user instructions |
| `gcp-network` | GCP | VPC, subnet, private service connection for Cloud SQL |
| `cloudsql-new` | GCP | Cloud SQL MySQL 8.0 with DMS-required flags and binary logging |
| `cloudsql-existing` | GCP | Data source for an existing Cloud SQL instance |
| `secrets` | GCP | Secret Manager secret for DB credentials |
| `dms` | GCP | DMS connection profiles + continuous migration job |

---

## Pre-requisites

### Tools
- Terraform >= 1.0.0
- AWS CLI configured (`aws configure`)
- Google Cloud SDK (`gcloud auth login && gcloud auth application-default login`)
- MySQL client (for creating the replication user after apply)

### GCP APIs (enable in your project)
```bash
gcloud services enable \
  datamigration.googleapis.com \
  sqladmin.googleapis.com \
  servicenetworking.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com \
  --project YOUR_GCP_PROJECT_ID
```

---

## Deployment

### Step 1 – Navigate to the environment
```bash
cd environments/mumbai
```

### Step 2 – Configure Variables
Edit `terraform.tfvars`:
```hcl
gcp_project_id    = "your-actual-project-id"
db_password       = "YourSecureAdminPass123!"   # RDS admin + Cloud SQL root
dms_user_password = "YourDmsUserPass456!"       # For 'dmsuser' replication account
migration_type    = "new"
```

### Step 3 – Initialize and Apply
```bash
terraform init
terraform plan
terraform apply
```

---

## Step 4 – Create the DMS Replication User (REQUIRED)

> **This step MUST be done after `terraform apply` and BEFORE starting the migration job.**

Google Cloud DMS requires a dedicated MySQL user with replication privileges. Terraform provisions the infrastructure but cannot execute arbitrary SQL against RDS. Run the following SQL using the **admin** credentials:

```bash
# Get the RDS endpoint from Terraform output
RDS_HOST=$(terraform output -raw aws_rds_address)

# Connect to RDS
mysql -h "$RDS_HOST" -P 3306 -u admin -p
```

Then run inside the MySQL session:
```sql
CREATE USER 'dmsuser'@'%' IDENTIFIED BY 'YourDmsUserPass456!';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'dmsuser'@'%';
GRANT SELECT ON *.* TO 'dmsuser'@'%';
FLUSH PRIVILEGES;

-- Verify grants
SHOW GRANTS FOR 'dmsuser'@'%';
```

---

## Step 5 – Start the Migration Job

```bash
gcloud database-migration migration-jobs start rds-to-cloudsql \
  --region=asia-south1 \
  --project=YOUR_GCP_PROJECT_ID
```

### Monitor Status
```bash
gcloud database-migration migration-jobs describe rds-to-cloudsql \
  --region=asia-south1 \
  --project=YOUR_GCP_PROJECT_ID
```

---

## Binary Logging Configuration

### AWS RDS (Source)
The `aws-rds` module creates a custom DB parameter group with these settings required by DMS:

| Parameter | Value | Purpose |
|---|---|---|
| `binlog_format` | `ROW` | Row-based binary logging for CDC |
| `binlog_row_image` | `FULL` | Capture all column values on UPDATE/DELETE |
| `binlog_checksum` | `NONE` | Prevent DMS checksum mismatch errors |

> **Note:** `backup_retention_period = 1` is set on RDS to ensure binary logs are retained.

### Cloud SQL (Destination)
The `cloudsql-new` module configures:

| Flag | Value | Purpose |
|---|---|---|
| `binlog_format` | `ROW` | Required for DMS |
| `binlog_row_image` | `FULL` | Required for DMS |
| `backup_configuration.binary_log_enabled` | `true` | Enables binary logging on Cloud SQL |

---

## Networking & Connectivity

### DMS Connectivity Mode: `static_ip_connectivity`
This project uses **static IP connectivity** — the correct mode when the source is **external to GCP** (AWS RDS over the public internet).

DMS connects from a set of **static egress IPs** specific to `asia-south1`. For production, restrict the AWS RDS Security Group ingress to only these IPs:

- See: https://cloud.google.com/database-migration/docs/mysql/network

For this demo, the Security Group allows `0.0.0.0/0` on port 3306. **Restrict this in production.**

### VS. `vpc_peering_connectivity`
`vpc_peering_connectivity` is only appropriate when **both source and destination are within GCP**. For AWS → GCP migrations, always use `static_ip_connectivity` or `reverse_ssh_tunnel`.

---

## Cleanup

```bash
terraform destroy
```

> **Warning:** This destroys all resources including the RDS instance and Cloud SQL instance. Make sure to take a final backup before destroying.

---

## Variable Reference

| Variable | Description | Default |
|---|---|---|
| `aws_region` | AWS region | `ap-south-1` |
| `gcp_region` | GCP region | `asia-south1` |
| `gcp_project_id` | GCP project ID | *(required)* |
| `db_password` | Admin/root DB password for RDS and Cloud SQL | *(required)* |
| `dms_user_password` | Password for `dmsuser` replication account on RDS | *(required)* |
| `migration_type` | `new` or `existing` Cloud SQL instance | `new` |
| `existing_cloudsql_instance_name` | Name of existing Cloud SQL instance (if `migration_type=existing`) | `""` |
