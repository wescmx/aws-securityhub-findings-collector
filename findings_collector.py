import boto3
import json
import csv
import io
from datetime import datetime, timezone, timedelta
import os

def lambda_handler(event, context):
    securityhub = boto3.client('securityhub')
    s3 = boto3.client('s3')
    bucket_name = os.environ['BUCKET_NAME']

    # Calculate date range for the previous month
    now = datetime.now(timezone.utc)
    first_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    last_month_start = (first_of_month - timedelta(days=1)).replace(day=1)
    last_month_end = first_of_month - timedelta(microseconds=1)

    # Create filter
    filters = {
        "UpdatedAt": [{
            "Start": last_month_start.isoformat(),
            "End": last_month_end.isoformat()
        }],
        "RecordState": [{
            "Value": "ACTIVE",
            "Comparison": "EQUALS"
        }],
        "SeverityLabel": [
            {
                "Value": "CRITICAL",
                "Comparison": "EQUALS"
            },
            {
                "Value": "HIGH",
                "Comparison": "EQUALS"
            }
        ]
    }

    findings = []
    next_token = None

    # Fetch all findings with pagination
    while True:
        if next_token:
            response = securityhub.get_findings(
                Filters=filters,
                MaxResults=100,
                NextToken=next_token
            )
        else:
            response = securityhub.get_findings(
                Filters=filters,
                MaxResults=100
            )

        findings.extend(response['Findings'])

        if 'NextToken' not in response:
            break

        next_token = response['NextToken']

    # Generate file names with the requested format
    # Use current date for both prefix and filename
    current_date = now.strftime('%Y-%m-%d')
    base_filename = f'securityhub-findings-{current_date}'

    # Generate JSON file
    json_key = f'{current_date}/{base_filename}.json'
    s3.put_object(
        Bucket=bucket_name,
        Key=json_key,
        Body=json.dumps(findings, default=str)
    )

    # Generate CSV file
    csv_data = []
    csv_headers = ['Id', 'Severity', 'Title', 'Description', 'CreatedAt', 'UpdatedAt']

    for finding in findings:
        csv_data.append([
            finding['Id'],
            finding['Severity']['Label'],
            finding['Title'],
            finding['Description'],
            finding['CreatedAt'],
            finding['UpdatedAt']
        ])

    # Write CSV to memory then upload to S3
    csv_buffer = io.StringIO()
    csv_writer = csv.writer(csv_buffer)
    csv_writer.writerow(csv_headers)
    csv_writer.writerows(csv_data)

    csv_key = f'{current_date}/{base_filename}.csv'
    s3.put_object(
        Bucket=bucket_name,
        Key=csv_key,
        Body=csv_buffer.getvalue()
    )

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Successfully collected {len(findings)} findings',
            'json_file': json_key,
            'csv_file': csv_key
        })
    }
