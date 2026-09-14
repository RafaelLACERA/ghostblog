module "supervision_instance" {
  source = "./modules/ec2-instance"

  name               = "${var.project_name}-supervision"
  instance_type      = var.instance_type_supervision
  subnet_id          = data.terraform_remote_state.data.outputs.public_subnet_id
  security_group_ids = [data.terraform_remote_state.data.outputs.supervision_security_group_id]
  key_name           = aws_key_pair.supervision.key_name
  project_name       = var.project_name
  # iam_instance_profile omis : aucun acces AWS necessaire, l'instance ne
  # fait que scraper node_exporter sur le reseau (voir modules/ec2-instance/variables.tf).
}
