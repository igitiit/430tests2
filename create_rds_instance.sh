#!/bin/bash

# Create DB Instance for MySQL using AWS RDS

# References

# https://docs.aws.amazon.com/cli/latest/reference/rds/#cli-aws-rds
# https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html

# Set variables
DB_INSTANCE_IDENTIFIER="coursera-mysql-instance"
DB_NAME="blog_db"
MASTER_USERNAME="coursera"
MASTER_PASSWORD="coursera"
DB_INSTANCE_CLASS="db.t3.micro"
ENGINE="mysql"
ENGINE_VERSION="8.0.37"
ALLOCATED_STORAGE=20

# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --db-name $DB_NAME \
    --engine $ENGINE \
    --engine-version $ENGINE_VERSION \
    --db-instance-class $DB_INSTANCE_CLASS \
    --allocated-storage $ALLOCATED_STORAGE \
    --master-username $MASTER_USERNAME \
    --master-user-password $MASTER_PASSWORD \
    --publicly-accessible

# *Wait for the instance to be available
aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_IDENTIFIER

# Get the endpoint
ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --query "DBInstances[0].Endpoint.Address" --output text)
echo "RDS MySQL instance created. Endpoint: $ENDPOINT"
