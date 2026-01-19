# 👻 Ghost Infrastructure Project - DevOps Edition

Ce projet implémente une plateforme de blogging **Ghost** hautement disponible, orchestrée avec **Docker** et destinée à être déployée sur **AWS** via **Terraform**.

## 🏗 Architecture du Projet

Le projet est divisé en deux parties principales :
* **/app** : Contient l'application Ghost, sa base de données MySQL et la configuration Docker.
* **/terraform** (En cours) : Infrastructure as Code pour le déploiement sur le Cloud.



## 🚀 Démarrage Rapide (Local)

### Pré-requis
* Docker Desktop ou Docker Engine
* Git Flow

### Installation
1.  Cloner le dépôt.
2.  Se rendre dans le dossier applicatif :
    ```bash
    cd app
    ```
3.  Lancer les containers :
    ```bash
    docker compose up -d
    ```

### Accès
* **Blog** : [http://localhost:2368](http://localhost:2368)
* **Administration** : [http://localhost:2368/ghost](http://localhost:2368/ghost)

## 🛡 Sécurité & DevOps
* **Git Flow** : Utilisation du workflow de branches pour les fonctionnalités.
* **Secrets** : Gestion via fichiers `.env` (exclus du versioning via `.gitignore`).
* **Santé du système** : Healthchecks intégrés pour assurer que Ghost ne démarre qu'une fois MySQL prêt.

## 🛠 Stack Technique
* **CMS** : Ghost 5 (Alpine Edition)
* **Database** : MySQL 8.0
* **CI/CD** : GitLab & GitHub (Miroring)
* **Infra** : Terraform & AWS (EC2)