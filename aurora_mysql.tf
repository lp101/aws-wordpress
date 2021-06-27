# # RDS Aurora Mysql Parameter group
# resource "aws_db_parameter_group" "mysql-pg" {
#   name   = "mysql-pg"
#   family = "mysql8.0"

#   # parameter {
#   #   name  = "log_connections"
#   #   value = "1"
#   # }
# }

resource "aws_db_parameter_group" "aurora-mysql-pg" {
  name        = "aurora-mysql-pg"
  family      = "aurora-mysql5.7"
  description = "aurora-mysql-pg"
  #tags        = local.tags
}

resource "aws_rds_cluster_parameter_group" "rds-cluster-aurora-mysql-pg" {
  name        = "rds-cluster-aurora-mysql-pg"
  family      = "aurora-mysql5.7"
  description = "rds-cluster-aurora-mysql-pg"
  #tags        = local.tags
}

# Aurora Mysql
module "db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  #version = "~> 3.0"
  version = "5.2.0"

  # DB configurations
  name           = "aurora-mysql-wp"
  database_name  = "wordpress"
  engine         = "aurora-mysql"
  engine_version = "5.7.12"
  instance_type  = "db.t3.medium"
  instance_type_replica = "db.t3.medium"
  apply_immediately   = true # for updating
  replica_count  = 1

  # Authentication
  iam_database_authentication_enabled = true
  #create_random_password = false
  username = var.rds_username
  #password = var.rds_password

  # Networking
  vpc_id  = module.vpc.vpc_id
  subnets = [aws_subnet.db-subnet-a.id,aws_subnet.db-subnet-b.id,aws_subnet.db-subnet-c.id]
  allowed_security_groups = [aws_security_group.beanstalk-wordpress-sg.id]
  #allowed_cidr_blocks = ["10.20.0.0/20"]
  create_security_group = true
  publicly_accessible = false

  # Storage
  storage_encrypted   = true

  # Backups
  #backup_retention_period = 7 # Default is 7
  skip_final_snapshot = true
  copy_tags_to_snapshot = true
  deletion_protection = false

  # Monitoring
  monitoring_interval = 10
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  # Parameters group
  db_parameter_group_name         = aws_db_parameter_group.aurora-mysql-pg.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds-cluster-aurora-mysql-pg.id

  # Tags
  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
}














