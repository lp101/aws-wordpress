variable "profile" {
  default     = "default"
  description = "AWS Credentials profile"
}

variable "region" {
  default     = "eu-west-1"
  description = "AWS region"
}

# variable "vpc-id" {
#   description = "Set your VPC id here"
#   default     = "vpc-6430b200"
# }

variable "rds_username" {
  description = "RDS Username"
  sensitive   = true
  default     = "administrator"
}
