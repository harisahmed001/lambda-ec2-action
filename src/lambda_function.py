import json
import boto3
import os

def lambda_handler(event, context):
    ec2 = boto3.resource('ec2')

    running_instances = ec2.instances.filter(Filters=[ {
            'Name': 'instance-state-name',
            'Values': ['running']
            } ])
    
    ami = os.environ['AMI_ID']
    instances_stoped = []
    for instance in running_instances:
        if ami != instance.image.id:
            ec2.instances.filter(InstanceIds=[instance.id]).stop()
            instances_stoped.append(instance.id)

    if len(instances_stoped) > 0 and 0 == 1: # Condition marked false, can be used for sending alert
        sns = boto3.resource('sns',region_name="eu-central-1")
        response = sns.client(
            TopicArn='arn:.......',   
            Message='These instances are stopped due to volilation ' + (',').join(instances_stoped),   
        )
       
    return {
        'statusCode': 200,
        'body': json.dumps('all unwanted instances stopped')
    }
