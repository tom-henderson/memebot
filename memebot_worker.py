import json
import urllib2
from urllib import urlencode
from pprint import pprint

api_url = "https://api.imgflip.com/caption_image"


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

    meme_request = urlencode({
        'username': "imgflip_hubot",
        'password': "imgflip_hubot",
        'template_id': "101470",
        'text1': 'Robots',
    })

    request = urllib2.Request(api_url)
    request.add_header('User-Agent', "Mozilla/5.0")
    response = urllib2.urlopen(request, meme_request)
    meme = json.loads(response.read())['data']['url']

    response_object = {
        "response_type": "in_channel",
        "text": meme,
    }

    response = respond(response_url, response_object)
