'''
Follow these steps to configure the webhook in Slack:

  1. Navigate to https://<your-team-domain>.slack.com/services/new

  2. Search for and select "Incoming WebHooks".

  3. Choose the default channel where messages will be sent and click "Add Incoming WebHooks Integration".

  4. Copy the webhook URL from the setup instructions and use it in the next section.

To encrypt your secrets use the following steps:

  1. Create or use an existing KMS Key - http://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html

  2. Click the "Enable Encryption Helpers" checkbox

  3. Paste <SLACK_CHANNEL> into the slackChannel environment variable

  Note: The Slack channel does not contain private info, so do NOT click encrypt

  4. Paste <SLACK_HOOK_URL> into the kmsEncryptedHookUrl environment variable and click encrypt

  Note: You must exclude the protocol from the URL (e.g. "hooks.slack.com/services/abc123").

  5. Give your function's role permission for the kms:Decrypt action.

     Example:

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1443036478000",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": [
                "<your KMS key ARN>"
            ]
        }
    ]
}
'''


import json
import logging
import os
import re
import ast
import pypd

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Event: " + str(event))
    logger.info("Raw Message: " + str(event['Records'][0]['Sns']['Message'].strip()))
    raw_msg = ast.literal_eval(event['Records'][0]['Sns']['Message'].strip())
    message = json.loads(json.dumps(raw_msg[0]))

    severity = float(re.search('^Severity ([0-9\.]+) -', message['title']).group(1))

    if 7.0 <= severity <= 8.9:
        pypd.api_key = os.environ['pagerduty_api_token']
        pg_message = {
            'routing_key': os.environ['pagerduty_integration_key'],
            'event_action': 'trigger',
            'payload': {
                'summary': re.sub('^Severity ([0-9\.]+)', 'Severity High', message['title']),
                'severity': 'critical',
                'source': '',
                'component': '',
                'group': 'AWS Monitoring',
                'class': 'AWS GuardDuty'
            }
        }

        for i in message['fields']:
            if i['title'] == "Account ID":
                pg_message['payload']['component'] = i['value']
            if i['title'] == "Timestamp":
                pg_message['payload']['timestamp'] = i['value']
            if i['title'] == "ARN":
                pg_message['payload']['source'] = i['value']

        try:
            logger.info("Triggering Pagerduty with payload: " + json.dumps(pg_message))
            pypd.EventV2.create(pg_message)
            logger.info("Pagerduty triggered.")
        except:
            logger.error("Request failed.")
    else:
        logger.info("Ingored non critial event.")
