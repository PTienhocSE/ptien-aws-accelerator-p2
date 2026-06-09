# -------------------------------------------------------------
# S3 STATIC ASSETS BUCKET CONFIGURATION
# -------------------------------------------------------------

# Random string to ensure a globally unique S3 bucket name
resource "random_string" "assets_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create S3 Bucket for static assets
resource "aws_s3_bucket" "assets" {
  bucket        = "aws-webapp-assets-${random_string.assets_suffix.result}"
  force_destroy = true # Allows easy deletion of bucket contents during destroy

  tags = {
    Name    = "Web Application Static Assets"
    Project = var.project_name
  }
}

# Enable versioning for historical backups
resource "aws_s3_bucket_versioning" "assets_versioning" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable default server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "assets_encryption" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access (files will be served securely via Flask backend using boto3 SDK)
resource "aws_s3_bucket_public_access_block" "assets_public_block" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -------------------------------------------------------------
# UPLOAD APPLICATION CODE ARTIFACTS TO S3
# -------------------------------------------------------------
# By uploading the application code to S3, we bypass the 16KB limit
# on EC2 user_data. The EC2 instance downloads these files at startup.

resource "aws_s3_object" "app_code" {
  bucket = aws_s3_bucket.assets.id
  key    = "app.py"
  source = "${path.module}/templates/app.py"
  etag   = filemd5("${path.module}/templates/app.py")
}

resource "aws_s3_object" "app_html" {
  bucket = aws_s3_bucket.assets.id
  key    = "templates/index.html"
  source = "${path.module}/templates/index.html"
  etag   = filemd5("${path.module}/templates/index.html")
}
