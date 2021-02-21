resource "aws_s3_bucket" "tenant-a-s3-bucket" {
  bucket = "clouddevops-tenant-a-s3"
  acl    = "private"

  tags = {
    Name        = "Tenant A Bucket"
    Environment = "Eng"
  }
}

resource "aws_s3_bucket" "tenant-b-s3-bucket" {
  bucket = "clouddevops-tenant-b-s3"
  acl    = "private"

  tags = {
    Name        = "Tenant B Bucket"
    Environment = "Eng"
  }
}
