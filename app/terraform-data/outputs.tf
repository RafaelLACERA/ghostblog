output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID du subnet public (instances EC2 app/staging)"
  value       = aws_subnet.public.id
}

output "secondary_subnet_id" {
  description = "ID du deuxieme subnet (utilise uniquement pour le DB subnet group RDS)"
  value       = aws_subnet.secondary.id
}

output "app_security_group_id" {
  description = "ID du security group partage par les instances Ghost prod et staging"
  value       = aws_security_group.app.id
}

output "app_db_endpoint" {
  description = "Endpoint RDS de la base de production (host:port)"
  value       = aws_db_instance.app.endpoint
}

output "app_db_username" {
  description = "Utilisateur de la base de production"
  value       = aws_db_instance.app.username
}

output "app_db_password" {
  description = "Mot de passe de la base de production"
  value       = random_password.app_db.result
  sensitive   = true
}

output "app_db_name" {
  description = "Nom de la base de production"
  value       = aws_db_instance.app.db_name
}

output "staging_db_endpoint" {
  description = "Endpoint RDS de la base de staging"
  value       = aws_db_instance.staging.endpoint
}

output "staging_db_username" {
  description = "Utilisateur de la base de staging"
  value       = aws_db_instance.staging.username
}

output "staging_db_password" {
  description = "Mot de passe de la base de staging"
  value       = random_password.staging_db.result
  sensitive   = true
}

output "staging_db_name" {
  description = "Nom de la base de staging"
  value       = aws_db_instance.staging.db_name
}
