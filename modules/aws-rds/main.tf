resource "aws_db_subnet_group" "dms_source" {
  name       = "dms-source-subnet-group"
  # AWS requires a DB subnet group to span at least 2 Availability Zones
  subnet_ids = [var.subnet_id_a, var.subnet_id_b]

  tags = {
    Name = "dms-source-subnet-group"
  }
}

resource "aws_db_parameter_group" "dms_source" {
  name        = "dms-source-mysql8"
  family      = "mysql8.0"
  description = "Parameter group for DMS source RDS - enables binary logging for CDC"

  # Required: ROW-level binary logging for Change Data Capture (CDC)
  parameter {
    name         = "binlog_format"
    value        = "ROW"
    apply_method = "pending-reboot"
  }

  # Required: Full row image so DMS can capture all column values on UPDATE/DELETE
  parameter {
    name         = "binlog_row_image"
    value        = "FULL"
    apply_method = "pending-reboot"
  }

  # Disable checksum so DMS can read binary logs without checksum mismatch errors
  parameter {
    name         = "binlog_checksum"
    value        = "NONE"
    apply_method = "pending-reboot"
  }

  tags = {
    Name    = "dms-source-mysql8-params"
    Purpose = "Enable binary logging for Google Cloud DMS"
  }
}

resource "aws_db_instance" "source" {
  identifier             = "dms-source-db"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "appdb"
  username               = "admin"
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.dms_source.name
  db_subnet_group_name   = aws_db_subnet_group.dms_source.name
  vpc_security_group_ids = [var.security_group_id]

  skip_final_snapshot = true
  # Must be true so Google Cloud DMS (external to AWS) can reach this instance
  publicly_accessible = true
  multi_az            = false

  # Retain binary logs for 24 hours minimum so DMS can catch up after disruptions
  backup_retention_period = 1
  backup_window           = "03:00-04:00"

  tags = {
    Name    = "dms-source-db"
    Purpose = "DMS Migration Source"
  }
}

# ---------------------------------------------------------------------------
# DMS Replication User Setup
# ---------------------------------------------------------------------------
# Google Cloud DMS requires a dedicated MySQL user with REPLICATION privileges.
# Terraform cannot natively execute arbitrary SQL; this null_resource logs the
# exact SQL that must be run MANUALLY (or via a CI/CD step) against the RDS
# instance once it is available.
#
# Run the following SQL as the 'admin' user on the RDS endpoint:
#
#   CREATE USER 'dmsuser'@'%' IDENTIFIED BY '<dms_replication_password>';
#   GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'dmsuser'@'%';
#   GRANT SELECT ON *.* TO 'dmsuser'@'%';
#   FLUSH PRIVILEGES;
#
# The dms_replication_password is stored in the variable var.dms_user_password.
# ---------------------------------------------------------------------------
resource "null_resource" "dms_replication_user_instructions" {
  # Re-run if the RDS instance or DMS user password changes
  triggers = {
    rds_endpoint     = aws_db_instance.source.endpoint
    dms_user_version = var.dms_user_password
  }

  provisioner "local-exec" {
    command = <<-EOT
      Write-Host "=================================================================="
      Write-Host "ACTION REQUIRED: Create the DMS replication user on RDS"
      Write-Host "=================================================================="
      Write-Host "Connect to RDS endpoint: ${aws_db_instance.source.address}:${aws_db_instance.source.port}"
      Write-Host "Run the following SQL as the admin user:"
      Write-Host ""
      Write-Host "  CREATE USER 'dmsuser'@'%' IDENTIFIED BY '${var.dms_user_password}';"
      Write-Host "  GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'dmsuser'@'%';"
      Write-Host "  GRANT SELECT ON *.* TO 'dmsuser'@'%';"
      Write-Host "  FLUSH PRIVILEGES;"
      Write-Host ""
      Write-Host "Connect via mysql CLI:"
      Write-Host "  mysql -h ${aws_db_instance.source.address} -P ${aws_db_instance.source.port} -u admin -p"
      Write-Host "=================================================================="
    EOT
    interpreter = ["PowerShell", "-Command"]
  }

  depends_on = [aws_db_instance.source]
}
