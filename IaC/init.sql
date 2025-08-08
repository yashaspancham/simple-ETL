CREATE DATABASE helloDB;

USE helloDB;

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