# PowerShell script to publish backend to GitHub
# Run this script from the project root directory

Write-Host "🚀 Publishing Backend to GitHub..." -ForegroundColor Cyan
Write-Host ""

# Check if git is available
try {
    $gitVersion = git --version
    Write-Host "✅ Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git from https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# Check if we're in a git repository
if (-not (Test-Path .git)) {
    Write-Host "❌ Not a git repository" -ForegroundColor Red
    Write-Host "Initializing git repository..." -ForegroundColor Yellow
    git init
    Write-Host "✅ Git repository initialized" -ForegroundColor Green
}

# Check current branch
$currentBranch = git branch --show-current
if (-not $currentBranch) {
    Write-Host "Creating main branch..." -ForegroundColor Yellow
    git checkout -b main
    $currentBranch = "main"
}
Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan
Write-Host ""

# Check git status
Write-Host "📋 Checking git status..." -ForegroundColor Cyan
git status --short
Write-Host ""

# Add backend files
Write-Host "➕ Adding backend files..." -ForegroundColor Cyan
git add backend/
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Backend files added" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some files may not have been added" -ForegroundColor Yellow
}
Write-Host ""

# Check what will be committed
Write-Host "📦 Files to be committed:" -ForegroundColor Cyan
git status --short
Write-Host ""

# Commit changes
Write-Host "💾 Committing changes..." -ForegroundColor Cyan
$commitMessage = "Add backend implementation with Spotify OAuth integration"
git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Changes committed successfully" -ForegroundColor Green
} else {
    Write-Host "⚠️  Commit may have failed or nothing to commit" -ForegroundColor Yellow
    Write-Host "Checking status..." -ForegroundColor Cyan
    git status
}
Write-Host ""

# Check if remote is configured
$remoteUrl = git remote get-url origin 2>$null
if ($remoteUrl) {
    Write-Host "🌐 Remote configured: $remoteUrl" -ForegroundColor Cyan
    Write-Host ""
    
    # Push to remote
    Write-Host "📤 Pushing to remote..." -ForegroundColor Cyan
    git push -u origin $currentBranch
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Successfully pushed to GitHub!" -ForegroundColor Green
        Write-Host "Branch: $currentBranch" -ForegroundColor Cyan
        Write-Host "Remote: $remoteUrl" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "❌ Push failed. Common issues:" -ForegroundColor Red
        Write-Host "  1. Authentication required (use Personal Access Token)" -ForegroundColor Yellow
        Write-Host "  2. Remote branch doesn't exist (create it on GitHub first)" -ForegroundColor Yellow
        Write-Host "  3. Network connectivity issues" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Try manually: git push -u origin $currentBranch" -ForegroundColor Cyan
    }
} else {
    Write-Host "⚠️  No remote configured" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To add a remote:" -ForegroundColor Cyan
    Write-Host "  git remote add origin https://github.com/yourusername/your-repo.git" -ForegroundColor White
    Write-Host ""
    Write-Host "Then push:" -ForegroundColor Cyan
    Write-Host "  git push -u origin $currentBranch" -ForegroundColor White
}

Write-Host ""
Write-Host "✨ Done!" -ForegroundColor Green

