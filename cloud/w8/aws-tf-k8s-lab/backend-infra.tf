# -------------------------------------------------------------
# TERRAFORM STATE REMOTE BACKEND INFRASTRUCTURE
# -------------------------------------------------------------

# Random string to ensure a globally unique S3 bucket name for state storage
resource "random_string" "state_suffix" {
  length  = 8
  special = false
  upper   = false
}

# 1. S3 Bucket to hold Terraform state files
resource "aws_s3_bucket" "state_bucket" {
  bucket        = "aws-webapp-state-bucket-${random_string.state_suffix.result}"
  force_destroy = true # Allows easy clean up of the bucket on terraform destroy

  tags = {
    Name        = "Terraform State Storage"
    Project     = var.project_name
    Purpose     = "Remote Backend State"
  }
}

# Enable versioning on S3 bucket to track state history and allow rollbacks
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable default server-side encryption for secure state file storage
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the state bucket (crucial for security)
resource "aws_s3_bucket_public_access_block" "state_public_block" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. DynamoDB Table for Terraform State Locking (prevents concurrent applies)
resource "aws_dynamodb_table" "state_locks" {
  name         = "aws-webapp-state-locks-${random_string.state_suffix.result}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "Terraform State Lock Table"
    Project = var.project_name
    Purpose = "Remote Backend Locking"
  }
}
