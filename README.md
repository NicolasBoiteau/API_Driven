☁️ Atelier 2 — API‑Driven Infrastructure




🎯 Objectif

Piloter dynamiquement des ressources EC2 simulées via une API REST Serverless, sans aucune interaction manuelle avec une console AWS.

L’environnement AWS est entièrement simulé localement grâce à LocalStack.

🏗️ Architecture technique
graph LR
    U[Client curl] -->|POST /ec2| A[API Gateway]
    A -->|Trigger| L[Lambda Python]
    L -->|Boto3| LS[LocalStack]
    LS -->|Start / Stop| E[EC2 Instance]
🚀 Installation & déploiement
Démarrage de l’environnement
make all

Installation des outils (awscli, localstack, jq)

Démarrage du conteneur LocalStack

Configuration AWS factice

Déploiement de la stack
make deploy

➡️ L’URL de l’API est affichée automatiquement

🎮 Utilisation de l’API
Stop de l’instance
curl -X POST http://127.0.0.1:4566/restapis/<API_ID>/prod/_user_request_/ec2 \
  -H 'Content-Type: application/json' \
  -d '{"instance_id": "<INSTANCE_ID>", "action": "stop"}'
Start de l’instance
curl -X POST http://127.0.0.1:4566/restapis/<API_ID>/prod/_user_request_/ec2 \
  -H 'Content-Type: application/json' \
  -d '{"instance_id": "<INSTANCE_ID>", "action": "start"}'
🔍 Vérification de l’état
aws --endpoint-url=http://127.0.0.1:4566 ec2 describe-instances \
  --instance-ids <INSTANCE_ID> \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text
📂 Structure — Atelier 2
.
├── Makefile
├── infrastructure/
│   └── setup.sh
└── lambda/
    └── main.py
🧠 Choix techniques clés

Architecture Serverless événementielle

Simulation AWS complète avec LocalStack

Gestion réseau Docker via IP passerelle 172.17.0.1

Automatisation robuste et idempotente

🧹 Nettoyage global
make clean
