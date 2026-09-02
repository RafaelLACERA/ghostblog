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
