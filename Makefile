.PHONY: all install start status deploy stop clean

# Commande par défaut : installe et démarre
all: install start

# 1. Installation des dépendances
install:
	@echo "🛠️  Correction et Installation..."
	# On vire le fichier Yarn qui bloque les mises à jour
	sudo rm -f /etc/apt/sources.list.d/yarn.list
	# Mise à jour des dépôts
	sudo apt-get update || true
	# On installe UNIQUEMENT jq et zip via apt (on retire awscli qui plante)
	sudo apt-get install -y jq zip python3-pip
	# On installe AWS CLI + LocalStack via PIP (c'est plus fiable)
	# Le flag --break-system-packages est parfois requis sur les Ubuntu récents
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

# 3. Vérification de l'état
status:
	localstack status services

# 4. Déploiement de l'infrastructure
deploy:
	@echo "🏗️  Exécution du script d'infrastructure..."
	chmod +x infrastructure/setup.sh
	bash infrastructure/setup.sh

# 5. Arrêt simple
stop:
	@echo "🛑 Arrêt de LocalStack..."
	localstack stop

# 6. Nettoyage complet
clean:
	@echo "🧹 Nettoyage des fichiers et arrêt..."
	localstack stop || true
	rm -rf rep_localstack
	rm -f lambda/function.zip
	@echo "✨ Environnement nettoyé."