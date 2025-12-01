import boto3
import os
import json

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME', 'VisitorCountTable')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    counter_id = 'homepage'

    response = table.update_item(
        Key={'id': counter_id},
        UpdateExpression='ADD #c :inc',
        ExpressionAttributeNames={'#c': 'count'},
        ExpressionAttributeValues={':inc': 1},
        ReturnValues='UPDATED_NEW'
    )

    new_count = response['Attributes']['count']

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps({'count': int(new_count)})
    }
