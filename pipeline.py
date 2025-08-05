import csv
import os
import time
import tracemalloc
from dotenv import load_dotenv
import psutil
import mariadb
from queries import (
    customers_table_insert_query,
    companies_table_insert_query,
    customer_company_insert_query,
    locations_table_insert_query,
    phones_table_insert_query
)



# Start tracking time and memory
start_time = time.time()
tracemalloc.start()

process = psutil.Process()


csvfile=open('dataset/customers-100.csv', newline='', encoding='utf-8')
reader=csv.reader(csvfile)

headers=next(reader)

try:
    load_dotenv()
    conn = mariadb.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME"),
    )
    cursor = conn.cursor()
    #For more info on the tables look at the docs/setUp.sql file
    

    #source structure of the CSV file:
    #head-> |Index | Customer Id | First Name | Last Name |Company | City | Country | Phone 1 | Phone 2 | Email | Subscription Date | Website|
    #index->|   0  |      1      |     2      |  3        |   4    |  5   |   6     |   7     |   8     |   9   |         10        |   11   |
    for row in reader:

        # customer_data_batch=[]
        # companies_data_batch=[]
        # customer_company_data_batch=[]
        # locations_data_batch=[]
        # primary_phone_primary_data_batch=[]
        # primary_phone_secondary_data_batch=[]
        # company_id_cache={}

        # if customer_data_batch==10: 
        # print(f"Inserting row into customers:\n{row[1], row[2], row[3], row[9], row[10], row[11]}\n")
        customer_data = (row[1], row[2], row[3], row[9], row[10], row[11])
        cursor.execute(customers_table_insert_query, customer_data)

        # print(f"Inserting row into companies: {row[4]}\n")
        companies_data = (row[4],)
        cursor.execute(companies_table_insert_query, companies_data)
        company_id = cursor.lastrowid

        # print(f"Inserting row into customer_company: {row[1], company_id}\n")
        customer_company_data = (row[1], company_id)
        cursor.execute(customer_company_insert_query, customer_company_data)

        # print(f"Inserting row into locations: {row[1], row[5], row[6]}\n")
        locations_data = (row[1], row[5], row[6])
        cursor.execute(locations_table_insert_query, locations_data)

        # print(f"Inserting row into phones: {row[1], 'primary', row[7]}\n")
        primary_phone_primary_data = (row[1], 'primary', row[7])
        cursor.execute(phones_table_insert_query, primary_phone_primary_data)
 
        # print(f"Inserting row into phones: {row[1], 'secondary', row[8]}\n")
        primary_phone_secondary_data = (row[1], 'secondary', row[8])
        cursor.execute(phones_table_insert_query, primary_phone_secondary_data)

    conn.commit()
    conn.close()

except mariadb.Error as e:
    print(f"Error in MariaDB Platform: {e}")
    exit(1) 






finally:
    csvfile.close()

    current, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    # Time tracking
    end_time = time.time()
    elapsed = end_time - start_time

    # Print metrics
    print(f"\n--- Performance Metrics ---")
    print(f"Time elapsed: {elapsed:.4f} seconds")
    print(f"Time elapsed: {(elapsed/60):.4f} minutses")
    print(f"Peak memory usage: {peak / 1024:.2f} KB")
    print(f"CPU percent used: {process.cpu_percent()}%")
    print(f"Memory percent used: {process.memory_percent():.2f}%")