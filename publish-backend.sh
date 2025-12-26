#!/bin/bash
# Bash script to publish backend to GitHub
# Run this script from the project root directory

echo "🚀 Publishing Backend to GitHub..."
echo ""

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed or not in PATH"
    echo "Please install Git from https://git-scm.com/download/"
    exit 1
fi

echo "✅ Git found: $(git --version)"
echo ""

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "❌ Not a git repository"
    echo "Initializing git repository..."
    git init
    echo "✅ Git repository initialized"
fi

# Check current branch
current_branch=$(git branch --show-current 2>/dev/null || echo "main")
if [ -z "$current_branch" ]; then
    echo "Creating main branch..."
    git checkout -b main
    current_branch="main"
fi
echo "Current branch: $current_branch"
echo ""

# Check git status
echo "📋 Checking git status..."
git status --short
echo ""

# Add backend files
echo "➕ Adding backend files..."
git add backend/
if [ $? -eq 0 ]; then
    echo "✅ Backend files added"
else
    echo "⚠️  Some files may not have been added"
fi
echo ""

# Check what will be committed
echo "📦 Files to be committed:"
git status --short
echo ""

# Commit changes
echo "💾 Committing changes..."
commit_message="Add backend implementation with Spotify OAuth integration"
git commit -m "$commit_message"

if [ $? -eq 0 ]; then
    echo "✅ Changes committed successfully"
else
    echo "⚠️  Commit may have failed or nothing to commit"
    echo "Checking status..."
    git status
fi
echo ""

# Check if remote is configured
remote_url=$(git remote get-url origin 2>/dev/null)
if [ -n "$remote_url" ]; then
    echo "🌐 Remote configured: $remote_url"
    echo ""
    
    # Push to remote
    echo "📤 Pushing to remote..."
    git push -u origin "$current_branch"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Successfully pushed to GitHub!"
        echo "Branch: $current_branch"
        echo "Remote: $remote_url"
    else
        echo ""
        echo "❌ Push failed. Common issues:"
        echo "  1. Authentication required (use Personal Access Token)"
        echo "  2. Remote branch doesn't exist (create it on GitHub first)"
        echo "  3. Network connectivity issues"
        echo ""
        echo "Try manually: git push -u origin $current_branch"
    fi
else
    echo "⚠️  No remote configured"
    echo ""
    echo "To add a remote:"
    echo "  git remote add origin https://github.com/yourusername/your-repo.git"
    echo ""
    echo "Then push:"
    echo "  git push -u origin $current_branch"
fi

echo ""
echo "✨ Done!"

