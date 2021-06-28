resource "aws_s3_bucket" "wordpress-deploy" {
  bucket = "wordpress-deploy"
  acl    = "private"
  force_destroy = true

  tags = {
    Name        = "wordpress-deploy"
    Environment = "Prod"
  }
}