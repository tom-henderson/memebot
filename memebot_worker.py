import json
import re
import urllib2
from urllib import urlencode
from pprint import pprint

api_url = "https://api.imgflip.com/caption_image"
memes = [
    {
        "regex": "(one does not simply) (.*)",
        "template_id": "61579"
    },
    {
        "regex": "(i don'?t always .*) (but when i do,? .*)",
        "template_id": "61532"
    },
    {
        "regex": "aliens ()(.*)",
        "template_id": "101470"
    },
    {
        "regex": "grumpy cat ()(.*)",
        "template_id": "405658"
    },
    {
        "regex": "(.*),? (\1 everywhere)",
        "template_id": "347390"
    },
    {
        "regex": "(not sure if .*) (or .*)",
        "template_id": "61520"
    },
    {
        "regex": "(y u no) (.+)",
        "template_id": "61527"
    },
    {
        "regex": "(brace yoursel[^\s]+) (.*)",
        "template_id": "61546"
    },
    {
        "regex": "(.*) (all the .*)",
        "template_id": "61533"
    },
    {
        "regex": "(.*) (that would be great|that'?d be great)",
        "template_id": "563423"
    },
    {
        "regex": "(.*) (\w+\stoo damn .*)",
        "template_id": "61580"
    },
    {
        "regex": "(yo dawg .*) (so .*)",
        "template_id": "101716"
    },
    {
        "regex": "(.*) (.* gonna have a bad time)",
        "template_id": "100951"
    },
    {
        "regex": "(am i the only one around here) (.*)",
        "template_id": "259680"
    },
    {
        "regex": "(what if i told you) (.*)",
        "template_id": "100947"
    },
    {
        "regex": "(.*) (ain'?t nobody got time for? that)",
        "template_id": "442575"
    },
    {
        "regex": "(.*) (i guarantee it)",
        "template_id": "10672255"
    },
    {
        "regex": "(.*) (a+n+d+ it'?s gone)",
        "template_id": "766986"
    },
    {
        "regex": "(.* bats an eye) (.* loses their minds?)",
        "template_id": "1790995"
    },
    {
        "regex": "(back in my day) (.*)",
        "template_id": "718432"
    }
]


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


def find_meme(input):
    for meme in memes:
        meme['match'] = re.search(meme['regex'], input.lower())
        if meme['match']:
            return meme
    return None


def lambda_handler(event, context):
    message = json.loads(event['Records'][0]['Sns']['Message'])

    user_name = get_param(message, 'user_name')
    channel_name = get_param(message, 'channel_name')
    command = get_param(message, 'command')
    command_text = get_param(message, 'text')
    response_url = get_param(message, 'response_url')

    if command_text == "help":
        expressions = "\n".join([meme['regex'] for meme in memes])
        response_object = {
            "response_type": "ephemeral",
            "text": "```{}```".format(expressions)
        }
        respond(response_url, response_object)

    meme = find_meme(command_text)

    if meme:
        meme_request = urlencode({
            'username': "imgflip_hubot",
            'password': "imgflip_hubot",
            'template_id': meme['template_id'],
            'text0': meme['match'].groups()[0],
            'text1': meme['match'].groups()[1],
        })

        request = urllib2.Request(api_url)
        request.add_header('User-Agent', "Mozilla/5.0")
        response = urllib2.urlopen(request, meme_request)
        meme_image = json.loads(response.read())['data']['url']

        response_object = {
            "response_type": "in_channel",
            "text": meme_image,
        }
    else:
        response_object = {
            "response_type": "ephemeral",
            "text": "Sorry, I couldn't find a meme to match '{}'".format(
                command_text
            )
        }

    respond(response_url, response_object)
