# -------------------------------------------------------------
# SSH KEY PAIR GENERATION FOR EC2
# -------------------------------------------------------------

# [REQUIREMENT MAPPING: Req 6 - Use >= 2 Terraform providers & wire them together]
# We use the separate "tls" provider to generate an RSA private key.
resource "tls_private_key" "minikube_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# [REQUIREMENT MAPPING: Req 6 - Wiring the tls provider output into the aws provider input]
# We take the public key output from 'tls_private_key.minikube_key' (tls provider) 
# and pass it to the public_key parameter of 'aws_key_pair.deployer' (aws provider).
resource "aws_key_pair" "deployer" {
  key_name   = "minikube-key-pair"
  public_key = tls_private_key.minikube_key.public_key_openssh
}

# [REQUIREMENT MAPPING: Req 6 - Using another provider (local) to save the private key locally]
resource "local_file" "private_key" {
  content         = tls_private_key.minikube_key.private_key_pem
  filename        = "${path.module}/minikube-key.pem"
  file_permission = "0600" # Sets read-only permissions for the owner
}
