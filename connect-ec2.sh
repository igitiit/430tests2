#!/bin/bash
# Save as connect-ec2.sh

# Replace this with your instance name tag
INSTANCE_NAME="django-blog-server"

# Get instance ID using the Name tag
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "Error: Could not find running EC2 instance with name ${INSTANCE_NAME}"
    exit 1
fi

# Get the public IP using the instance ID
EC2_IP=$(aws ec2 describe-instances \
    --instance-ids ${INSTANCE_ID} \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

if [ "$EC2_IP" == "None" ] || [ -z "$EC2_IP" ]; then
    echo "Error: Could not get public IP for instance ${INSTANCE_ID}"
    exit 1
fi

echo "Connecting to instance ${INSTANCE_ID} at ${EC2_IP}..."

# Connect using the retrieved IP
ssh -t -i blog_project.pem ubuntu@${EC2_IP} "export TERM=xterm-256color; bash -l"
