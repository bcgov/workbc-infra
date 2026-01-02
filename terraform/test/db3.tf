# rds for JobBoard

resource "aws_rds_cluster" "postgres-jobboard" {
  cluster_identifier      = "jobboard-postgres-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "16.8"
#  engine_mode             = "provisioned"
  master_username         = local.db_creds3.adm_username
  master_password         = local.db_creds3.adm_password
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  db_subnet_group_name    = aws_db_subnet_group.data_subnet.name
  kms_key_id              = aws_kms_key.workbc-kms-key.arn
  storage_encrypted       = true
  vpc_security_group_ids  = [data.aws_security_group.data.id, aws_security_group.allow_postgres.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.jobboard_pg.name
  skip_final_snapshot     = true
  final_snapshot_identifier = "jobboard-finalsnapshot"
  
  serverlessv2_scaling_configuration {
    max_capacity = 2.0
    min_capacity = 1.0
  }

  tags = var.common_tags
}

# create this manually
data "aws_secretsmanager_secret_version" "creds3" {
  secret_id = "jobboard-db-creds"
}

locals {
  db_creds3 = jsondecode(
    data.aws_secretsmanager_secret_version.creds3.secret_string
  )
}
  
resource "aws_rds_cluster_instance" "postgres-jobboard" {
  count = 2
  cluster_identifier = aws_rds_cluster.postgres-jobboard.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.postgres-jobboard.engine
  engine_version     = aws_rds_cluster.postgres-jobboard.engine_version
}

resource "aws_rds_cluster_parameter_group" "jobboard_pg" {
  name        = "jobboard-pg"
  family      = "aurora-postgresql16"
  description = "JobBoard cluster parameter group"

  parameter {
    name  = "cron.database_name"
    value = "jobboard"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,pg_cron"
    apply_method = "pending-reboot"
  }
}
