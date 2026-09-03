# Ghostblog — Projet de certification ASD (DevOps)

Déploiement d'un blog **Ghost CMS** sur AWS, piloté de bout en bout via un pipeline **GitLab CI/CD** (Terraform pour l'infrastructure, Ansible + Docker pour l'application). Projet réalisé dans le cadre de la certification **Administrateur Système DevOps (ASD, niveau 6, RNCP36061)**.

Contrainte forte du projet : le jour de la soutenance, aucun poste personnel n'est disponible. Tout le cycle de vie de l'infrastructure (création, déploiement, destruction) doit donc être pilotable depuis un simple navigateur, via les boutons manuels du pipeline GitLab.

## Architecture

- **Deux instances EC2** (+ Elastic IP), une par environnement (`app` = production, `staging`), provisionnées via le même module Terraform réutilisable (`app/terraform/instances/modules/ec2-instance`), même security group et même clé SSH — l'environnement de staging reste conforme à la prod.
- **Deux bases RDS MySQL 8.0** séparées (une par environnement) : tester sur staging ne touche jamais aux données de prod.
- **Deux buckets S3** séparés (un par environnement) pour les médias Ghost (images uploadées, thèmes) via l'adaptateur `ghost-storage-adapter-s3` — sans ça, les uploads seraient perdus à chaque recréation des EC2 (contrairement à RDS, un volume Docker local ne survit pas à `destroy_app_infra`). Chaque instance accède à son bucket via un rôle IAM dédié (pas de clé AWS statique dans le conteneur).
- **Trois states Terraform à cycles de vie distincts**, regroupés sous `app/terraform/` :
  - `persistent/` : couche persistante (VPC, subnets, security group, RDS) — jamais détruite par les cycles de test des EC2.
  - `instances/` : instances EC2 prod/staging, jetables et recréées à chaque cycle de test, lisant le réseau via `terraform_remote_state`.
  - `dns/` : enregistrements DNS OVH (`ghost.lacera.fr` / `ghost-staging.lacera.fr`), pointés vers les Elastic IP des instances — lit le state `instances` à distance, indépendant du cycle de vie des EC2 (survit à leur destruction/recréation).
- **Nginx (reverse proxy) + Certbot (HTTPS via Let's Encrypt)** sur chaque instance, configurés par le rôle Ansible `nginx` — le domaine attendu est dérivé de la variable `GHOST_URL_APP`/`GHOST_URL_STAGING` (voir section Variables CI/CD).
- **Instance de supervision séparée** (Prometheus/Grafana, à venir) dans le domaine `supervision/`.

## Structure du dépôt

- `app/` :
  - `docker-compose.yml`, `dockerfile` : stack applicative Ghost (l'image se connecte à une base RDS externe, pas de MySQL en conteneur).
  - `ansible/` : rôles `hardening` (pare-feu, durcissement SSH), `docker` (installation Docker Engine), `ghost_app` (déploiement du conteneur Ghost), `nginx` (reverse proxy + Certbot/HTTPS).
  - `terraform/persistent/`, `terraform/instances/`, `terraform/dns/` : voir Architecture ci-dessus.
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
| `deploy_data` | Crée/met à jour VPC, subnets, security group, RDS (`app/terraform/persistent`) |
| `deploy_app_infra` | Crée/met à jour les EC2 prod + staging (`app/terraform/instances`) |
| `deploy_dns` | Crée/met à jour les enregistrements DNS OVH (`app/terraform/dns`), doit être lancé après `deploy_app_infra` |
| `deliver_staging` | Déploie l'image Ghost + Nginx/Certbot sur staging via Ansible (automatique sur push si les fichiers pertinents changent) |
| `deploy_prod` | Promotion manuelle du même tag d'image vers la prod (+ Nginx/Certbot) |
| `destroy_app_infra` | Détruit les EC2 (doit être lancé avant `destroy_data`) |
| `destroy_data` | Détruit VPC/subnets/security group/RDS — bloqué automatiquement tant que des EC2 existent encore |
| `destroy_dns` | Détruit les enregistrements DNS OVH |

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
| `GHOST_URL_APP` | URL publique de la prod (`https://ghost.lacera.fr`), transmise à Ghost (`url` config) et utilisée par le rôle `nginx` pour dériver le domaine du certificat Certbot | Non* | Non |
| `GHOST_URL_STAGING` | URL publique du staging (`https://ghost-staging.lacera.fr`) | Non* | Non |
| `OVH_ENDPOINT` | Endpoint API OVH (`ovh-eu`) | Non* | Non |
| `OVH_APPLICATION_KEY` | Identifiant d'application OVH | Non* | Oui |
| `OVH_APPLICATION_SECRET` | Secret d'application OVH | Non* | Oui |
| `OVH_CONSUMER_KEY` | Clé consommateur OVH | Non* | Oui |

*Non protégées volontairement : les jobs `deploy_*`/`destroy_*` tournent aussi sur les pipelines de Merge Request (branches non protégées), pas seulement sur `main`.

`GHOST_URL_APP`/`GHOST_URL_STAGING` doivent toujours avoir une valeur valide (jamais vide) : une variable vide écraserait le défaut du rôle Ansible par une chaîne vide, et casserait la demande de certificat Certbot (domaine invalide).

Les identifiants OVH (`OVH_APPLICATION_KEY`/`SECRET`/`OVH_CONSUMER_KEY`) se génèrent via https://api.ovh.com/createToken/, à restreindre idéalement aux chemins `/domain/zone/lacera.fr/*` (principe du moindre privilège).

Le token GitLab (`CI_JOB_TOKEN`) et les credentials du Container Registry (`CI_REGISTRY*`) sont fournis automatiquement par GitLab, aucune configuration nécessaire.

## Bootstrap DNS/HTTPS (une seule fois)

L'ordre est important la première fois qu'on démarre une infra à partir de zéro (Certbot a besoin que le domaine résolve déjà vers l'instance pour valider son certificat) :

1. `deploy_app_infra` (les EC2 doivent exister pour avoir une IP à pointer).
2. `deploy_dns` — crée les enregistrements A vers les Elastic IP.
3. Vérifier la propagation : `dig +short ghost.lacera.fr` / `dig +short ghost-staging.lacera.fr` doivent renvoyer les bonnes IP.
4. `deliver_staging`/`deploy_prod` — le rôle `nginx` installe le reverse proxy et obtient le certificat HTTPS, maintenant que le domaine résout correctement.

Si l'IP change (recréation des EC2 après un `destroy_app_infra`), relancer `deploy_dns` pour repointer le DNS avant de redéployer l'appli.

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
- Accès S3 via rôle IAM d'instance (pas de clé d'accès AWS statique dans le conteneur Ghost) — chaque rôle est scopé à son seul bucket.

## Stack technique

- **CMS** : Ghost 6 (image `ghost:6-alpine`)
- **Base de données** : MySQL 8.0 (Amazon RDS)
- **Conteneurisation** : Docker / Docker Compose
- **Infrastructure as Code** : Terraform (providers AWS + OVH)
- **Configuration** : Ansible
- **Cloud** : AWS (EC2, EIP, VPC, RDS, S3, IAM)
- **DNS** : OVH (`lacera.fr`)
- **Reverse proxy / HTTPS** : Nginx + Certbot (Let's Encrypt)
- **CI/CD** : GitLab CI/CD & GitLab Container Registry
