import boto3
import os
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Stops or starts EC2 instances tagged with Environment=dev
    Triggered by EventBridge on a schedule
    event = {"action": "stop"} or {"action": "start"}
    """
    region = os.environ.get('REGION', 'us-east-1')
    environment = os.environ.get('ENVIRONMENT', 'dev')
    action = event.get('action', 'stop')

    ec2 = boto3.client('ec2', region_name=region)

    # Find instances tagged Environment=dev
    response = ec2.describe_instances(
        Filters=[
            {
                'Name': 'tag:Environment',
                'Values': [environment]
            },
            {
                'Name': 'tag:ManagedBy',
                'Values': ['lambda-scheduler']
            },
            {
                'Name': 'instance-state-name',
                'Values': ['running'] if action == 'stop' else ['stopped']
            }
        ]
    )

    # Extract instance IDs
    instance_ids = [
        instance['InstanceId']
        for reservation in response['Reservations']
        for instance in reservation['Instances']
    ]

    if not instance_ids:
        message = f"No instances found to {action}"
        logger.info(message)
        return {
            'statusCode': 200,
            'body': json.dumps({'message': message})
        }

    # Perform action
    if action == 'stop':
        ec2.stop_instances(InstanceIds=instance_ids)
        logger.info(f"STOPPED instances: {instance_ids}")
    elif action == 'start':
        ec2.start_instances(InstanceIds=instance_ids)
        logger.info(f"STARTED instances: {instance_ids}")
    else:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f"Unknown action: {action}"})
        }

    return {
        'statusCode': 200,
        'body': json.dumps({
            'action': action,
            'instances': instance_ids,
            'count': len(instance_ids)
        })
    }
