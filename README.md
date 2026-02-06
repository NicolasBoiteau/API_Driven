# 🧪 Ateliers DevOps — Infrastructure as Code & Automation

![DevOps](https://img.shields.io/badge/DevOps-IaC-blueviolet?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Production--Ready-success?style=for-the-badge)

Ce dépôt regroupe **deux ateliers DevOps complémentaires**, orientés *Infrastructure as Code*, automatisation et environnements reproductibles via **GitHub Codespaces**.

---

# 🐳 Atelier 1 — From Image to Cluster

![Packer](https://img.shields.io/badge/Packer-Build-blue?logo=packer)
![Kubernetes](https://img.shields.io/badge/K3d-Cluster-326ce5?logo=kubernetes)
![Ansible](https://img.shields.io/badge/Ansible-Deploy-EE0000?logo=ansible)

## 🎯 Objectif

Industrialiser le cycle de vie complet d’une application **Nginx**, depuis la construction d’une image immuable jusqu’à son déploiement automatisé sur un cluster Kubernetes local.

---

## 🏗️ Architecture & workflow

```mermaid
graph LR
    A[Code source index.html] -->|Packer| B[Image Docker mon-nginx-custom:v1]
    B -->|Import| C[Cluster K3d 1 Server + 2 Agents]
    D[Ansible deploy.yml] -->|Orchestration| C
    C -->|Service NodePort| E[Navigateur Web]
```

---

## 🚀 Déploiement automatisé

```bash
make all
```

**Pipeline exécuté :**

* Installation des dépendances
* Création du cluster K3d
* Build de l’image avec Packer
* Déploiement Kubernetes via Ansible

---

## 🌐 Accès à l’application

```bash
kubectl port-forward svc/nginx-service 8081:80
```

➡️ Ouvrir le navigateur → **MISSION RÉUSSIE**

---

## 📂 Structure — Atelier 1

```plaintext
.
├── Makefile
├── deploy.yml
├── index.html
└── template.pkr.hcl
```

---

# ☁️ Atelier 2 — API-Driven Infrastructure

![AWS](https://img.shields.io/badge/AWS-LocalStack-orange?logo=amazon-aws)
![Lambda](https://img.shields.io/badge/Compute-Lambda-blue?logo=aws-lambda)
![Python](https://img.shields.io/badge/Code-Python_3.9-yellow?logo=python)
![Docker](https://img.shields.io/badge/Env-Docker-blue?logo=docker)

## 🎯 Objectif

Piloter dynamiquement des ressources **EC2 simulées** via une **API REST Serverless**, sans aucune interaction manuelle avec une console AWS.

L’environnement AWS est entièrement simulé localement grâce à **LocalStack**.

---

## 🏗️ Architecture technique

```mermaid
graph LR
    U[Client curl] -->|POST /ec2| A[API Gateway]
    A -->|Trigger| L[Lambda Python]
    L -->|Boto3| LS[LocalStack]
    LS -->|Start / Stop| E[EC2 Instance]
```

---

## 🚀 Installation & déploiement

### Démarrage de l’environnement

```bash
make all
```

* Installation des outils (awscli, localstack, jq)
* Démarrage du conteneur LocalStack
* Configuration AWS factice

### Déploiement de la stack

```bash
make deploy
```

➡️ L’URL de l’API est affichée automatiquement

---

## 🎮 Utilisation de l’API

### Stop de l’instance

```bash
curl -X POST http://127.0.0.1:4566/restapis/<API_ID>/prod/_user_request_/ec2 \
  -H 'Content-Type: application/json' \
  -d '{"instance_id": "<INSTANCE_ID>", "action": "stop"}'
```

### Start de l’i
