provider "aws" {
  region = "ap-south-1"
}

# Random ID for unique S3 bucket name
resource "random_id" "bucket_id" {
  byte_length = 4
}

# S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "yashas-unique-bucket-${random_id.bucket_id.hex}"
}

# Upload CSV file to S3
resource "aws_s3_object" "data_file" {
  bucket = aws_s3_bucket.bucket.bucket
  key    = "customers-100.csv"
  source = "./customers-100.csv"
  etag   = filemd5("./customers-100.csv")
}

# VPC and Subnet Data
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Subnet Group for RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Open to all for testing
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Variables
variable "db_user" {}
variable "db_pass" {}

# RDS MySQL Instance
resource "aws_db_instance" "mysql_db" {
  identifier             = "db-4fd324fwe"
  engine                 = "mysql"
  engine_version         = "8.4.6"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_user
  password               = var.db_pass
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
}

# Null resource to run init.sql after DB is ready
resource "null_resource" "run_sql_script" {
  depends_on = [aws_db_instance.mysql_db]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      sleep 60
      mysql -h ${aws_db_instance.mysql_db.address} \
            -u ${var.db_user} \ 
            -p ${var.db_pass} \ 
            < init.sql
    EOT
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policies for Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy" "lambda_rds_policy" {
  name = "lambda-rds-write-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "rds-data:ExecuteStatement",
        "rds-data:BatchExecuteStatement",
        "rds-data:BeginTransaction",
        "rds-data:CommitTransaction",
        "rds-data:RollbackTransaction"
      ],
      Resource = "*"
    }]
  })
}

# Lambda Layer
resource "aws_lambda_layer_version" "my_layer" {
  filename            = "layer.zip"
  layer_name          = "etl-layer"
  compatible_runtimes = ["python3.12"]
}

# Lambda Function
resource "aws_lambda_function" "my_lambda" {
  function_name = "simpleETL"
  runtime       = "python3.12"
  handler       = "lambda_function.handler"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = 10

  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  layers = [aws_lambda_layer_version.my_layer.arn]

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_s3,
    aws_iam_role_policy.lambda_rds_policy
  ]
}
