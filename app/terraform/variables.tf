variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type_app" {
  description = "Type d'instance pour le serveur applicatif (Ghost blue/green)"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_monitoring" {
  description = "Type d'instance pour le serveur de supervision (Zabbix)"
  type        = string
  default     = "t3.micro"
}

variable "project_name" {
  description = "Nom du projet, utilisé pour le tagging des ressources"
  type        = string
  default     = "ghostblog"
}

variable "admin_ip_cidr" {
  description = "IP publique autorisée pour SSH (format CIDR, ex: 1.2.3.4/32)"
  type        = string
}

variable "supervision_ip_cidr" {
  description = "IP publique/privée de l'instance supervision, autorisée à scraper node_exporter"
  type        = string
}