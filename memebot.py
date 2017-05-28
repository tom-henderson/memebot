import os
import json
from urlparse import parse_qs

import boto3

token_parameter = os.environ['token_parameter']
sns_arn = os.environ['sns_arn']
sns = boto3.client('sns')


def respond(err, res=None):
    return {
        'statusCode': '400' if err else '200',
        'body': err.message if err else res,
        'headers': {
            'Content-Type': 'application/json',
        },
    }


try:
    ssm = boto3.client('ssm')
    response = ssm.get_parameters(
        Names=[token_parameter],
        WithDecryption=True
    )
    expected_token = response['Parameters'][0]['Value']
except:
    respond(Exception('Failed to fetch token'))


def get_param(params, key, default=None):
    try:
        return params[key][0]
    except KeyError:
        return default


def lambda_handler(event, context):
    params = parse_qs(event['body'])

    token = get_param(params, 'token')
    if token != expected_token:
        logger.error("Request token (%s) does not match expected", token)
        return respond(Exception('Invalid request token'))

    response = sns.publish(
        TargetArn=sns_arn,
        Message=json.dumps({'default': json.dumps(params)}),
        MessageStructure='json'
    )

    response_object = {
        "text": ":hourglass: Preparing your meme.",
    }

    return respond(
        None,
        json.dumps(response_object)
    )
