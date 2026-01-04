# ============================================================================
# ANTIDOTE FLUTTER - LOCAL SETUP SCRIPT (PowerShell)
# ============================================================================
# This script guides you through the local deployment setup process
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Antidote Flutter - Local Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

$prerequisitesMet = $true

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found. Please install Node.js >= 18.0.0" -ForegroundColor Red
    Write-Host "  Download from: https://nodejs.org/" -ForegroundColor Gray
    $prerequisitesMet = $false
}

# Check Flutter
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "✓ Flutter: Installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter not found. Please install Flutter >= 3.16.0" -ForegroundColor Red
    Write-Host "  Download from: https://flutter.dev/docs/get-started/install" -ForegroundColor Gray
    $prerequisitesMet = $false
}

# Check Git
try {
    $gitVersion = git --version
    Write-Host "✓ Git: Installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Git not found. Please install Git" -ForegroundColor Red
    Write-Host "  Download from: https://git-scm.com/" -ForegroundColor Gray
    $prerequisitesMet = $false
}

Write-Host ""

if (-not $prerequisitesMet) {
    Write-Host "Please install missing prerequisites and run this script again." -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "STEP 1: Supabase Setup" -ForegroundColor Green
Write-Host "  1. Create account at https://app.supabase.com" -ForegroundColor White
Write-Host "  2. Create a new project" -ForegroundColor White
Write-Host "  3. Get your credentials from Settings → API" -ForegroundColor White
Write-Host "     - SUPABASE_URL" -ForegroundColor Gray
Write-Host "     - SUPABASE_ANON_KEY (for frontend)" -ForegroundColor Gray
Write-Host "     - SUPABASE_SERVICE_ROLE_KEY (for backend)" -ForegroundColor Gray
Write-Host ""

Write-Host "STEP 2: Spotify Developer Setup" -ForegroundColor Green
Write-Host "  1. Create account at https://developer.spotify.com/" -ForegroundColor White
Write-Host "  2. Create a new app" -ForegroundColor White
Write-Host "  3. Get your Client ID" -ForegroundColor White
Write-Host "  4. Add redirect URI: com.antidote.app://auth/callback" -ForegroundColor White
Write-Host ""

Write-Host "STEP 3: Backend Setup" -ForegroundColor Green
Write-Host "  1. Navigate to backend directory: cd backend" -ForegroundColor White
Write-Host "  2. Install dependencies: npm install" -ForegroundColor White
Write-Host "  3. Create .env file from env.example" -ForegroundColor White
Write-Host "  4. Fill in your credentials in .env" -ForegroundColor White
Write-Host ""

Write-Host "STEP 4: Frontend Setup" -ForegroundColor Green
Write-Host "  1. Navigate to frontend directory: cd frontend" -ForegroundColor White
Write-Host "  2. Install dependencies: flutter pub get" -ForegroundColor White
Write-Host "  3. Create .env.development file (see docs/LOCAL_DEPLOYMENT.md)" -ForegroundColor White
Write-Host "  4. Fill in your credentials" -ForegroundColor White
Write-Host ""

Write-Host "STEP 5: Database Setup" -ForegroundColor Green
Write-Host "  1. Open Supabase SQL Editor" -ForegroundColor White
Write-Host "  2. Run database/setup_complete.sql" -ForegroundColor White
Write-Host "  3. Verify with database/verify_setup.sql" -ForegroundColor White
Write-Host ""

Write-Host "STEP 6: Start Services" -ForegroundColor Green
Write-Host "  Terminal 1 (Backend):" -ForegroundColor White
Write-Host "    cd backend" -ForegroundColor Gray
Write-Host "    npm run dev" -ForegroundColor Gray
Write-Host ""
Write-Host "  Terminal 2 (Frontend):" -ForegroundColor White
Write-Host "    cd frontend" -ForegroundColor Gray
Write-Host "    flutter run" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Quick Commands" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend:" -ForegroundColor Yellow
Write-Host "  cd backend" -ForegroundColor White
Write-Host "  npm install          # Install dependencies" -ForegroundColor Gray
Write-Host "  npm run dev          # Start development server" -ForegroundColor Gray
Write-Host "  npm run build        # Build for production" -ForegroundColor Gray
Write-Host ""
Write-Host "Frontend:" -ForegroundColor Yellow
Write-Host "  cd frontend" -ForegroundColor White
Write-Host "  flutter pub get     # Install dependencies" -ForegroundColor Gray
Write-Host "  flutter run          # Run app" -ForegroundColor Gray
Write-Host "  flutter analyze     # Check for issues" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Documentation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "For detailed instructions, see:" -ForegroundColor Yellow
Write-Host "  docs/LOCAL_DEPLOYMENT.md" -ForegroundColor White
Write-Host ""
Write-Host "For troubleshooting, see the Troubleshooting section" -ForegroundColor Yellow
Write-Host "in LOCAL_DEPLOYMENT.md" -ForegroundColor White
Write-Host ""

Write-Host "Ready to start? Follow the steps above!" -ForegroundColor Green
Write-Host ""

