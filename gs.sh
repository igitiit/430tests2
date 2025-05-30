#!/bin/bash

# Store the absolute path of the script
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Ensure valid execution path
if [[ ! "$PWD" == "$script_dir"* ]]; then
    echo "Error: Please run this script within $script_dir or its subdirectories."
    exit 1
fi

# Move to the git repository root
cd "$script_dir"

# Check if it's a valid git repository
if [ ! -d ".git" ]; then
    echo "Error: Not a valid git repository. Missing .git directory."
    exit 1
fi

# Check for changes
if git status --porcelain | grep -q '^'; then
    echo "Changes detected. Proceeding with commit..."
else
    echo "No changes to commit. Exiting."
    exit 0
fi

# Add all changes
git add --all

# Prompt for commit message
echo "Enter commit message:"
read commit_message

# Commit changes
git commit -m "$commit_message"

# Push to main branch
git push origin main

echo "Git operations completed successfully!"
