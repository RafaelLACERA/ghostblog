terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.44"
    }
  }

  backend "http" {
  }
}

provider "aws" {
  region = var.aws_region
}

# Identifiants lus dans les variables CI/CD OVH_*
provider "ovh" {}
