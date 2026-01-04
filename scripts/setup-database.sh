#!/bin/bash
# ============================================================================
# ANTIDOTE FLUTTER - DATABASE SETUP SCRIPT (Bash)
# ============================================================================
# This script helps you set up the Antidote database in Supabase
# 
# PREREQUISITES:
# 1. Supabase project created at https://app.supabase.com
# 2. SQL scripts in the database/ directory
#
# USAGE:
# 1. Open Supabase SQL Editor: https://app.supabase.com/project/YOUR_PROJECT/sql
# 2. Run each SQL script in order (or use setup_complete.sql for all-in-one)
# 3. Verify setup with verify_setup.sql
# ============================================================================

echo "========================================"
echo "Antidote Database Setup Guide"
echo "========================================"
echo ""

echo "This script provides instructions for setting up your database."
echo ""

echo "STEP 1: Open Supabase SQL Editor"
echo "  Go to: https://app.supabase.com/project/YOUR_PROJECT/sql"
echo ""

echo "STEP 2: Run SQL Scripts in Order"
echo "  Option A: Run setup_complete.sql (recommended - does everything)"
echo "    File: database/setup_complete.sql"
echo ""
echo "  Option B: Run scripts individually:"
echo "    1. database/schema.sql"
echo "    2. database/indexes.sql"
echo "    3. database/functions.sql"
echo "    4. database/rls_policies.sql"
echo "    5. database/enable_rls_source_tables.sql"
echo ""

echo "STEP 3: Verify Setup"
echo "  Run: database/verify_setup.sql"
echo "  This will check that all tables, views, and policies are created correctly."
echo ""

echo "STEP 4: Get Your Credentials"
echo "  After setup, get your credentials from:"
echo "  https://app.supabase.com/project/YOUR_PROJECT/settings/api"
echo "  - SUPABASE_URL"
echo "  - SUPABASE_ANON_KEY (for frontend)"
echo "  - SUPABASE_SERVICE_ROLE_KEY (for backend)"
echo ""

echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Update frontend/.env.development with your Supabase credentials"
echo "  2. Update backend/.env with your Supabase credentials"
echo "  3. Continue with local deployment setup"
echo ""

