# Ghostblog — Projet de certification ASD (DevOps)

Déploiement d'un blog **Ghost CMS** sur AWS, piloté de bout en bout via un pipeline **GitLab CI/CD** (Terraform pour l'infrastructure, Ansible + Docker pour l'application). Projet réalisé dans le cadre de la certification **Administrateur Système DevOps (ASD, niveau 6, RNCP36061)**.

Contrainte forte du projet : le jour de la soutenance, aucun poste personnel n'est disponible. Tout le cycle de vie de l'infrastructure (création, déploiement, destruction) doit donc être pilotable depuis un simple navigateur, via les boutons manuels du pipeline GitLab.

## Architecture

- **Deux instances EC2** (+ Elastic IP), une par environnement (`app` = production, `staging`), provisionnées via le même module Terraform réutilisable (`app/terraform/modules/ec2-instance`), même security group et même clé SSH — l'environnement de staging reste conforme à la prod.
- **Deux bases RDS MySQL 8.0** séparées (une par environnement) : tester sur staging ne touche jamais aux données de prod.
- **Deux states Terraform à cycles de vie distincts** :
  - `app/terraform-data/` : couche persistante (VPC, subnets, security group, RDS) — jamais détruite par les cycles de test des EC2.
  - `app/terraform/` : instances EC2 prod/staging, jetables et recréées à chaque cycle de test, lisant le réseau via `terraform_remote_state`.
- **Instance de supervision séparée** (Prometheus/Grafana, à venir) dans le domaine `supervision/`.
- DNS à venir chez OVH (`ghost.lacera.fr` / `staging.lacera.fr`).

## Structure du dépôt

- `app/` :
  - `docker-compose.yml`, `dockerfile` : stack applicative Ghost (l'image se connecte à une base RDS externe, pas de MySQL en conteneur).
  - `ansible/` : rôles `hardening` (pare-feu, durcissement SSH), `docker` (installation Docker Engine), `ghost_app` (déploiement du conteneur Ghost).
  - `terraform-data/`, `terraform/` : voir Architecture ci-dessus.
- `supervision/` : infrastructure et configuration de la stack de supervision (pas encore commencé).
- `.gitlab-ci.yml` : pipeline CI/CD, voir section dédiée ci-dessous.

## Git Workflow : Trunk-Based Development

- **Trunk unique (`main`)**, protégé (pas de push direct, pas de force-push), pas de branches `develop`/`release`.
- Branches de fonctionnalités courtes (`feature/`, `fix/`, `chore/`, `docs/...`), une Merge Request par contribution.

## Pipeline CI/CD

Stages : `build` (image Docker) → `test` (lint, scans) → `provisioning` (Terraform) → `deploy` (Ansible) → `destroy` (Terraform).

Jobs manuels principaux :

| Job | Rôle |
|---|---|
| `deploy_data` | Crée/met à jour VPC, subnets, security group, RDS (`app/terraform-data`) |
| `deploy_app_infra` | Crée/met à jour les EC2 prod + staging (`app/terraform`) |
| `deliver_staging` | Déploie l'image Ghost sur staging via Ansible (automatique sur push si les fichiers pertinents changent) |
| `deploy_prod` | Promotion manuelle du même tag d'image vers la prod |
| `destroy_app_infra` | Détruit les EC2 (doit être lancé avant `destroy_data`) |
| `destroy_data` | Détruit VPC/subnets/security group/RDS — bloqué automatiquement tant que des EC2 existent encore |

Ces boutons apparaissent selon deux logiques, qui coexistent :

- **Sur une Merge Request** : automatiquement, si le diff touche les fichiers concernés (vrai fonctionnement GitOps).
- **Depuis "Run pipeline"** (CI/CD → Pipelines → Run pipeline, sur `main`) : toujours disponibles, quel que soit le diff — c'est le mode utilisé pour la démonstration/soutenance, accessible depuis un simple navigateur.

Dans les deux cas, rien ne s'exécute sans un clic explicite sur le bouton du job.

## Variables CI/CD requises

À définir dans **Settings → CI/CD → Variables** :

| Variable | Rôle | Protected | Masked |
|---|---|---|---|
| `AWS_ACCESS_KEY_ID` | Authentification AWS (IAM dédié au projet) | Non* | Oui |
| `AWS_SECRET_ACCESS_KEY` | Authentification AWS | Non* | Oui |
| `AWS_DEFAULT_REGION` | Région AWS (`eu-west-3`) | Non* | Non |
| `SUPERVISION_IP_CIDR` | IP autorisée à scraper `node_exporter` (port 9100) | Non* | Non |
| `GHOST_URL_APP` | URL publique de la prod, transmise à Ghost (`url` config) | Non* | Non |
| `GHOST_URL_STAGING` | URL publique du staging | Non* | Non |

*Non protégées volontairement : les jobs `deploy_*`/`destroy_*` tournent aussi sur les pipelines de Merge Request (branches non protégées), pas seulement sur `main`.

`GHOST_URL_APP`/`GHOST_URL_STAGING` doivent toujours avoir une valeur (ex: `http://localhost:8090` en attendant le DNS) : une variable vide écraserait le défaut du rôle Ansible par une chaîne vide.

Le token GitLab (`CI_JOB_TOKEN`) et les credentials du Container Registry (`CI_REGISTRY*`) sont fournis automatiquement par GitLab, aucune configuration nécessaire.

## Démarrage rapide (local)

Prérequis : Docker Engine + Docker Compose, et une base MySQL accessible (RDS en prod/staging ; en local, n'importe quel MySQL joignable via `DB_HOST`).

```bash
cd app
cp .env.example .env   # renseigner DB_HOST/DB_USER/DB_PASSWORD/DB_NAME et les secrets locaux
docker compose up -d --build
```

- Blog : http://localhost:8090
- Administration : http://localhost:8090/ghost

## Sécurité

- Aucun secret n'est commité dans le dépôt (`.env`, clés, tokens sont dans `.gitignore`).
- Les credentials AWS et variables sensibles sont gérées via les **variables CI/CD GitLab** (masquées).
- La clé SSH des instances est générée par Terraform (`tls_private_key`) et lue directement depuis le state dans le job de déploiement — elle ne quitte jamais le système de fichiers éphémère du job (pas d'artifact GitLab téléchargeable).

## Stack technique

- **CMS** : Ghost 6 (image `ghost:6-alpine`)
- **Base de données** : MySQL 8.0 (Amazon RDS)
- **Conteneurisation** : Docker / Docker Compose
- **Infrastructure as Code** : Terraform
- **Configuration** : Ansible
- **Cloud** : AWS (EC2, EIP, VPC, RDS)
- **CI/CD** : GitLab CI/CD & GitLab Container Registry
