# -------------------------------------------------------------
# VPC MODULE VARIABLES DECLARATION
# -------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (Should have at least 2 for multi-AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (Should have at least 2 for RDS Multi-AZ subnet group)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "project_name" {
  description = "Project name tag value for resource identification"
  type        = string
  default     = "aws-webapp-lab"
}
