# -------------------------------------------------------------
# SECURITY CONFIGURATION: SECURITY GROUPS
# -------------------------------------------------------------

# 1. Security Group for the EC2 Web Server
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allows HTTP and SSH traffic from the Internet"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound HTTP (port 80) from any IP address
  ingress {
    description      = "HTTP from Internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Allow inbound SSH (port 22) from any IP address for administration
  ingress {
    description      = "SSH from Internet"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.project_name}-ec2-sg"
    Project = var.project_name
  }
}

# 2. Security Group for the RDS MySQL Database
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Allows MySQL traffic only from the EC2 security group"
  vpc_id      = module.vpc.vpc_id

  # Allow MySQL inbound (port 3306) exclusively from the EC2 instance's security group
  ingress {
    description     = "MySQL from EC2 Web Server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  # Allow all outbound traffic (though database usually stays isolated)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.project_name}-db-sg"
    Project = var.project_name
  }
}
