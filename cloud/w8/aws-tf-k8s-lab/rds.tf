# -------------------------------------------------------------
# RDS MYSQL DATABASE CONFIGURATION
# -------------------------------------------------------------

# Create DB Subnet Group across private subnets for RDS placement
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

# Provision RDS MySQL Database Instance
resource "aws_db_instance" "mysql" {
  identifier           = "${var.project_name}-mysql"
  allocated_storage    = 20                  # 20 GB (Free Tier Eligible)
  max_allocated_storage = 100                 # Auto-scaling storage limit
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"       # Free Tier Eligible
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  skip_final_snapshot  = true               # Skip backup when destroying for fast lab cleanup
  publicly_accessible  = false              # DB is isolated from public internet

  tags = {
    Name    = "${var.project_name}-mysql"
    Project = var.project_name
  }
}
