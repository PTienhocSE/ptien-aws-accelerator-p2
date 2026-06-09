#!/bin/bash
# -------------------------------------------------------------
# EC2 BOOTSTRAP SCRIPT: INSTALL PYTHON DEPS & LAUNCH FLASK WEB APP
# -------------------------------------------------------------

# Redirect all stdout/stderr to a log file for troubleshooting
exec > >(tee -i /var/log/user_data_setup.log) 2>&1

echo "=== Starting System Initialization (Web App Stack) ==="
date

# Update system packages
apt-get update -y
apt-get install -y python3-pip python3-venv curl jq

# Create a virtual environment to prevent package conflict issues
echo "=== Setting up Python Virtual Environment ==="
python3 -m venv /home/ubuntu/venv
/home/ubuntu/venv/bin/pip install --upgrade pip
/home/ubuntu/venv/bin/pip install flask mysql-connector-python boto3

# Create application directories
echo "=== Creating Directories ==="
mkdir -p /home/ubuntu/templates

# Download code artifacts from S3 using Python and Boto3 (utilizing the EC2 instance role)
echo "=== Downloading Application Artifacts from S3 ==="
/home/ubuntu/venv/bin/python3 -c "
import boto3
s3 = boto3.client('s3', region_name='${aws_region}')
s3.download_file('${s3_bucket}', 'app.py', '/home/ubuntu/app.py')
s3.download_file('${s3_bucket}', 'templates/index.html', '/home/ubuntu/templates/index.html')
"

# Set permissions for the ubuntu user
chown -R ubuntu:ubuntu /home/ubuntu

# Create systemd service to run the Flask application
echo "=== Registering Web App systemd service ==="
cat << EOF > /etc/systemd/system/webapp.service
[Unit]
Description=AWS Web Application (Python Flask)
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
Environment="DB_HOST=${db_host}"
Environment="DB_USER=${db_user}"
Environment="DB_PASSWORD=${db_pass}"
Environment="DB_NAME=${db_name}"
Environment="S3_BUCKET=${s3_bucket}"
Environment="AWS_REGION=${aws_region}"
ExecStart=/home/ubuntu/venv/bin/python /home/ubuntu/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload, enable, and launch the service
systemctl daemon-reload
systemctl enable webapp.service
systemctl start webapp.service

echo "=== Web Application setup completed successfully ==="
systemctl status webapp.service
date
