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

# Recuperee par un lookup souple cote CI (curl+jq sur l'API du state
# "supervision", voir .gitlab-ci.yml job deploy_dns), pas via
# terraform_remote_state : ce dernier echoue durement ("Unable to find
# remote state") si le state cible n'a jamais ete applique une seule fois -
# un cas reel ici puisque deploy_supervision peut ne jamais avoir reussi.
# Chaine vide par defaut = pas d'enregistrement DNS cree (voir records.tf).
variable "supervision_public_ip" {
  description = "IP publique de l'instance de supervision, vide si elle n'existe pas encore"
  type        = string
  default     = ""
}
