--This will be all the SQL code run for the setup of the target database.
--   customer_db
--   ├── customers (core identity + email/date)
--   ├── companies (deduplicated companies)
--   ├── customer_company (join table)
--   ├── locations (city/country per customer)
--   ├── phones (phone 1 and phone 2)


-- 📄customers
-- customer_id INT UNSIGNED PRIMARY KEY
-- 
-- first_name VARCHAR(100)
-- 
-- last_name VARCHAR(100)
-- 
-- email VARCHAR(255)
-- 
-- subscription_date DATE
-- 
-- 📄 companies
-- company_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
-- 
-- name VARCHAR(255) UNIQUE
-- 
-- website VARCHAR(255)
-- 
-- 📄 customer_company
-- customer_id INT UNSIGNED
-- 
-- company_id BIGINT UNSIGNED
-- 
-- PRIMARY KEY (customer_id, company_id)
-- 
-- FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
-- 
-- FOREIGN KEY (company_id) REFERENCES companies(company_id)
-- 
-- 📄 locations
-- customer_id INT UNSIGNED PRIMARY KEY
-- 
-- city VARCHAR(100)
-- 
-- country VARCHAR(100)
-- 
-- FOREIGN KEY (customer_id) REFERENCES customers(customer_id)

CREATE DATABASE targetDB;

USE targetDB;


--create user 
--ps:pwd and usn are temp
CREATE USER 'user'@'localhost' IDENTIFIED BY 'dbpwd';
GRANT ALL PRIVILEGES ON targetDB.* TO 'user'@'localhost';
FLUSH PRIVILEGES;


--Create tables
CREATE TABLE customers (
  customer_id VARCHAR(50) PRIMARY KEY,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email VARCHAR(255),
  subscription_date DATE,
  website VARCHAR(255)
) ENGINE=InnoDB;



CREATE TABLE companies (
  company_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) UNIQUE
) ENGINE=InnoDB;



CREATE TABLE customer_company (
  customer_id VARCHAR(50),
  company_id BIGINT UNSIGNED,
  PRIMARY KEY (customer_id, company_id),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  FOREIGN KEY (company_id) REFERENCES companies(company_id)
) ENGINE=InnoDB;



CREATE TABLE locations (
  customer_id VARCHAR(50) PRIMARY KEY,
  city VARCHAR(100),
  country VARCHAR(100),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;



CREATE TABLE phones (
  customer_id VARCHAR(50),
  phone_type ENUM('primary', 'secondary'),
  phone_number VARCHAR(50),
  PRIMARY KEY (customer_id, phone_type),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;


--Some queries for debugging and testing
--All entries in the tables
SELECT * FROM customers; 
SELECT * FROM companies; 
SELECT * FROM customer_company; 
SELECT * FROM locations; 
SELECT * FROM phones;

--Count of entries in the tables
SELECT COUNT(*) FROM customers; 
SELECT COUNT(*) FROM companies; 
SELECT COUNT(*) FROM customer_company; 
SELECT COUNT(*) FROM locations; 
SELECT COUNT(*) FROM phones;

--Delete all entries in the tables
DELETE FROM phones;
DELETE FROM locations;
DELETE FROM customer_company;
DELETE FROM companies;
DELETE FROM customers;

--Describe the tables
DESCRIBE customers;
DESCRIBE companies;
DESCRIBE customer_company;
DESCRIBE locations;
DESCRIBE phones;