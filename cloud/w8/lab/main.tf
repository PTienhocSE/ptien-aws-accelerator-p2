terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# DAY 1 - Lesson 2: Create an S3 bucket with Terraform
# resource "aws_s3_bucket" "first" {
#   bucket_prefix = "tf-series-bai2-"
#   force_destroy = true

#   tags = {
#     Project = "terraform-series"
#     Bai     = "02"
#   }
# }

# output "bucket_name" {
#   value = aws_s3_bucket.first.id
# }

# output "bucket_arn" {
#   value = aws_s3_bucket.first.arn
# }

# DAY 1 - Lesson 4: Create an S3 bucket with Terraform and add tags
# resource "aws_s3_bucket" "demo" {
#   bucket_prefix = "tf-series-bai4-"
#   force_destroy = true

#   tags = {
#     Project = "terraform-series"
#     Env     = "dev"
#   }
# }

# output "bucket_name" {
#   value = aws_s3_bucket.demo.id
# }

# output "bucket_arn" {
#   value = aws_s3_bucket.demo.arn
# }


# DAY 2 - Lesson 5: Create an S3 bucket with Terraform and enable versioning
# resource "aws_s3_bucket" "data" {
#   bucket_prefix = "tf-series-bai5-"
#   force_destroy = true
# }

# resource "aws_s3_bucket_versioning" "data" {
#   bucket = aws_s3_bucket.data.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# Day 2 - Lesson 6: Remote State on S3 With use_lockfile
# resource "aws_s3_bucket" "state" {
#   bucket_prefix = "tf-series-state-"
#   force_destroy = true # chỉ để dọn lab; KHÔNG bật ở thật
# }

# resource "aws_s3_bucket_versioning" "state" {
#   bucket = aws_s3_bucket.state.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
#   bucket = aws_s3_bucket.state.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# resource "aws_s3_bucket_public_access_block" "state" {
#   bucket                  = aws_s3_bucket.state.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

#Day 2 - Lesson 8: Sensitive Variables and Outputs
# variable "db_password" {
#   type      = string
#   sensitive = true
#   default   = "super-secret-123"
# }

# output "password_echo" {
#   value     = var.db_password
#   sensitive = true
# }

# variable "secret_value" {
#   type      = string
#   sensitive = true
#   default   = "p@ssw0rd-bai8-demo"
# }

# # CŨ: giá trị sẽ vào state
# resource "aws_secretsmanager_secret_version" "legacy" {
#   secret_id     = aws_secretsmanager_secret.legacy.id
#   secret_string = var.secret_value
# }

# # MỚI: write-only, giá trị KHÔNG vào state
# resource "aws_secretsmanager_secret_version" "wo" {
#   secret_id                = aws_secretsmanager_secret.wo.id
#   secret_string_wo         = var.secret_value
#   secret_string_wo_version = 1
# }

# #Day 2 - Lesson 10: Data Sources, Functions, for Expressions and Dynamic Blocks
# data "aws_caller_identity" "current" {}
# 
# data "aws_availability_zones" "available" {
#   state = "available"
# }
# 
# data "aws_ami" "al2023" {
#   most_recent = true
#   owners      = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["al2023-ami-2023.*-x86_64"]
#   }
# }
# 
# output "account_id" {
#   value = data.aws_caller_identity.current.account_id
# }
# 
# output "az_names" {
#   value = data.aws_availability_zones.available.names
# }
# 
# output "latest_al2023_ami" {
#   value = data.aws_ami.al2023.id
# }

# variable "allowed_ports" {
#   type    = list(number)
#   default = [80, 443, 22]
# }

# locals {
#   # list: lấy các cổng, lọc bỏ 22 bằng mệnh đề if
#   web_ports = [for p in var.allowed_ports : p if p != 22]

#   # map: cổng -> mô tả
#   port_desc = { for p in var.allowed_ports : p => "cho phép cổng ${p}" }
# }

# resource "aws_security_group" "web" {
#   name_prefix = "tf-series-bai10-"
#   vpc_id      = data.aws_vpc.default.id

#   dynamic "ingress" {
#     for_each = local.web_ports
#     content {
#       description = "HTTP/HTTPS ${ingress.value}"
#       from_port   = ingress.value
#       to_port     = ingress.value
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
