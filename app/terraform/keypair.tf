# Clé générée par Terraform : la clé privée est stockée dans le state (backend GitLab,
# chiffré côté serveur) et lue directement depuis ce state par le job de déploiement
# (terraform output -raw app_ssh_private_key) - jamais copiée dans une variable
# GitLab CI/CD, pour ne jamais la faire résider ailleurs que dans le state chiffré.
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
