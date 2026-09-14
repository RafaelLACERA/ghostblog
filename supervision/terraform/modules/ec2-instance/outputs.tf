output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "IP publique fixe (Elastic IP) de l'instance"
  value       = aws_eip.this.public_ip
}

output "private_ip" {
  description = "IP privée de l'instance"
  value       = aws_instance.this.private_ip
}
