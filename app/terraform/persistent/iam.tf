# Un role IAM par environnement (pas partage) : l'instance app ne peut
# toucher qu'au bucket app, l'instance staging qu'au bucket staging.
# Permet a l'adaptateur de stockage Ghost (dans le conteneur) d'utiliser
# la chaine de credentials par defaut du SDK AWS (role d'instance EC2),
# sans jamais avoir besoin d'une cle d'acces AWS statique dans le conteneur.

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_storage" {
  name               = "${var.project_name}-app-storage"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name    = "${var.project_name}-app-storage"
    Project = var.project_name
  }
}

resource "aws_iam_role" "staging_storage" {
  name               = "${var.project_name}-staging-storage"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name    = "${var.project_name}-staging-storage"
    Project = var.project_name
  }
}

data "aws_iam_policy_document" "app_storage" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.app.arn]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl",
    ]
    resources = ["${aws_s3_bucket.app.arn}/*"]
  }
}

data "aws_iam_policy_document" "staging_storage" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.staging.arn]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl",
    ]
    resources = ["${aws_s3_bucket.staging.arn}/*"]
  }
}

resource "aws_iam_role_policy" "app_storage" {
  name   = "${var.project_name}-app-storage"
  role   = aws_iam_role.app_storage.id
  policy = data.aws_iam_policy_document.app_storage.json
}

resource "aws_iam_role_policy" "staging_storage" {
  name   = "${var.project_name}-staging-storage"
  role   = aws_iam_role.staging_storage.id
  policy = data.aws_iam_policy_document.staging_storage.json
}

resource "aws_iam_instance_profile" "app_storage" {
  name = "${var.project_name}-app-storage"
  role = aws_iam_role.app_storage.name
}

resource "aws_iam_instance_profile" "staging_storage" {
  name = "${var.project_name}-staging-storage"
  role = aws_iam_role.staging_storage.name
}
