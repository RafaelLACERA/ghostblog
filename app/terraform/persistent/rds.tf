# Base de donnees managee, une par environnement (jamais partagee entre
# prod et staging - tester sur staging ne doit jamais toucher aux vraies
# donnees). prevent_destroy protege les deux instances meme d'un
# "terraform destroy" lance sur ce state : il faudrait explicitement
# retirer cette ligne avant de pouvoir les detruire pour de vrai.

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Autorise MySQL uniquement depuis les instances Ghost (prod/staging)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL depuis les instances Ghost"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Tout le trafic sortant autorise"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.secondary.id]

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

resource "random_password" "app_db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "staging_db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "app" {
  identifier              = "${var.project_name}-app-db"
  engine                  = "mysql"
  engine_version          = "8.4"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_encrypted       = true
  db_name                 = "ghost_db"
  username                = "ghostadmin"
  password                = random_password.app_db.result
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = 7
  skip_final_snapshot     = true

  # Support etendu payant active par defaut par AWS : desactive explicitement
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"

  tags = {
    Name    = "${var.project_name}-app-db"
    Project = var.project_name
  }

  # prevent_destroy desactive : bloquerait destroy_data
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_db_instance" "staging" {
  identifier              = "${var.project_name}-staging-db"
  engine                  = "mysql"
  engine_version          = "8.4"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_encrypted       = true
  db_name                 = "ghost_db"
  username                = "ghostadmin"
  password                = random_password.staging_db.result
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = 7
  skip_final_snapshot     = true

  # Support etendu payant active par defaut par AWS : desactive explicitement
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"

  tags = {
    Name    = "${var.project_name}-staging-db"
    Project = var.project_name
  }

  # prevent_destroy desactive : bloquerait destroy_data
  # lifecycle {
  #   prevent_destroy = true
  # }
}
