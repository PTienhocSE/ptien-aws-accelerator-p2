# -------------------------------------------------------------
# TERRAFORM OUTPUTS
# -------------------------------------------------------------

# 1. The public URL of the Web App
output "web_app_url" {
  description = "The public URL to access your Web Application over the Internet"
  value       = "http://${aws_instance.web_server.public_ip}"
}

# 2. The public IP address of the EC2 Web Server
output "ec2_public_ip" {
  description = "The public IP address of the EC2 Instance"
  value       = aws_instance.web_server.public_ip
}

# 3. Pre-formatted SSH command for debugging
output "ssh_command" {
  description = "The SSH command to connect to your EC2 Web Server"
  value       = "ssh -i minikube-key.pem ubuntu@${aws_instance.web_server.public_ip}"
}

# 4. RDS MySQL Endpoint
output "rds_endpoint" {
  description = "The connection endpoint for the RDS MySQL instance"
  value       = aws_db_instance.mysql.endpoint
}

# 5. S3 Assets Bucket Name
output "s3_assets_bucket" {
  description = "The name of the S3 bucket created for static assets"
  value       = aws_s3_bucket.assets.id
}

# 6. S3 State Bucket Name (For Remote Backend Config)
output "state_bucket_name" {
  description = "S3 bucket name created for Terraform State storage"
  value       = aws_s3_bucket.state_bucket.id
}

# 7. DynamoDB State Lock Table Name (For Remote Backend Config)
output "state_lock_table_name" {
  description = "DynamoDB table name created for Terraform State Locking"
  value       = aws_dynamodb_table.state_locks.id
}
