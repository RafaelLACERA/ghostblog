# Stockage des medias Ghost (images uploadees, themes) - un bucket par
# environnement, jamais partage entre prod et staging, meme principe que
# les bases RDS. Necessaire ici (pas dans "instances") car ce bucket doit
# survivre aux cycles de destruction/recreation des EC2 de test.

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "app" {
  bucket = "${var.project_name}-app-content-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${var.project_name}-app-content"
    Project = var.project_name
  }
}

resource "aws_s3_bucket" "staging" {
  bucket = "${var.project_name}-staging-content-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${var.project_name}-staging-content"
    Project = var.project_name
  }
}

# L'adaptateur de stockage Ghost (ghost-storage-adapter-s3) pose une ACL
# "public-read" sur chaque image uploadee (normal pour des images de blog,
# censees etre publiques) - AWS bloque ca par defaut depuis quelques annees,
# il faut explicitement l'autoriser sur ces deux buckets precis.
resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_public_access_block" "staging" {
  bucket = aws_s3_bucket.staging.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_ownership_controls" "staging" {
  bucket = aws_s3_bucket.staging.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
