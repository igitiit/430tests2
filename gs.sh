#!/bin/bash

# Navigate to the project root directory (modify the path accordingly)
cd path/to/your/project
echo "Working directory: $(pwd)"

# Check if there are any changes to add
# if git diff-index --quiet HEAD --; then

# Check if there are any changes (including untracked files)
if [[ -z $(git status --porcelain) ]]; then
echo "No changes to commit."
else
# Add all changes to the staging area
git add -A

# Prompt the user for a commit message
echo "Enter the commit message:"
read commitMessage

# Commit the changes
git commit -m "$commitMessage"

# Push the changes to the main branch
if git push origin main; then
echo "Push successful."
else
echo "Push failed."
fi
fi
