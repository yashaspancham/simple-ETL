#this ran on AWS lambda

import os
import pymysql
import boto3
import csv
from queries import (#same as here in local
    customers_table_insert_query,
    companies_table_insert_query,
    customer_company_insert_query,
    locations_table_insert_query,
    phones_table_insert_query
)


s3=boto3.client('s3')

def lambda_handler(event, context):
    bucket="customer-dataset-dl"
    key="DataSets/customers-10000.csv"

    response=s3.get_object(Bucket=bucket, Key=key)
    content=response['Body'].read().decode('utf-8').splitlines()
    reader = csv.reader(content)
    next(reader)
    conn = None
    cursor = None
    try:
        conn = pymysql.connect(
            host=os.environ['DB_HOST'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            database=os.environ['DB_NAME'],
            port=3306
        )
        cursor=conn.cursor()
        customer_data_batch=[]
        customer_company_data_batch=[]
        locations_data_batch=[]
        primary_phone_data_batch=[]
        company_id_cache={}
        for row in reader:
            # print(f"Inserting row into customers:\n{row[1], row[2], row[3], row[9], row[10], row[11]}\n")
            if len(customer_data_batch)==10:
                cursor.executemany(customers_table_insert_query, customer_data_batch)
                customer_data_batch.clear()
            customer_data = (row[1], row[2], row[3], row[9], row[10], row[11])
            customer_data_batch.append(customer_data)

            # print(f"Inserting row into companies: {row[4]}\n")
            if row[4] not in company_id_cache.values():
                companies_data = (row[4],)
                cursor.execute(companies_table_insert_query, companies_data)
                company_id = cursor.lastrowid
                company_id_cache[company_id] = row[4]

            # print(f"Inserting row into customer_company: {row[1], company_id}\n")
            if len(customer_company_data_batch)==10:
                cursor.executemany(customer_company_insert_query, customer_company_data_batch)
                customer_company_data_batch.clear()
            customer_company_data = (row[1], company_id)
            customer_company_data_batch.append(customer_company_data)


            # print(f"Inserting row into locations: {row[1], row[5], row[6]}\n")
            if len(locations_data_batch)==10:
                cursor.executemany(locations_table_insert_query, locations_data_batch)
                locations_data_batch.clear()
            locations_data = (row[1], row[5], row[6])
            locations_data_batch.append(locations_data)

            # print(f"Inserting row into phones: {row[1], 'primary', row[7]}\n")
            # print(f"Inserting row into phones: {row[1], 'secondary', row[8]}\n")
            if len(primary_phone_data_batch) == 20:
                cursor.executemany(phones_table_insert_query, primary_phone_data_batch)
                primary_phone_data_batch.clear()
            primary_phone_primary_data = (row[1], 'primary', row[7])
            primary_phone_secondary_data = (row[1], 'secondary', row[8])
            primary_phone_data_batch.append(primary_phone_primary_data)
            primary_phone_data_batch.append(primary_phone_secondary_data)
        

         # Insert any remaining batched data
        if customer_data_batch:
            cursor.executemany(customers_table_insert_query, customer_data_batch)
        if customer_company_data_batch:
            cursor.executemany(customer_company_insert_query, customer_company_data_batch)
        if locations_data_batch:
            cursor.executemany(locations_table_insert_query, locations_data_batch)
        if primary_phone_data_batch:
            cursor.executemany(phones_table_insert_query, primary_phone_data_batch)
        
        conn.commit()
        return {
                "statusCode": 200,
                "body": "Data inserted successfully"
            }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Error: {e}"
        }
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()