terraform {
  required_version = ">= 1.5"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.44"
    }
  }

  backend "http" {
  }
}

# Le provider lit OVH_ENDPOINT/OVH_APPLICATION_KEY/OVH_APPLICATION_SECRET/
# OVH_CONSUMER_KEY directement depuis l'environnement (variables CI/CD
# GitLab, meme principe que le provider AWS qui lit deja ses credentials
# de cette facon) : rien a cabler ici.
provider "ovh" {}
