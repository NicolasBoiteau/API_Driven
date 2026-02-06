#!/bin/bash
# Installation silencieuse
pip install awscli-local > /dev/null 2>&1

# 1. Creation de l'instance EC2
echo "[1/5] Creation de l'instance EC2..."
INSTANCE_ID=$(awslocal ec2 run-instances \
    --image-id ami-ff000000 \
    --count 1 \
    --instance-type t2.micro \
    --query 'Instances[0].InstanceId' \
    --output text)

echo " -> Instance creee : $INSTANCE_ID"

# 2. Creation du Role IAM
echo "[2/5] Creation du Role IAM..."
awslocal iam create-role --role-name lambda-ec2-role --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' > /dev/null

# 3. Code Python (Optimisé pour ton Codespace)
echo "[3/5] Generation du code Python..."
cat <<EOF > lambda_function.py
import boto3
import json
import os

def lambda_handler(event, context):
    # FIX NICO: On force l'IP 172.17.0.1 pour eviter les bugs reseau Docker
    endpoint = os.environ.get('AWS_ENDPOINT_URL', 'http://172.17.0.1:4566')
    ec2 = boto3.client('ec2', endpoint_url=endpoint)
    instance_id = os.environ['INSTANCE_ID']
    
    # On regarde quelle route a ete appelee (/start, /stop ou /status)
    path = event.get('resource', '')
    
    msg = ""
    
    try:
        if '/start' in path:
            ec2.start_instances(InstanceIds=[instance_id])
            msg = f"✅ Instance {instance_id} DEMARREE avec succes."
        
        elif '/stop' in path:
            ec2.stop_instances(InstanceIds=[instance_id])
            msg = f"🛑 Instance {instance_id} ARRETEE avec succes."
            
        elif '/status' in path:
            msg = "Verification du statut..."
        
        else:
            return {"statusCode": 400, "body": json.dumps("Route inconnue")}

        # Verification finale de l'etat
        desc = ec2.describe_instances(InstanceIds=[instance_id])
        state = desc['Reservations'][0]['Instances'][0]['State']['Name']
        
        return {
            "statusCode": 200, 
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "route": path,
                "instance_id": instance_id,
                "etat_actuel": state,
                "message": msg
            })
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
EOF

rm -f function.zip
zip function.zip lambda_function.py > /dev/null

# 4. Deploiement Lambda (Avec le fix IP)
echo "[4/5] Deploiement de la Lambda..."
LAMBDA_ARN=$(awslocal lambda create-function \
    --function-name ManageEC2 \
    --zip-file fileb://function.zip \
    --handler lambda_function.lambda_handler \
    --runtime python3.9 \
    --role arn:aws:iam::000000000000:role/lambda-ec2-role \
    --environment Variables="{INSTANCE_ID=$INSTANCE_ID,AWS_ENDPOINT_URL=http://172.17.0.1:4566}" \
    --query 'FunctionArn' --output text)

# 5. API Gateway (Start, Stop, Status)
echo "[5/5] Configuration API Gateway..."
API_ID=$(awslocal apigateway create-rest-api --name "EC2Controller" --query 'id' --output text)
PARENT_ID=$(awslocal apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)

# Fonction pour creer une route rapidement
create_route() {
    PATH_PART=$1
    echo " -> Route /$PATH_PART..."
    RES_ID=$(awslocal apigateway create-resource --rest-api-id $API_ID --parent-id $PARENT_ID --path-part $PATH_PART --query 'id' --output text)
    awslocal apigateway put-method --rest-api-id $API_ID --resource-id $RES_ID --http-method GET --authorization-type NONE > /dev/null
    awslocal apigateway put-integration --rest-api-id $API_ID --resource-id $RES_ID --http-method GET --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations > /dev/null
}

create_route "start"
create_route "stop"
create_route "status"

awslocal apigateway create-deployment --rest-api-id $API_ID --stage-name prod > /dev/null

# URL AUTO-DETECT
if [ -n "$CODESPACE_NAME" ]; then
    BASE_URL="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
else
    BASE_URL="http://localhost:4566"
fi

echo "--------------------------------------------------"
echo "✅ SUCCES ! Cliquez sur les liens ci-dessous :"
echo "--------------------------------------------------"
echo "🟢 DEMARRER : $BASE_URL/restapis/$API_ID/prod/_user_request_/start"
echo "🔴 ARRETER  : $BASE_URL/restapis/$API_ID/prod/_user_request_/stop"
echo "🔍 STATUT   : $BASE_URL/restapis/$API_ID/prod/_user_request_/status"
echo "--------------------------------------------------"