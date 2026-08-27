# Clé générée par Terraform : la clé privée est stockée dans le state (backend GitLab,
# chiffré côté serveur) et doit être copiée une fois dans une variable GitLab CI/CD
# masquée/protégée (ex: SSH_PRIVATE_KEY) pour permettre au pipeline de déployer sans PC local.
resource "tls_private_key" "app" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "app" {
  key_name   = "${var.project_name}-app-key"
  public_key = tls_private_key.app.public_key_openssh

  tags = {
    Name    = "${var.project_name}-app-key"
    Project = var.project_name
  }
}
