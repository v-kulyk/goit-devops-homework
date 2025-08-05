# Note: This file should be uncommented after initial S3 bucket creation
# terraform {
#   backend "s3" {
#     bucket         = "bucket-name-here"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
