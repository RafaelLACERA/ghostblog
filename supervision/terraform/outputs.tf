output "supervision_instance_id" {
  description = "ID de l'instance de supervision"
  value       = module.supervision_instance.instance_id
}

output "supervision_public_ip" {
  description = "IP publique fixe (Elastic IP) de l'instance de supervision, pour accéder à Grafana"
  value       = module.supervision_instance.public_ip
}

output "supervision_private_ip" {
  description = "IP privée de l'instance de supervision. À utiliser pour la variable GitLab CI/CD SUPERVISION_IP_CIDR (le trafic de scrape passe par le réseau privé du VPC, pas par l'IP publique)"
  value       = module.supervision_instance.private_ip
}

output "supervision_ssh_private_key" {
  description = "Clé privée SSH générée pour l'instance de supervision. Lue directement depuis ce state par le job de déploiement, jamais copiée ailleurs."
  value       = tls_private_key.supervision.private_key_pem
  sensitive   = true
}
