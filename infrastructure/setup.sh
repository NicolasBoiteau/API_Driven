#!/bin/bash

# Configuration
# On utilise 127.0.0.1 pour le script (côté terminal)
ENDPOINT_URL="http://127.0.0.1:4566"
REGION="us-east-1"
# On utilise host.docker.internal pour que la Lambda (dans docker) voie LocalStack
LAMBDA_INTERNAL_ENDPOINT="http://172.17.0.1:4566"

# Alias pour simplifier les commandes
awslocal="aws --endpoint-url=$ENDPOINT_URL --region=$REGION"

echo "🏗️  Début du déploiement de l'infrastructure..."

# 1. Création d'une instance EC2 factice (pour avoir quelque chose à piloter)
echo "1️⃣  Création de l'instance EC2..."
INSTANCE_ID=$($awslocal ec2 run-instances --image-id ami-ff0000 --count 1 --instance-type t2.micro --query 'Instances[0].InstanceId' --output text)
echo "   ✅ Instance créée : $INSTANCE_ID"

# 2. Préparation du rôle IAM pour la Lambda
echo "2️⃣  Création du Rôle IAM..."
cat > role-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{"Effect": "Allow","Principal": {"Service": "lambda.amazonaws.com"},"Action": "sts:AssumeRole"}]
}
EOF
$awslocal iam create-role --role-name LambdaEC2Role --assume-role-policy-document file://role-trust-policy.json > /dev/null
$awslocal iam attach-role-policy --role-name LambdaEC2Role --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
rm role-trust-policy.json

# 3. Packaging et Déploiement de la Lambda
echo "3️⃣  Déploiement de la fonction Lambda..."
cd lambda && zip -q function.zip main.py && cd ..
$awslocal lambda create-function \
    --function-name ManageEC2 \
    --zip-file fileb://lambda/function.zip \
    --handler main.lambda_handler \
    --runtime python3.9 \
    --role arn:aws:iam::000000000000:role/LambdaEC2Role \
    --environment Variables="{AWS_ENDPOINT_URL=$LAMBDA_INTERNAL_ENDPOINT}" \
    > /dev/null
echo "   ✅ Lambda déployée avec variable d'env : $LAMBDA_INTERNAL_ENDPOINT"

# 4. Création de l'API Gateway
echo "4️⃣  Création de l'API Gateway..."
API_ID=$($awslocal apigateway create-rest-api --name "EC2ControllerAPI" --query 'id' --output text)
ROOT_ID=$($awslocal apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)

# Création de la ressource /ec2
RESOURCE_ID=$($awslocal apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part ec2 --query 'id' --output text)

# Création de la méthode POST
$awslocal apigateway put-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method POST --authorization-type "NONE" > /dev/null

# Intégration API Gateway -> Lambda
$awslocal apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:000000000000:function:ManageEC2/invocations \
    > /dev/null

# Déploiement de l'API
$awslocal apigateway create-deployment --rest-api-id $API_ID --stage-name prod > /dev/null

echo "---------------------------------------------------"
echo "🎉 DEPLOIEMENT TERMINE !"
echo "---------------------------------------------------"
echo "Instance ID à piloter : $INSTANCE_ID"
echo "URL de l'API : $ENDPOINT_URL/restapis/$API_ID/prod/_user_request_/ec2"
echo "---------------------------------------------------"
echo "💡 Pour tester, lancez cette commande :"
echo "curl -X POST $ENDPOINT_URL/restapis/$API_ID/prod/_user_request_/ec2 \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"instance_id\": \"$INSTANCE_ID\", \"action\": \"stop\"}'"
echo "---------------------------------------------------"