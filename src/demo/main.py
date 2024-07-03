import boto3
import logging
import os
import random
import json


logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)
awsRegion = os.environ["AWS_REGION"]
functionName = os.environ["AWS_LAMBDA_FUNCTION_NAME"]

def lambda_handler(event, context):
    print(event)

    response = {
        "statusCode": 200,
        "isBase64Encoded": False,
        "headers": {
            "Content-Type": "application/json"
            }
    }


    if event['path'] == '/100KB':

        if os.path.isfile("/tmp/100KB"):
            myFile = open("/tmp/100KB", "r")
        else:
            aws_aga = ("Easy manageability: The static IP addresses provided by AWS Global Accelerator are fixed and provide a single entry point to your applications.", "Fine-grained control: AWS Global Accelerator lets you set a traffic dial for your regional endpoint groups, to dial traffic up or down for a specific AWS Region when you conduct performance testing or application updates.", "Improved performance: AWS Global Accelerator ingresses traffic from the edge location that is closest to your end clients through anycast static IP addresses.", "High availability: AWS Global Accelerator has a fault-isolating design that increases the availability of your application. When you create an accelerator, you are allocated two IPv4 static IP addresses that are serviced by independent network zones.", "Instant regional failover: AWS Global Accelerator automatically checks the health of your applications and routes user traffic only to healthy application endpoints. If the health status changes or you make configuration updates, AWS Global Accelerator reacts instantaneously to route your users to the next available endpoint.")
            all = [aws_aga]

            with open('/tmp/100KB','w') as f:
                mySize = 100 * 1024 * 1024 ## 100KB
                for i in range(1880):
                    chars = ''.join([random.choice(i) for i in all])
                    f.write(chars + '\n')
                    if os.path.getsize("/tmp/100KB") > mySize:
                        break
            pass
            myFile = open("/tmp/100KB", "r")

            response['body'] = myFile.read()

    else:
        response['body']= json.dumps("Processed in " + awsRegion.upper() + " by " + functionName + "\n")

    return response