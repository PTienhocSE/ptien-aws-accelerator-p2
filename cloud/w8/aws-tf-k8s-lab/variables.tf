# -------------------------------------------------------------
# INPUT VARIABLES DECLARATION
# -------------------------------------------------------------

variable "aws_region" {
  description = "The AWS Region to deploy the infrastructure into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type to run the Web App. t3.micro is default."
  type        = string
  default     = "t3.micro"
}

variable "project_name" {
  description = "Name tag prefix for resources"
  type        = string
  default     = "aws-webapp-lab"
}

variable "vpc_cidr" {
  description = "CIDR range for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "Username for the RDS MySQL Database"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Password for the RDS MySQL Database"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Initial database name to create in MySQL"
  type        = string
  default     = "webappdb"
}
