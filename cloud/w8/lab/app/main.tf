terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "tf-series-state-20260602033548393100000001"
    key          = "app/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "app" {
  bucket_prefix = "tf-series-bai6-app-"
  force_destroy = true
}
