output "app_instance_id" {
  description = "ID de l'instance applicative Ghost"
  value       = module.app_instance.instance_id
}

output "app_public_ip" {
  description = "IP publique fixe (Elastic IP) de l'instance applicative, à pointer via le DNS OVH"
  value       = module.app_instance.public_ip
}

output "app_private_ip" {
  description = "IP privée de l'instance applicative"
  value       = module.app_instance.private_ip
}

output "app_ssh_private_key" {
  description = "Clé privée SSH générée pour l'instance applicative. À copier une seule fois dans une variable GitLab CI/CD masquée/protégée, puis à ne plus jamais afficher en clair."
  value       = tls_private_key.app.private_key_pem
  sensitive   = true
}

output "staging_instance_id" {
  description = "ID de l'instance de staging Ghost"
  value       = module.staging_instance.instance_id
}

output "staging_public_ip" {
  description = "IP publique fixe (Elastic IP) de l'instance de staging, à pointer via le DNS OVH"
  value       = module.staging_instance.public_ip
}

output "staging_private_ip" {
  description = "IP privée de l'instance de staging"
  value       = module.staging_instance.private_ip
}

# Relais des sorties RDS depuis le state persistant app-data : configure_app
# (Ansible) ne lit que le state "app", ces outputs evitent d'avoir a
# s'authentifier une deuxieme fois contre app-data depuis la CI.

output "app_db_host" {
  description = "Adresse DNS de la base de production"
  value       = data.terraform_remote_state.data.outputs.app_db_host
}

output "app_db_port" {
  description = "Port de la base de production"
  value       = data.terraform_remote_state.data.outputs.app_db_port
}

output "app_db_name" {
  description = "Nom de la base de production"
  value       = data.terraform_remote_state.data.outputs.app_db_name
}

output "app_db_user" {
  description = "Utilisateur de la base de production"
  value       = data.terraform_remote_state.data.outputs.app_db_username
}

output "app_db_password" {
  description = "Mot de passe de la base de production"
  value       = data.terraform_remote_state.data.outputs.app_db_password
  sensitive   = true
}

output "staging_db_host" {
  description = "Adresse DNS de la base de staging"
  value       = data.terraform_remote_state.data.outputs.staging_db_host
}

output "staging_db_port" {
  description = "Port de la base de staging"
  value       = data.terraform_remote_state.data.outputs.staging_db_port
}

output "staging_db_name" {
  description = "Nom de la base de staging"
  value       = data.terraform_remote_state.data.outputs.staging_db_name
}

output "staging_db_user" {
  description = "Utilisateur de la base de staging"
  value       = data.terraform_remote_state.data.outputs.staging_db_username
}

output "staging_db_password" {
  description = "Mot de passe de la base de staging"
  value       = data.terraform_remote_state.data.outputs.staging_db_password
  sensitive   = true
}

output "app_s3_bucket" {
  description = "Bucket S3 des medias de production"
  value       = data.terraform_remote_state.data.outputs.app_s3_bucket_name
}

output "staging_s3_bucket" {
  description = "Bucket S3 des medias de staging"
  value       = data.terraform_remote_state.data.outputs.staging_s3_bucket_name
}
