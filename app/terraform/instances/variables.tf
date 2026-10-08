variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type_app" {
  description = "Type d'instance pour le serveur applicatif Ghost (production)"
  type        = string
  default     = "t3.small"
}

# Meme type que la prod : preproduction conforme a la production
variable "instance_type_staging" {
  description = "Type d'instance pour le serveur applicatif Ghost (staging)"
  type        = string
  default     = "t3.small"
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
