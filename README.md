# 👻 Ghost Infrastructure Project — DevSecOps Edition

Ce projet implémente une plateforme de blogging **Ghost** sécurisée, sobre et hautement disponible. L'infrastructure est déployée sur **AWS** via une démarche **IaC (Terraform & Ansible)** et orchestrée avec **Docker Swarm**.

---

## 🏗️ Architecture & Philosophie DevOps

Le projet repose sur des principes forts :

- **KISS & FinOps :** Architecture optimisée sur instance unique AWS EC2 (avec Elastic IP et stockage persistant EBS) pour éviter l'over-engineering et maîtriser l'empreinte cloud.
- **Blue-Green Deployment :** Stratégie de déploiement sans coupure de service (_Zero Downtime_) gérée via un Reverse Proxy Nginx.
- **DevSecOps :** Rotation des secrets, passphrases à haute entropie (méthode Diceware), masquage des variables d'environnement, et scans de sécurité automatisés (Trivy).

### Structure du Dépôt

- **/app** : Stack applicative (Ghost, MySQL 8.0, configurations Docker Swarm / Compose).
- **/infra** : Code IaC (Terraform pour le provisionnement AWS, Playbooks Ansible pour la configuration).
- **/.gitlab-ci.yml** : Pipeline d'intégration et de déploiement continus.

---

## 🌿 Git Workflow : Trunk-Based Development

Le projet abandonne le modèle lourd _Git Flow_ au profit du **Trunk-Based Development** :

- **Trunk unique (`main`) :** Seule branche pérenne du projet.
- **Short-Lived Feature Branches :** Branches de fonctionnalités très courtes créées via `git switch -c feature/<nom>`.
- **Merge Requests (MR) :** Validation rapide et fusion immédiate sur `main` pour garantir une intégration continue réelle et fluide.

---

## 🚀 Démarrage Rapide (Environnement Local)

### Pré-requis

- Docker Engine / Docker Compose
- Git (version 2.23+ recommandée pour `git switch`)

### Installation & Lancement

1. **Cloner le dépôt :**
   ```bash
   git clone <url-du-depot-gitlab>
   cd app
   ```

2. **Configurer les variables d'environnement :**
   Duplique le fichier modèle `.env.example` et renseigne tes secrets :
   ```bash
   cp .env.example .env
   ```
   *(Le fichier `.env` est exclu du versioning via le `.gitignore`).*

3. **Lancer la stack en local :**
   ```bash
   docker compose up -d
   ```

### Accès aux Services

- **Blog** : http://localhost:8090
- **Administration** : http://localhost:8090/ghost

---

## 🛡️ Sécurité & Secrets

- **Gestion des identifiants :** Aucun secret n'est commité dans le dépôt. Les mots de passe sont générés via la méthode **Diceware** (phrases de passe à haute entropie) et injectés via les **Variables CI/CD GitLab** (masquées et protégées).
- **Isolation des volumes :** Persistance stricte des données MySQL et des médias Ghost séparée sur des volumes dédiés.

---

## 🛠️ Stack Technique

- **CMS Applicatif :** Ghost 5 (Alpine Edition / Node.js)
- **Base de données :** MySQL 8.0
- **Orchestration :** Docker Swarm / Docker Compose
- **Infrastructure as Code :** Terraform & Ansible
- **Cloud Provider :** AWS (EC2, EBS, EIP, VPC)
- **CI/CD Pipeline :** GitLab CI/CD & GitLab Container Registry
