# Setting Up Django Blog with Docker and S3 Storage

## Prerequisites
1. EC2 instance running
2. blog_project.pem key file
3. AWS credentials configured locally (use `aws configure` if not set up)
4. Security group with ports 22 (SSH) and 80 (HTTP) open

## Step 1: Set Key Permissions
```bash
chmod 400 blog_project.pem
```

## Step 2: Verify AWS Credentials
```bash
aws configure list
```
Expected output should show credentials are configured.

## Step 3: Install Docker Compose
```bash
ssh -t -i blog_project.pem ubuntu@YOUR_EC2_IP "sudo apt update && sudo apt install docker-compose -y"
```
Replace YOUR_EC2_IP with your EC2 instance's public IP.

## Step 4: Deploy Container with AWS Credentials
Copy and paste this entire command block:
```bash
ssh -t -i blog_project.pem ubuntu@YOUR_EC2_IP \
    "AWS_ACCESS_KEY=$(aws configure get aws_access_key_id); \
    AWS_SECRET_KEY=$(aws configure get aws_secret_access_key); \
    sudo docker stop blog_web || true; \
    sudo docker rm blog_web || true; \
    sudo docker run -d --name blog_web \
    -p 80:8000 \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY \
    -e AWS_DEFAULT_REGION=us-east-1 \
    119922150720.dkr.ecr.us-east-1.amazonaws.com/blog_project-web:3f3406d3bc3b5c568188e88769ad341ac74f744d"
```

## Step 5: Verify Container Status
```bash
ssh -t -i blog_project.pem ubuntu@YOUR_EC2_IP "sudo docker ps"
```
Expected output should show container 'blog_web' running and port 80 mapped to 8000.

## Step 6: Check Container Logs
```bash
ssh -t -i blog_project.pem ubuntu@YOUR_EC2_IP "sudo docker logs blog_web"
```
Look for "FORCING S3 STORAGE BACKEND" message without errors.

## Accessing Your Blog
1. Open your web browser
2. Navigate to: `http://YOUR_EC2_IP`
3. You should see the blog post listing page

## Troubleshooting
If you see Nginx default page:
1. Clear browser cache
2. Try accessing explicitly with port: `http://YOUR_EC2_IP:80`
3. Check container logs for errors:
```bash
ssh -t -i blog_project.pem ubuntu@YOUR_EC2_IP "sudo docker logs blog_web"
```

## Expected Results
1. Web interface shows list of blog posts
2. Images from S3 load properly
3. No error messages in container logs

## Configuration Details
- Container port mapping: 80:8000
- S3 bucket: coursera-bucket3
- Region: us-east-1
- Image: Uses Django with Gunicorn
- Storage: AWS S3 for static and media files

## Security Notes
1. AWS credentials are pulled automatically from local configuration
2. No credentials are exposed in command history
3. Container runs with proper port mappings
4. EC2 security group must allow inbound traffic on ports 22 and 80
