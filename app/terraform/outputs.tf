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

output "preprod_instance_id" {
  description = "ID de l'instance de préproduction Ghost"
  value       = module.preprod_instance.instance_id
}

output "preprod_public_ip" {
  description = "IP publique fixe (Elastic IP) de l'instance de préproduction, à pointer via le DNS OVH"
  value       = module.preprod_instance.public_ip
}

output "preprod_private_ip" {
  description = "IP privée de l'instance de préproduction"
  value       = module.preprod_instance.private_ip
}
