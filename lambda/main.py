import boto3
import json
import os

def lambda_handler(event, context):
    # On récupère l'URL de l'endpoint via une variable d'environnement
    # Si non définie, on fallback sur une valeur par défaut (pour éviter le crash)
    endpoint = os.environ.get('AWS_ENDPOINT_URL', 'http://host.docker.internal:4566')
    
    print(f"Connexion a EC2 via : {endpoint}") # Pour les logs CloudWatch
    
    ec2 = boto3.client('ec2', endpoint_url=endpoint)

    try:
        # 1. Gestion du body (parfois string, parfois dict selon l'appel)
        body = event
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']

        instance_id = body.get('instance_id')
        action = body.get('action')

        if not instance_id or not action:
            return {
                'statusCode': 400,
                'body': json.dumps('Erreur: instance_id et action sont requis.')
            }

        # 2. Exécution de l'action
        if action == 'start':
            ec2.start_instances(InstanceIds=[instance_id])
            msg = f"Instance {instance_id} demarree."
        elif action == 'stop':
            ec2.stop_instances(InstanceIds=[instance_id])
            msg = f"Instance {instance_id} arretee."
        else:
            return {'statusCode': 400, 'body': json.dumps(f"Action inconnue: {action}")}

        return {
            'statusCode': 200,
            'body': json.dumps({'message': msg, 'status': 'success'})
        }

    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': json.dumps(f"Erreur interne: {str(e)}")
        }