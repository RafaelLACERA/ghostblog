# Ghostblog — Projet de certification ASD (DevOps)

Déploiement d'un blog **Ghost CMS** sur AWS, piloté de bout en bout via un pipeline **GitLab CI/CD** (Terraform pour l'infrastructure, Ansible + Docker pour l'application). Projet réalisé dans le cadre de la certification **Administrateur Système DevOps (ASD, niveau 6, RNCP36061)**.

Contrainte forte du projet : le jour de la soutenance, aucun poste personnel n'est disponible. Tout le cycle de vie de l'infrastructure (création, déploiement, destruction) doit donc être pilotable depuis un simple navigateur, via les boutons manuels du pipeline GitLab.

## Architecture

- **Deux instances EC2** (+ Elastic IP), une par environnement (`app` = production, `staging`), provisionnées via le même module Terraform réutilisable (`app/terraform/instances/modules/ec2-instance`), même security group et même clé SSH — l'environnement de staging reste conforme à la prod.
- **Deux bases RDS MySQL 8.4** séparées (une par environnement) : tester sur staging ne touche jamais aux données de prod. Le support étendu payant d'AWS est explicitement désactivé (`engine_lifecycle_support`).
- **Deux buckets S3** séparés (un par environnement) pour les médias Ghost (images uploadées, thèmes) via l'adaptateur `ghost-storage-adapter-s3` — sans ça, les uploads seraient perdus à chaque recréation des EC2 (contrairement à RDS, un volume Docker local ne survit pas à `destroy_app_infra`). Chaque instance accède à son bucket via un rôle IAM dédié (pas de clé AWS statique dans le conteneur).
- **Quatre states Terraform à cycles de vie distincts**, chacun indépendant :
  - `app/terraform/persistent/` (state `app-data`) : couche persistante (VPC, subnets, security groups, RDS, S3, IAM) — jamais détruite par les cycles de test des EC2.
  - `app/terraform/instances/` (state `app`) : instances EC2 prod/staging, jetables et recréées à chaque cycle de test, lisant le réseau via `terraform_remote_state`.
  - `app/terraform/dns/` (state `app-dns`) : enregistrements DNS OVH (`ghost.lacera.fr` / `ghost-staging.lacera.fr` / `ghost-monitoring.lacera.fr`), pointés vers les Elastic IP correspondantes — indépendant du cycle de vie des EC2 qu'il pointe.
  - `supervision/terraform/` (state `supervision`) : instance EC2 dédiée à la supervision (Prometheus + Grafana), cycle de vie totalement indépendant des instances Ghost — elle continue de fonctionner (et de les observer, y compris comme `DOWN`) pendant un `destroy_app_infra`/`deploy_app_infra` de test.
