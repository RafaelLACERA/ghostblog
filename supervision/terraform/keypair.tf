# Cle SSH dediee a l'instance supervision, distincte de celle de app/staging
# (app/terraform/instances/keypair.tf) : reutiliser la meme cle couplerait
# le cycle de vie de la supervision a celui des instances qu'elle surveille,
# ce qu'on cherche justement a eviter.
resource "tls_private_key" "supervision" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "supervision" {
  key_name   = "${var.project_name}-supervision-key"
  public_key = tls_private_key.supervision.public_key_openssh

  tags = {
    Name    = "${var.project_name}-supervision-key"
    Project = var.project_name
  }
}
