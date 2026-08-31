# Ghostblog — Projet de certification ASD (DevOps)

Déploiement d'un blog **Ghost CMS** sur AWS, piloté de bout en bout via un pipeline **GitLab CI/CD** (Terraform pour l'infrastructure, Docker pour l'application). Projet réalisé dans le cadre de la certification **Administrateur Système DevOps (ASD, niveau 6, RNCP36061)**.

## Architecture

- **Instance applicative unique** (AWS EC2 + Elastic IP) hébergeant Ghost via Docker Compose (MySQL 8.0 + Ghost).
- **Environnements preprod / prod classiques**: deux instances EC2 distinctes prévues via le même module Terraform réutilisable (`app/terraform/modules/ec2-instance`) — à ce stade, seule l'instance de production est provisionnée.
  - `ghost.lacera.fr` → production
  - `preprod.lacera.fr` → préproduction (à venir)
- **Instance de supervision séparée** (Prometheus/Grafana, à venir) dans le domaine `supervision/`.
- DNS géré chez OVH.

## Structure du dépôt

- `app/` : stack applicative (`docker-compose.yml`, `dockerfile`) et infrastructure Terraform (`app/terraform/`) de l'instance app.
- `supervision/` : infrastructure et configuration de la stack de supervision (en cours).
- `.gitlab-ci.yml` : pipeline CI/CD (validation et déploiement Terraform, build de l'image Ghost).

## Git Workflow : Trunk-Based Development

- **Trunk unique (`main`)**, pas de branches `develop`/`release`.
- Branches de fonctionnalités courtes (`feature/<nom>`), une Merge Request par contribution.

## Démarrage rapide (local)

Prérequis : Docker Engine + Docker Compose.

```bash
cd app
cp .env.example .env   # renseigner les secrets locaux
docker compose up -d --build
```

- Blog : http://localhost:8090
- Administration : http://localhost:8090/ghost

## Infrastructure (Terraform)

```bash
cd app/terraform
terraform init
terraform plan
terraform apply
```

Le backend d'état Terraform est géré par GitLab (`backend "http"`), initialisé dynamiquement par le pipeline CI/CD. La clé SSH de l'instance est générée par Terraform (`tls_private_key`) et exposée en sortie sensible.

## Sécurité

- Aucun secret n'est commité dans le dépôt (`.env`, clés, tokens sont dans `.gitignore`).
- Les credentials AWS et variables sensibles sont gérées via les **variables CI/CD GitLab** (masquées).

## Stack technique

- **CMS** : Ghost 6 (image `ghost:6-alpine`)
- **Base de données** : MySQL 8.0
- **Conteneurisation** : Docker / Docker Compose
- **Infrastructure as Code** : Terraform
- **Cloud** : AWS (EC2, EIP, VPC)
- **CI/CD** : GitLab CI/CD & GitLab Container Registry
