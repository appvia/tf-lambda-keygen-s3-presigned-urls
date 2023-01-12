import boto3
from datetime import datetime
import json
import logging
import os
import sys
import urllib3

# Global Args
logger = logging.getLogger('keygen-s3-presigned-urls')
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)
time = datetime.utcnow()

def lambda_handler(event, context):
    logger.debug(f"Event contents: {event}")
    try:
        body = json.loads(event['body'])
    except Exception as e:
        logger.error(f"Unexpected error occurred, event should contain top level key 'body' with string content to be parsed as a JSON object: {e}")
        return {
            'statusCode': 400,
            'body': json.dumps({"message": str(e)})
        }

    if body.get('licenseKey') and body['licenseKey']:
        key = body['licenseKey']
    else:
        logger.error(f"'licenseKey' is missing from event data: {body}")
        return {
            'statusCode': 401,
            'body': json.dumps({"message": "The 'licenseKey' is missing from POST data."})
        }

    ticket = body['ticketId'] if body.get('ticketId') and body['ticketId'] else "unknown-ticket"
    ticket = ticket.lower().replace(' ', '-')
    logger.info(f"Ticket ID detected as '{ticket}'")

    try:
        license = validate_keygen_license(key)
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({"message": str(e)})
        }

    try:
        orgId = license['data']['attributes']['metadata']['oId'].lower().replace(' ', '-')
        logger.info(f"Organization detected as '{orgId}'")
    except:
        logger.warning("No organization detected in license metadata, setting orgId to unknown-org.")
        orgId = "unknown-org"

    bucket = os.environ.get('S3_BUCKET')
    base_path = os.environ.get('S3_BASE_PATH')
    day = time.strftime('%Y-%m-%d')
    s3_link_expiry = int(os.environ.get('LINK_EXPIRY_HOURS')) * 60 * 60

    try:
        put_url = generate_presigned_url(
            'put_object',
            {
                'Bucket': bucket,
                'Key': f"{base_path}/{orgId}/{ticket}/{day}/support-logs.tar.gz"
            },
            s3_link_expiry)

    except Exception as e:
        logger.error(f"Unexpected error occurred: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({"message": str(e)})
        }

    logger.info("Process completed successfully.")
    return {
        'statusCode': 200,
        'body': json.dumps({"message": "S3 pre-signed URL generated successfully", "url": put_url, "ticket": ticket})
    }

def generate_presigned_url(client_method, method_parameters, expires_in):
    logger.info("Generating a pre-signed URL to allow uploading a file to S3.")

    try:
        s3_client = boto3.client('s3')
        url = s3_client.generate_presigned_url(
            ClientMethod=client_method,
            Params=method_parameters,
            ExpiresIn=expires_in
        )
    except Exception as e:
        raise Exception(f"Couldn't get a presigned URL for client method '{client_method}'. Exception Message: {e}")

    logger.info(f"Pre-signed URL for S3 has been generated: {url}")
    return url

def validate_keygen_license(key):
    logger.info("Making request to validate Keygen License")

    keygen_account_id = os.environ.get('KEYGEN_ACCOUNT_ID')

    try:
        http = urllib3.PoolManager()
        res = http.request(
            "POST",
            f"https://api.keygen.sh/v1/accounts/{keygen_account_id}/licenses/actions/validate-key",
            body=json.dumps({
                "meta": {
                    "key": key
                }
            }),
            headers={
                "Content-Type": "application/vnd.api+json",
                "Accept": "application/vnd.api+json"
            }
        )
    except Exception as e:
        raise Exception(f"Unexpected failure calling Keygen. Exception Message: {e}")

    license = json.loads(res.data.decode('utf8'))

    try:
        if license['data']['attributes']['status'] != "ACTIVE":
            raise Exception(f"License validation failure: {license['data']['attributes']['status']}")
    except Exception as e:
        raise Exception(f"Unexpected license validation failure, keygen response: {license}.")

    logger.info(f"License '{license['data']['id']}' validated successfully!")
    return license
