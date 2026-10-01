module "supervision_instance" {
  source = "./modules/ec2-instance"

  name               = "${var.project_name}-supervision"
  instance_type      = var.instance_type_supervision
  subnet_id          = data.terraform_remote_state.data.outputs.public_subnet_id
  security_group_ids = [data.terraform_remote_state.data.outputs.supervision_security_group_id]
  key_name           = aws_key_pair.supervision.key_name
  project_name       = var.project_name
  root_volume_size   = var.root_volume_size_supervision
  # Pas de profil IAM : l'instance ne fait que scraper le reseau
}
