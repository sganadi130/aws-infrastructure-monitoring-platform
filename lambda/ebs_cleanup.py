import boto3
import os
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Finds and deletes unattached EBS volumes tagged Environment=dev
    Triggered by EventBridge every Sunday
    Unattached volumes = state is 'available' (not 'in-use')
    """
    region = os.environ.get('REGION', 'us-east-1')
    environment = os.environ.get('ENVIRONMENT', 'dev')

    ec2 = boto3.client('ec2', region_name=region)

    # Find unattached EBS volumes tagged Environment=dev
    response = ec2.describe_volumes(
        Filters=[
            {
                'Name': 'status',
                'Values': ['available']  # available = not attached to any instance
            },
            {
                'Name': 'tag:Environment',
                'Values': [environment]
            }
        ]
    )

    volumes = response.get('Volumes', [])

    if not volumes:
        message = "No unattached EBS volumes found to clean up"
        logger.info(message)
        return {
            'statusCode': 200,
            'body': json.dumps({'message': message})
        }

    deleted_volumes = []
    failed_volumes = []

    for volume in volumes:
        volume_id = volume['VolumeId']
        volume_size = volume['Size']

        try:
            ec2.delete_volume(VolumeId=volume_id)
            deleted_volumes.append({
                'volume_id': volume_id,
                'size_gb': volume_size
            })
            logger.info(f"DELETED volume: {volume_id} ({volume_size}GB)")

        except Exception as e:
            failed_volumes.append({
                'volume_id': volume_id,
                'error': str(e)
            })
            logger.error(f"FAILED to delete volume {volume_id}: {str(e)}")

    total_gb_freed = sum(v['size_gb'] for v in deleted_volumes)

    logger.info(f"Cleanup complete: {len(deleted_volumes)} volumes deleted, "
                f"{total_gb_freed}GB freed, "
                f"{len(failed_volumes)} failures")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'deleted_volumes': deleted_volumes,
            'failed_volumes': failed_volumes,
            'total_deleted': len(deleted_volumes),
            'total_gb_freed': total_gb_freed
        })
    }
