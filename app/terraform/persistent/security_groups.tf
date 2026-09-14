# Complete par le role Ansible "hardening" (UFW + sshd_config) au niveau OS.
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group partage par les instances Ghost prod et staging (Nginx)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP depuis internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS depuis internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (authentification par cle uniquement)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "node_exporter - accessible uniquement depuis instance supervision"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.supervision_ip_cidr]
  }

  egress {
    description = "Tout le trafic sortant autorise"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-app-sg"
    Project = var.project_name
  }
}

# Instance de supervision (Prometheus/Grafana) : Grafana expose son UI web,
# SSH pour l'administration. Pas de regle 9100 ici : c'est l'instance
# supervision qui scrape *sortant* vers app/staging, jamais l'inverse (voir
# la regle 9100 sur le SG "app" ci-dessus).
resource "aws_security_group" "supervision" {
  name        = "${var.project_name}-supervision-sg"
  description = "Security group de l'instance de supervision (Prometheus/Grafana)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH (authentification par cle uniquement)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ouvert au monde : impossible de connaitre a l'avance l'IP depuis
  # laquelle Grafana sera consulte le jour de la soutenance (poste
  # impose sur place, reseau inconnu). Protection = mot de passe Grafana.
  ingress {
    description = "Grafana - interface web"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Tout le trafic sortant autorise (scrape node_exporter sur app/staging)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-supervision-sg"
    Project = var.project_name
  }
}
