module "app_instance" {
  source = "./modules/ec2-instance"

  name                 = "${var.project_name}-app"
  instance_type        = var.instance_type_app
  subnet_id            = data.terraform_remote_state.data.outputs.public_subnet_id
  security_group_ids   = [data.terraform_remote_state.data.outputs.app_security_group_id]
  key_name             = aws_key_pair.app.key_name
  project_name         = var.project_name
  iam_instance_profile = data.terraform_remote_state.data.outputs.app_iam_instance_profile_name
}

# Meme security group et meme cle SSH que la production : l'environnement
# de staging doit rester conforme a la prod (critere du referentiel ASD).
module "staging_instance" {
  source = "./modules/ec2-instance"

  name                 = "${var.project_name}-staging"
  instance_type        = var.instance_type_staging
  subnet_id            = data.terraform_remote_state.data.outputs.public_subnet_id
  security_group_ids   = [data.terraform_remote_state.data.outputs.app_security_group_id]
  key_name             = aws_key_pair.app.key_name
  project_name         = var.project_name
  iam_instance_profile = data.terraform_remote_state.data.outputs.staging_iam_instance_profile_name
}
