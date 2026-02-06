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
