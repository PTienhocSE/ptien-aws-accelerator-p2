# -------------------------------------------------------------
# EC2 WEB SERVER CONFIGURATION AND BOOTSTRAP SCRIPT
# -------------------------------------------------------------

# Search for the latest official Ubuntu 22.04 LTS AMI from Canonical on AWS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Compile bootstrap configuration and inject environment parameters
data "cloudinit_config" "webapp_setup" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    filename     = "setup.sh"
    content = templatefile("${path.module}/templates/setup.sh", {
      db_host    = aws_db_instance.mysql.address
      db_user    = var.db_username
      db_pass    = var.db_password
      db_name    = var.db_name
      s3_bucket  = aws_s3_bucket.assets.id
      aws_region = var.aws_region
    })
  }
}

# Provision EC2 Web Server Instance in Public Subnet
resource "aws_instance" "web_server" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = module.vpc.public_subnet_ids[0] # Place in the first public subnet
  
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.deployer.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size           = 20 # 20 GB gp3 storage is plenty
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # Ensure the application artifacts are uploaded to S3 BEFORE launching the EC2 instance,
  # so the bootstrap script can download them successfully.
  depends_on = [
    aws_s3_object.app_code,
    aws_s3_object.app_html
  ]

  user_data = data.cloudinit_config.webapp_setup.rendered

  tags = {
    Name    = "${var.project_name}-web-server"
    Project = var.project_name
  }
}
