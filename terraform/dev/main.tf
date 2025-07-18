
locals {
  common_tags        = var.common_tags
}

resource "aws_s3_bucket" "example" {
  bucket = "my-tf-test-bucket-workbc"
 
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
