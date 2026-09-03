variable "name" {
  description = "Nom de l'instance, utilisé pour le tagging des ressources"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
}

variable "ami_id" {
  description = "ID de l'AMI à utiliser. Si vide, la dernière AMI Ubuntu 26.04 LTS (Canonical) est utilisée automatiquement"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "ID du subnet dans lequel déployer l'instance"
  type        = string
}

variable "security_group_ids" {
  description = "Liste des security groups à attacher à l'instance"
  type        = list(string)
}

variable "key_name" {
  description = "Nom de la key pair AWS à utiliser pour l'accès SSH"
  type        = string
}

variable "project_name" {
  description = "Nom du projet, utilisé pour le tagging des ressources"
  type        = string
}

variable "iam_instance_profile" {
  description = "Nom du profil IAM a attacher a l'instance (acces S3)"
  type        = string
}
