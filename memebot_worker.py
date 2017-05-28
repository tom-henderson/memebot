import json
import urllib2
from pprint import pprint


def respond(url, response_object):
    req = urllib2.Request(url)
    req.add_header('Content-Type', 'application/json')
    response = urllib2.urlopen(req, json.dumps(response_object))
    return response


def get_param(params, key, default=None):
    try:
        return params[key][0]
    except KeyError:
        return default


def lambda_handler(event, context):
    message = json.loads(event['Records'][0]['Sns']['Message'])

    user_name = get_param(message, 'user_name')
    channel_name = get_param(message, 'channel_name')
    command = get_param(message, 'command')
    command_text = get_param(message, 'text')
    response_url = get_param(message, 'response_url')

    response_object = {
        "text": ":white_check_mark: Worker ran successfully.",
    }

    response = respond(response_url, response_object)
