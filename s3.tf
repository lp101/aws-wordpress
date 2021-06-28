resource "aws_s3_bucket" "wordpress-deploy" {
  bucket = "wordpress-deploy"
  acl    = "private"

  tags = {
    Name        = "wordpress-deploy"
    Environment = "Prod"
  }
}