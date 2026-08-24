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
