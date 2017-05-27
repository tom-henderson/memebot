import json
from urlparse import parse_qs

import boto3

token_parameter = 'memebot_slash_command_token'
sns_topic = 'memebot_sns_topic'
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

    token = params['token'][0]
    if token != expected_token:
        logger.error("Request token (%s) does not match expected", token)
        return respond(Exception('Invalid request token'))

    user = get_param(params, 'user_name')
    command = get_param(params, 'command')
    channel = get_param(params, 'channel_name')
    command_text = get_param(params, 'text')

    response_object = {
        "text": "Preparing your meme...",
    }

    return respond(
        None,
        json.dumps(response_object)
    )
