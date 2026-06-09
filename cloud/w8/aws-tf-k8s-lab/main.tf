# -------------------------------------------------------------
# TERRAFORM CONFIGURATION AND PROVIDERS DECLARATION
# -------------------------------------------------------------

terraform {
  required_version = ">= 1.10"

  # Declare the providers needed for this project
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # REMOTE STATE BACKEND CONFIGURATION
  # ----------------------------------------------------------------------------
  # Note: Initially comment this block out. Run `terraform apply` first to create
  # the S3 bucket and DynamoDB table. Then, uncomment this block, fill in the 
  # actual bucket and dynamodb_table names from the terraform outputs, and run 
  # `terraform init -migrate-state` to migrate state file onto AWS.
  # ----------------------------------------------------------------------------
  backend "s3" {
    bucket         = "aws-webapp-state-bucket-72q91t7r"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aws-webapp-state-locks-72q91t7r"
    encrypt        = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# -------------------------------------------------------------
# VPC CUSTOM MODULE INSTANTIATION
# -------------------------------------------------------------
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}
