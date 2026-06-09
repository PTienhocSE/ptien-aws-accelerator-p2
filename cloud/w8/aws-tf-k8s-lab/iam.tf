# -------------------------------------------------------------
# IAM ROLE AND INSTANCE PROFILE FOR S3 ACCESS
# -------------------------------------------------------------

# Create IAM Role for EC2 Instance to assume
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-ec2-role"
    Project = var.project_name
  }
}

# Create IAM Policy for S3 static assets access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.project_name}-s3-policy"
  description = "Allows EC2 instance to read/write/list static assets in S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.assets.id}",
          "arn:aws:s3:::${aws_s3_bucket.assets.id}/*"
        ]
      }
    ]
  })
}

# Attach policy to IAM Role
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Create EC2 Instance Profile using IAM Role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
