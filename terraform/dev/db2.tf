# rds for CDQ

#resource "aws_db_subnet_group" "data_subnet" {
#  name                   = "data-subnet"
#  subnet_ids             = data.aws_subnets.data.ids
#
#  tags = var.common_tags
#}

resource "aws_rds_cluster" "postgres-cdq" {
  cluster_identifier      = "cdq-postgres-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "16.6"
  master_username         = local.db_creds2.adm_username
  master_password         = local.db_creds2.adm_password
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  db_subnet_group_name    = aws_db_subnet_group.data_subnet.name
  kms_key_id              = aws_kms_key.workbc-kms-key.arn
  storage_encrypted       = true
  vpc_security_group_ids  = [data.aws_security_group.data.id, aws_security_group.allow_postgres.id]
  skip_final_snapshot     = true
  final_snapshot_identifier = "cdq-finalsnapshot"
  
  serverlessv2_scaling_configuration {
    max_capacity = 2.0
    min_capacity = 1.0
  }

  tags = var.common_tags
}

# create this manually
data "aws_secretsmanager_secret_version" "creds2" {
  secret_id = "cdq-db-creds"
}

locals {
  db_creds2 = jsondecode(
    data.aws_secretsmanager_secret_version.creds2.secret_string
  )
}
  
resource "aws_rds_cluster_instance" "postgres-cdq" {
  cluster_identifier = aws_rds_cluster.postgres-cdq.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.postgres-cdq.engine
  engine_version     = aws_rds_cluster.postgres-cdq.engine_version
}
