.PHONY: all install start status deploy stop clean ec2-start ec2-stop ec2-status

# Commande par défaut : installe et démarre
all: install start

# 1. Installation des dépendances (Robuste)
install:
	@echo "🛠️  Correction et Installation..."
	# On vire le fichier Yarn qui bloque souvent les mises à jour dans Codespaces
	sudo rm -f /etc/apt/sources.list.d/yarn.list
	# Mise à jour des dépôts
	sudo apt-get update || true
	# On installe UNIQUEMENT les outils système via apt
	sudo apt-get install -y jq zip python3-pip
	# On installe AWS CLI + LocalStack via PIP (c'est plus fiable)
	# Le flag --break-system-packages est géré automatiquement en cas d'erreur
	sudo pip install awscli localstack awscli-local --break-system-packages || sudo pip install awscli localstack awscli-local
	@echo "✅ Installation terminée."

# 2. Démarrage de l'environnement
start:
	@echo "🚀 Démarrage de LocalStack en arrière-plan..."
	localstack start -d
	@echo "⏳ Pause de 15 secondes pour laisser les services démarrer..."
	@sleep 15
	@echo "⚙️  Configuration des identifiants AWS factices..."
	aws configure set aws_access_key_id test
	aws configure set aws_secret_access_key test
	aws configure set region us-east-1
	@echo "✅ Environnement AWS simulé est PRÊT."

# 3. Vérification de l'état des services LocalStack
status:
	localstack status services

# 4. Déploiement de l'infrastructure (Lance ton script setup.sh)
deploy:
	@echo "🏗️  Exécution du script d'infrastructure..."
	chmod +x infrastructure/setup.sh
	bash infrastructure/setup.sh

# 5. Arrêt simple (Stop le conteneur mais garde les fichiers)
stop:
	@echo "🛑 Arrêt de LocalStack..."
	localstack stop

# 6. Nettoyage complet (Reset total pour repartir de zéro)
clean:
	@echo "🧹 Nettoyage des fichiers et arrêt..."
	localstack stop || true
	rm -rf rep_localstack
	rm -f lambda/function.zip
	rm -f infrastructure/function.zip
	@echo "✨ Environnement nettoyé."


# --- Raccourcis pour piloter l'EC2 via l'API (Synchronisés avec setup.sh) ---

# Appelle la route /start
ec2-start:
	@echo "🟢 Envoi de l'ordre START via l'API..."
	$(eval API_ID := $(shell aws --endpoint-url=http://127.0.0.1:4566 apigateway get-rest-apis --query 'items[0].id' --output text))
	@curl -s -X GET "http://127.0.0.1:4566/restapis/$(API_ID)/prod/_user_request_/start" | jq .

# Appelle la route /stop
ec2-stop:
	@echo "🔴 Envoi de l'ordre STOP via l'API..."
	$(eval API_ID := $(shell aws --endpoint-url=http://127.0.0.1:4566 apigateway get-rest-apis --query 'items[0].id' --output text))
	@curl -s -X GET "http://127.0.0.1:4566/restapis/$(API_ID)/prod/_user_request_/stop" | jq .

# Appelle la route /status
ec2-status:
	@echo "🔍 Vérification du STATUT via l'API..."
	$(eval API_ID := $(shell aws --endpoint-url=http://127.0.0.1:4566 apigateway get-rest-apis --query 'items[0].id' --output text))
	@curl -s -X GET "http://127.0.0.1:4566/restapis/$(API_ID)/prod/_user_request_/status" | jq .