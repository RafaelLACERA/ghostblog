variable "project_name" {
  description = "Nom du projet, utilisé pour le tagging des ressources"
  type        = string
  default     = "ghostblog"
}

variable "dns_zone" {
  description = "Zone DNS OVH dans laquelle creer les enregistrements"
  type        = string
  default     = "lacera.fr"
}

variable "gitlab_api_url" {
  description = "URL de base de l'API GitLab, pour lire le state distant app"
  type        = string
}

variable "gitlab_project_id" {
  description = "ID du projet GitLab, pour lire le state distant app"
  type        = string
}

variable "gitlab_ci_job_token" {
  description = "Token d'authentification pour lire le state distant app"
  type        = string
  sensitive   = true
}
