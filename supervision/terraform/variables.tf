variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

# t3.small : memoire mesuree a 84 % en t3.micro avec Grafana 13 (01/10)
variable "instance_type_supervision" {
  description = "Type d'instance pour Prometheus/Grafana"
  type        = string
  default     = "t3.small"
}

# 15 Go : disque mesure a 80 % sur 8 Go avec les images Grafana 13 et Prometheus v3.15 (01/10)
variable "root_volume_size_supervision" {
  description = "Taille du disque racine de l'instance de supervision en Go"
  type        = number
  default     = 15
}

variable "project_name" {
  description = "Nom du projet, utilisé pour le tagging des ressources"
  type        = string
  default     = "ghostblog"
}

variable "gitlab_api_url" {
  description = "URL de base de l'API GitLab, pour lire le state distant app-data"
  type        = string
}

variable "gitlab_project_id" {
  description = "ID du projet GitLab, pour lire le state distant app-data"
  type        = string
}

variable "gitlab_ci_job_token" {
  description = "Token d'authentification pour lire le state distant app-data"
  type        = string
  sensitive   = true
}

variable "dns_zone" {
  description = "Zone DNS OVH des enregistrements"
  type        = string
  default     = "lacera.fr"
}
