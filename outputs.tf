output "vpc_id" {
  description = "VPC Id"
  value       = module.vpc.vpc_id
  sensitive   = false
}
output "subnet_efs_a_id" {
  description = "EFS Subnet Zone A"
  value       = aws_subnet.efs-subnet-a.id
  sensitive   = false
}
output "subnet_efs_b_id" {
  description = "EFS Subnet Zone B"
  value       = aws_subnet.efs-subnet-b.id
  sensitive   = false
}
output "subnet_efs_c_id" {
  description = "EFS Subnet Zone C"
  value       = aws_subnet.efs-subnet-c.id
  sensitive   = false
}

output "rds_database_name" {
  description = "RDS Mysql Name"
  value       = module.db.rds_cluster_database_name
}
output "rds_hostname" {
  description = "RDS instance hostname"
  value       = module.db.rds_cluster_endpoint
}
output "rds_port" {
  description = "RDS instance port"
  value       = module.db.rds_cluster_port
}
# output "rds_username" {
#   description = "RDS instance username"
#   value       = module.db.rds_cluster_master_username
#   sensitive = true
# }
# output "rds_password" {
#   description = "RDS instance password"
#   value       = module.db.rds_cluster_master_password
#   sensitive = true
# }

output "endpoint" {
  description = "Fully qualified DNS name for the environment"
  value       = aws_elastic_beanstalk_environment.wordpressenv.cname
}