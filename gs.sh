#!/bin/bash

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

echo "Working directory: $(pwd)"

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
