#!/bin/bash

# Local GitHub Actions Workflow Tester
# Usage: ./tester.sh [workflow_file] [--dry-run]
# Example: ./tester.sh django.yml
#          ./tester.sh deploy.yml --dry-run

set -e  # Exit on any error

# Get the absolute path to the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$WORKFLOW_DIR/../.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_step() {
    echo -e "${GREEN}==> $1${NC}"
}

echo_info() {
    echo -e "${BLUE}==> $1${NC}"
}

echo_error() {
    echo -e "${RED}==> $1${NC}"
}

simulate_deploy() {
    echo_info "[DRY RUN] Simulating deployment workflow steps:"
    
    # Change to project root for Docker context
    cd "$PROJECT_ROOT"
    
    echo_info "1. AWS Credential Check"
    aws sts get-caller-identity || {
        echo_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    }

    echo_info "2. ECR Login Simulation"
    aws ecr get-login-password --region us-east-1 > /dev/null 2>&1 || {
        echo_error "Failed to simulate ECR login. Check AWS permissions."
        exit 1
    }

    echo_info "3. Docker Build Configuration Check"
    if [ -f Dockerfile ]; then
        echo_info "Found Dockerfile, validating..."
        # Use hadolint if available, otherwise just check file exists
        if command -v hadolint >/dev/null 2>&1; then
            hadolint Dockerfile || {
                echo_error "Dockerfile validation failed"
                exit 1
            }
        else
            echo_info "hadolint not found, skipping detailed Dockerfile validation"
            echo_info "Checking basic Docker configuration..."
            # Check if docker is available
            docker info >/dev/null 2>&1 || {
                echo_error "Docker is not running or not installed"
                exit 1
            }
        fi
    else
        echo_error "Dockerfile not found in project root"
        exit 1
    fi

    echo_info "4. EC2 Instance Check Simulation"
    aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=MyEC2Instance" \
        --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress]" \
        --output text || {
        echo_error "Failed to query EC2 instance. Check AWS permissions or instance existence."
        exit 1
    }

    echo_info "5. Simulating ECR Image Tag Generation"
    SAMPLE_IMAGE_TAG=$(git rev-parse HEAD 2>/dev/null || echo "sample-sha")
    echo_info "Would build and push image with tag: $SAMPLE_IMAGE_TAG"

    echo_step "Deployment workflow dry run completed successfully! ✅"
}

run_django_tests() {
    echo_step "Running Django workflow steps:"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    echo_step "Setting up environment variables"
    export CI=true
    export DJANGO_SETTINGS_MODULE=blog_project.local_settings

    echo_step "Setting up Python virtual environment"
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    source venv/bin/activate

    echo_step "Installing dependencies"
    pip install -r requirements.txt

    echo_step "Running Django system checks"
    python3 blog_project/manage.py check

    echo_step "Running tests"
    python3 blog_project/manage.py test blog
}

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: ./tester.sh [workflow_file] [--dry-run]"
    echo "Available workflow files:"
    ls "$WORKFLOW_DIR"/*.yml 2>/dev/null | xargs -n 1 basename 2>/dev/null || echo "No workflow files found"
    exit 1
fi

WORKFLOW_FILE="$WORKFLOW_DIR/$1"
DRY_RUN=false

if [ "$2" = "--dry-run" ]; then
    DRY_RUN=true
fi

if [ ! -f "$WORKFLOW_FILE" ]; then
    echo_error "Workflow file $1 not found!"
    exit 1
fi

echo_step "Testing workflow: $1"

case "$1" in
    "django.yml")
        run_django_tests
        ;;
    "deploy.yml")
        if [ "$DRY_RUN" = true ]; then
            simulate_deploy
        else
            echo_error "Deploy workflow must be run with --dry-run flag for safety"
            exit 1
        fi
        ;;
    *)
        echo_error "Unsupported workflow file: $1"
        exit 1
        ;;
esac

if [ $? -eq 0 ]; then
    echo_step "Workflow completed successfully! ✅"
else
    echo_error "Workflow failed! ❌"
    exit 1
fi
