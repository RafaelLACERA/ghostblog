module "app_instance" {
  source = "./modules/ec2-instance"

  name               = "${var.project_name}-app"
  instance_type      = var.instance_type_app
  subnet_id          = aws_subnet.public.id
  security_group_ids = [aws_security_group.app.id]
  key_name           = aws_key_pair.app.key_name
  project_name       = var.project_name
}
