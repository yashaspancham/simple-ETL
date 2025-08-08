#for mysql use %s instead of ?

customers_table_insert_query="""
INSERT IGNORE INTO customers (customer_id, first_name, last_name, email, subscription_date, website)
VALUES (%s, %s, %s, %s, %s, %s)
"""
companies_table_insert_query="""
INSERT IGNORE INTO companies (name)
VALUES (%s)
"""
customer_company_insert_query="""
INSERT IGNORE INTO customer_company (customer_id, company_id)
VALUES (%s, %s)
"""

locations_table_insert_query="""
INSERT IGNORE INTO locations (customer_id, city, country)
VALUES (%s, %s, %s)
"""
phones_table_insert_query="""
INSERT IGNORE INTO phones (customer_id, phone_type, phone_number)
VALUES (%s, %s, %s)
"""