- **Nginx (reverse proxy) + Certbot (HTTPS via Let's Encrypt)** sur chaque instance (app, staging, et supervision), configurés par un rôle Ansible `nginx` — le domaine attendu est dérivé de `GHOST_URL_APP`/`GHOST_URL_STAGING` pour Ghost, de `MONITORING_DOMAIN` pour Grafana (voir section Variables CI/CD).
- **Supervision (Prometheus + Grafana)** sur une instance EC2 dédiée (`supervision/`), scrapant `node_exporter` (binaire natif, pas de conteneur, pour ne pas fausser la mesure de charge) installé sur les instances app/staging. Dashboard Grafana et datasource Prometheus provisionnés automatiquement au démarrage. Limite assumée : les métriques/dashboards ne survivent pas à un `destroy_supervision` (pas de stockage S3/EBS dédié pour cette donnée à faible enjeu, contrairement à RDS/S3 pour le contenu Ghost) — c'est de l'observation temps réel pendant les cycles de test, pas de l'historisation long terme.
- **Alerting Grafana** : 4 règles provisionnées par fichier comme la datasource/le dashboard — "instance down" (P1, `up == bool 0` sur node_exporter, `for: 2m`) et mémoire > 85 %, CPU > 90 %, disque > 80 % (P2, `for: 5m`). Destinataire email fixé dans `supervision/ansible/roles/monitoring/defaults/main.yml` (`monitoring_alert_email`, même principe que `nginx_certbot_email` ailleurs dans le projet — à changer là en cas de fork). SMTP optionnel (voir Variables CI/CD) : sans SMTP configuré, l'alerte se déclenche et s'affiche quand même dans Grafana (Alerting → Alert rules), seul l'envoi d'email échoue silencieusement.

## Structure du dépôt

- `app/` :
  - `docker-compose.yml`, `dockerfile` : stack applicative Ghost (l'image se connecte à une base RDS externe, pas de MySQL en conteneur).
  - `ansible/` : rôles `hardening` (pare-feu, durcissement SSH), `docker` (installation Docker Engine), `node_exporter` (métriques système pour Prometheus), `ghost_app` (déploiement du conteneur Ghost), `nginx` (reverse proxy + Certbot/HTTPS).
  - `terraform/persistent/`, `terraform/instances/`, `terraform/dns/` : voir Architecture ci-dessus.
- `supervision/` : stack de supervision (Prometheus + Grafana), state Terraform (`terraform/`) et rôles Ansible (`ansible/roles/hardening`, `docker`, `monitoring`, `nginx`) dédiés — voir Architecture ci-dessus.
- `.gitlab-ci.yml` : pipeline CI/CD, voir section dédiée ci-dessous.

## Git Workflow : Trunk-Based Development

- **Trunk unique (`main`)**, protégé (pas de push direct, pas de force-push), pas de branches `develop`/`release`.
- Branches de fonctionnalités courtes (`feature/`, `fix/`, `chore/`, `docs/...`), une Merge Request par contribution, branche supprimée après le merge.
- Merge checks : pas de merge si la pipeline n'est pas verte, ni tant qu'une discussion de relecture reste ouverte.

## Pipeline CI/CD

Stages : `.pre` (validation Terraform) → `build` (image Docker) → `test` (lint, scans) → `provisioning` (Terraform) → `deploy` (Ansible) → `destroy` (Terraform).

Gates bloquants, jamais contournés (aucun `allow_failure` sur un test) : `terraform validate`, `tflint`, `ansible-lint`, `hadolint`, et Trivy sur l'image Ghost, sur les images de supervision et sur le binaire `node_exporter` installé hors image (bloquant sur toute CVE CRITICAL). La détection de secrets GitLab produit un rapport sur chaque MR, sans bloquer. Une CVE ne passe qu'après analyse, documentée dans `.trivyignore`. Les déploiements attendent la fin de tous les tests, et chaque déploiement Ansible se termine par un contrôle HTTP 200 de l'URL publique.

Jobs manuels principaux :

| Job | Rôle |
|---|---|
| `deploy_data` | Crée/met à jour VPC, subnets, security group, RDS (`app/terraform/persistent`) |
| `deploy_app_infra` | Crée/met à jour les EC2 prod + staging (`app/terraform/instances`) |
| `deploy_dns` | Crée/met à jour les enregistrements DNS OVH (`app/terraform/dns`), doit être lancé après `deploy_app_infra` |
| `deliver_staging` | Déploie l'image Ghost + Nginx/Certbot sur staging via Ansible (automatique sur Merge Request si les fichiers pertinents changent) |
| `deploy_prod` | Promotion manuelle du même tag d'image vers la prod (+ Nginx/Certbot), uniquement depuis une pipeline sur `main` |
| `destroy_app_infra` | Détruit les EC2 (doit être lancé avant `destroy_data`) |
| `destroy_data` | Détruit VPC/subnets/security group/RDS — bloqué automatiquement tant que des EC2 existent encore |
| `destroy_dns` | Détruit les enregistrements DNS OVH. À lancer en premier ; attend la fin des déploiements en cours (`resource_group`) |
| `deploy_supervision` | Crée/met à jour l'instance EC2 de supervision (`supervision/terraform`) |
| `deploy_supervision_config` | Déploie Prometheus + Grafana via Ansible sur l'instance de supervision |
| `destroy_supervision` | Détruit l'instance de supervision — indépendant de `destroy_app_infra`/`destroy_data` |

Ces boutons apparaissent selon deux logiques, qui coexistent :

- **Sur une Merge Request** : automatiquement, si le diff touche les fichiers concernés (vrai fonctionnement GitOps). Exception : `deploy_prod`, jamais proposé sur une MR (la prod ne reçoit que du code mergé).
- **Depuis "Run pipeline"** (CI/CD → Pipelines → Run pipeline, sur `main`) : toujours disponibles, quel que soit le diff — c'est le mode utilisé pour la démonstration/soutenance, accessible depuis un simple navigateur.

Dans les deux cas, rien ne s'exécute sans un clic explicite sur le bouton du job.

## Variables CI/CD requises

À définir dans **Settings → CI/CD → Variables** :

| Variable | Rôle | Protected | Masked |
|---|---|---|---|
| `AWS_ACCESS_KEY_ID` | Authentification AWS (IAM dédié au projet) | Non* | Oui |
| `AWS_SECRET_ACCESS_KEY` | Authentification AWS | Non* | Oui |
| `AWS_DEFAULT_REGION` | Région AWS (`eu-west-3`) | Non* | Non |
| `SUPERVISION_IP_CIDR` | IP **privée** (pas l'Elastic IP publique) de l'instance de supervision, seule autorisée à scraper `node_exporter` (port 9100) sur app/staging | Non* | Non |
| `GHOST_URL_APP` | URL publique de la prod (`https://ghost.lacera.fr`), transmise à Ghost (`url` config) et utilisée par le rôle `nginx` pour dériver le domaine du certificat Certbot | Non* | Non |
| `GHOST_URL_STAGING` | URL publique du staging (`https://ghost-staging.lacera.fr`) | Non* | Non |
| `MONITORING_DOMAIN` | Domaine de Grafana (`ghost-monitoring.lacera.fr`), utilisé par le rôle `nginx` de `supervision/ansible` pour le certificat Certbot | Non* | Non |
| `GRAFANA_ADMIN_PASSWORD` | Mot de passe du compte admin Grafana | Non* | Oui |
| `MONITORING_SMTP_HOST` | Serveur SMTP pour l'envoi des alertes par email — optionnel, vide = alerte visible dans Grafana mais pas d'email envoyé | Non* | Non |
| `MONITORING_SMTP_USER` | Utilisateur SMTP — optionnel | Non* | Non |
| `MONITORING_SMTP_PASSWORD` | Mot de passe SMTP — optionnel | Non* | Oui |
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

## Bootstrap supervision (une seule fois)

`SUPERVISION_IP_CIDR` doit contenir l'IP **privée** de l'instance de supervision, qui n'existe qu'une fois cette instance créée — bootstrap en plusieurs passes :

1. Donner une valeur provisoire à `SUPERVISION_IP_CIDR` (ex: `127.0.0.1/32`) si elle n'a pas encore de vraie valeur.
2. `deploy_data` — crée aussi le security group `supervision`, indépendant de cette variable.
3. `deploy_supervision` — crée l'instance EC2 de supervision.
4. Récupérer l'IP **privée** de l'instance (`terraform output -raw supervision_private_ip` dans les logs du job, ou dans la console AWS) — pas l'IP publique/Elastic IP, le trafic de scrape passe par le réseau privé du VPC.
5. Mettre à jour `SUPERVISION_IP_CIDR` avec `<ip_privée>/32`.
6. Relancer `deploy_data` — met à jour la règle du security group `app` in-place, sans recréer d'instance.
7. `deploy_dns` — crée l'enregistrement `ghost-monitoring.lacera.fr` (nécessite que `deploy_supervision` ait déjà tourné).
8. `deploy_supervision_config` — installe Prometheus + Grafana, obtient le certificat HTTPS pour `ghost-monitoring.lacera.fr`.
9. `deliver_staging`/`deploy_prod` si pas déjà fait — installe `node_exporter` sur app/staging (ajouté à `app/ansible/playbook.yml`).

Vérification : `https://ghost-monitoring.lacera.fr` doit afficher Grafana (identifiants `admin`/`$GRAFANA_ADMIN_PASSWORD`), avec la datasource Prometheus et le dashboard "ghostblog - app/staging" déjà provisionnés, ciblant `app`/`staging` en `UP`.

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
- Durcissement des serveurs (rôle `hardening`) : UFW en refus par défaut, SSH par clé uniquement, connexion root interdite.
- Images AMI Ubuntu filtrées sur le compte officiel de Canonical, toujours la plus récente (donc la plus à jour).

## Coûts (FinOps)

- Toute l'infrastructure est détruite en fin de session et reconstruite depuis la pipeline.
- Instances au plus juste (`t3.micro` en staging, dimensionné sur mesures Grafana).
- Budget AWS mensuel avec alerte, et détection d'anomalies de coûts.

## Stack technique

- **CMS** : Ghost 6 (image `ghost:6-alpine`)
- **Base de données** : MySQL 8.4 LTS (Amazon RDS)
- **Supervision** : Prometheus v3.15, Grafana 13, node_exporter 1.12
- **Qualité et sécurité** : Trivy, tflint, hadolint, ansible-lint, détection de secrets GitLab
- **Conteneurisation** : Docker / Docker Compose
- **Infrastructure as Code** : Terraform (providers AWS + OVH)
- **Configuration** : Ansible
- **Cloud** : AWS (EC2, EIP, VPC, RDS, S3, IAM)
- **DNS** : OVH (`lacera.fr`)
- **Reverse proxy / HTTPS** : Nginx + Certbot (Let's Encrypt)
- **CI/CD** : GitLab CI/CD & GitLab Container Registry
