variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Nom du projet, utilisé pour le tagging des ressources"
  type        = string
  default     = "ghostblog"
}

variable "supervision_ip_cidr" {
  description = "IP publique/privée de l'instance supervision, autorisée à scraper node_exporter"
  type        = string
}
