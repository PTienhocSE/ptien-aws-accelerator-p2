# AWS 3-TIER WEB APP - AUTOMATED TERRAFORM DEPLOYMENT

This repository contains the Terraform configuration files and bootstrap scripts to deploy a secure, cost-optimized, and premium 3-tier web application stack on AWS. The infrastructure features a custom VPC, an EC2 Web Server running a Flask application, an isolated RDS MySQL database, an S3 bucket for static assets, and a remote S3 state backend with DynamoDB state locking.

---

## 1. ARCHITECTURE OVERVIEW

```text
User Browser -> EC2 Web Server (Port 80) -> RDS MySQL Database (Port 3306)
                                        -> S3 Static Assets Bucket (boto3 SDK)
```

*   **VPC Module**: Custom VPC (`10.0.0.0/16`) with 2 Public Subnets and 2 Private Subnets spanning 2 Availability Zones.
*   **EC2 Web Server**: A Python Flask application running in a public subnet, configured with systemd capabilities (`CAP_NET_BIND_SERVICE`) to securely bind to port 80 without running as root.
*   **RDS MySQL Database**: A MySQL instance isolated in private subnets, with inbound traffic allowed *only* from the EC2 Web Server security group.
*   **S3 Static Assets**: Secure private S3 bucket utilized to store static assets. To bypass the 16KB EC2 userdata payload limit, the application code artifacts (`app.py` and `index.html`) are also uploaded here via Terraform and downloaded on first-boot.
*   **State Backend**: Configured to store Terraform state in a remote S3 bucket with versioning and concurrent run locking managed via DynamoDB.

---

## 2. DEPLOYMENT INSTRUCTIONS

To deploy this infrastructure, follow these steps sequentially:

### Step 1: Initialize the local directory
```bash
terraform init
```

### Step 2: Provision the infrastructure (Local state first)
Ensure the `backend "s3"` block in `main.tf` is **commented out** for this initial run, then deploy:
```bash
terraform apply -auto-approve
```

### Step 3: Migrate State to Remote Backend
Once the apply finishes:
1. Open [main.tf](file:///d:/Workspace/Study/AWS/aws-tf-k8s-lab/main.tf).
2. Uncomment the `backend "s3"` block.
3. Replace the bucket name and dynamodb_table name values with the `state_bucket_name` and `state_lock_table_name` printed in the terraform outputs.
4. Run the state migration command:
```bash
terraform init -plugin-dir=".terraform/providers" -migrate-state -force-copy
```
Your state is now securely stored on AWS with concurrent locking enabled!

---

## 3. VERIFICATION AND TELEMETRY

After deployment, the terminal outputs will display:
- `web_app_url`: The URL to access the live web application.
- `ec2_public_ip`: Public IP of the web server.
- `ssh_command`: SSH command to connect to the EC2 server.
- `rds_endpoint`: Database connection endpoint.
- `s3_assets_bucket`: Name of the created assets bucket.

### 3.1. Monitor Server Bootstrap Logs
Connect to the server:
```bash
ssh -i minikube-key.pem ubuntu@<EC2_PUBLIC_IP>
```
Audit the cloud-init bootstrap progress:
```bash
tail -f /var/log/user_data_setup.log
```

### 3.2. Inspect Web Application Service
Verify the Flask service status under systemd:
```bash
sudo systemctl status webapp.service
```
View web app service execution logs:
```bash
sudo journalctl -u webapp -f
```

---

## 4. DECOMMISSIONING

To tear down all AWS resources and cleanup local key files, run:
```bash
terraform destroy -auto-approve
```