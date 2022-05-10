import boto3
import json
import logging
import os
import re
import ast

from base64 import b64decode
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# The base-64 encoded, encrypted key (CiphertextBlob) stored in the kmsEncryptedHookUrl environment variable
ENCRYPTED_HOOK_URL = os.environ['kmsEncryptedHookUrl']
# The Slack Webhook URL
HOOK_URL = "https://" + boto3.client('kms').decrypt(CiphertextBlob=b64decode(ENCRYPTED_HOOK_URL))['Plaintext'].decode('utf-8')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Event: " + str(event))
    logger.info("Raw Message: " + str(event['Records'][0]['Sns']))
    message_json = event['Records'][0]['Sns']
    logger.info("Message json: " + str(message_json))
    logger.info("Message text: " + str(message_json['Message']))

    message = {
        "title": str(message_json['Subject']),
        "text": str(message_json['Message']),
        "fields": [
            {
                "title": "State",
                "value": str(message_json['MessageAttributes']['State']['Value']),
                "short": True
            },
            {
                "title": "EventType",
                "value": str(message_json['MessageAttributes']['EventType']['Value']),
                "short": True
            }
        ]
    }

    if str(message_json['MessageAttributes']['State']['Value']) == "COMPLETED":
        SLACK_CHANNEL = os.environ['slackChannelSuccess']
        status = {"color": "good"}
    else:
        SLACK_CHANNEL = os.environ['slackChannelFail']
        status = {"color": "danger"}

    message.update(status)
    slack_message = {
        'channel': SLACK_CHANNEL,
        'attachments': [message]
    }

    logger.info("Slack Message: " + str(slack_message))

    req = Request(HOOK_URL, json.dumps(slack_message).encode('utf-8'))
    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted to %s", slack_message['channel'])
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
