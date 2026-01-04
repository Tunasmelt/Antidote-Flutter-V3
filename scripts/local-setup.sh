#!/bin/bash
# ============================================================================
# ANTIDOTE FLUTTER - LOCAL SETUP SCRIPT (Bash)
# ============================================================================
# This script guides you through the local deployment setup process
# ============================================================================

echo "========================================"
echo "Antidote Flutter - Local Setup"
echo "========================================"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
echo ""

PREREQUISITES_MET=true

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✓ Node.js: $NODE_VERSION"
else
    echo "✗ Node.js not found. Please install Node.js >= 18.0.0"
    echo "  Download from: https://nodejs.org/"
    PREREQUISITES_MET=false
fi

# Check Flutter
if command -v flutter &> /dev/null; then
    echo "✓ Flutter: Installed"
else
    echo "✗ Flutter not found. Please install Flutter >= 3.16.0"
    echo "  Download from: https://flutter.dev/docs/get-started/install"
    PREREQUISITES_MET=false
fi

# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo "✓ Git: Installed"
else
    echo "✗ Git not found. Please install Git"
    echo "  Download from: https://git-scm.com/"
    PREREQUISITES_MET=false
fi

echo ""

if [ "$PREREQUISITES_MET" = false ]; then
    echo "Please install missing prerequisites and run this script again."
    exit 1
fi

echo "========================================"
echo "Setup Steps"
echo "========================================"
echo ""

echo "STEP 1: Supabase Setup"
echo "  1. Create account at https://app.supabase.com"
echo "  2. Create a new project"
echo "  3. Get your credentials from Settings → API"
echo "     - SUPABASE_URL"
echo "     - SUPABASE_ANON_KEY (for frontend)"
echo "     - SUPABASE_SERVICE_ROLE_KEY (for backend)"
echo ""

echo "STEP 2: Spotify Developer Setup"
echo "  1. Create account at https://developer.spotify.com/"
echo "  2. Create a new app"
echo "  3. Get your Client ID"
echo "  4. Add redirect URI: com.antidote.app://auth/callback"
echo ""

echo "STEP 3: Backend Setup"
echo "  1. Navigate to backend directory: cd backend"
echo "  2. Install dependencies: npm install"
echo "  3. Create .env file from env.example"
echo "  4. Fill in your credentials in .env"
echo ""

echo "STEP 4: Frontend Setup"
echo "  1. Navigate to frontend directory: cd frontend"
echo "  2. Install dependencies: flutter pub get"
echo "  3. Create .env.development file (see docs/LOCAL_DEPLOYMENT.md)"
echo "  4. Fill in your credentials"
echo ""

echo "STEP 5: Database Setup"
echo "  1. Open Supabase SQL Editor"
echo "  2. Run database/setup_complete.sql"
echo "  3. Verify with database/verify_setup.sql"
echo ""

echo "STEP 6: Start Services"
echo "  Terminal 1 (Backend):"
echo "    cd backend"
echo "    npm run dev"
echo ""
echo "  Terminal 2 (Frontend):"
echo "    cd frontend"
echo "    flutter run"
echo ""

echo "========================================"
echo "Quick Commands"
echo "========================================"
echo ""
echo "Backend:"
echo "  cd backend"
echo "  npm install          # Install dependencies"
echo "  npm run dev          # Start development server"
echo "  npm run build        # Build for production"
echo ""
echo "Frontend:"
echo "  cd frontend"
echo "  flutter pub get     # Install dependencies"
echo "  flutter run          # Run app"
echo "  flutter analyze     # Check for issues"
echo ""

echo "========================================"
echo "Documentation"
echo "========================================"
echo ""
echo "For detailed instructions, see:"
echo "  docs/LOCAL_DEPLOYMENT.md"
echo ""
echo "For troubleshooting, see the Troubleshooting section"
echo "in LOCAL_DEPLOYMENT.md"
echo ""

echo "Ready to start? Follow the steps above!"
echo ""

