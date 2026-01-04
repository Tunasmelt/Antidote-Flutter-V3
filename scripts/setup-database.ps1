# ============================================================================
# ANTIDOTE FLUTTER - DATABASE SETUP SCRIPT (PowerShell)
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

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Antidote Database Setup Guide" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script provides instructions for setting up your database." -ForegroundColor Yellow
Write-Host ""

Write-Host "STEP 1: Open Supabase SQL Editor" -ForegroundColor Green
Write-Host "  Go to: https://app.supabase.com/project/YOUR_PROJECT/sql" -ForegroundColor White
Write-Host ""

Write-Host "STEP 2: Run SQL Scripts in Order" -ForegroundColor Green
Write-Host "  Option A: Run setup_complete.sql (recommended - does everything)" -ForegroundColor White
Write-Host "    File: database/setup_complete.sql" -ForegroundColor Gray
Write-Host ""
Write-Host "  Option B: Run scripts individually:" -ForegroundColor White
Write-Host "    1. database/schema.sql" -ForegroundColor Gray
Write-Host "    2. database/indexes.sql" -ForegroundColor Gray
Write-Host "    3. database/functions.sql" -ForegroundColor Gray
Write-Host "    4. database/rls_policies.sql" -ForegroundColor Gray
Write-Host "    5. database/enable_rls_source_tables.sql" -ForegroundColor Gray
Write-Host ""

Write-Host "STEP 3: Verify Setup" -ForegroundColor Green
Write-Host "  Run: database/verify_setup.sql" -ForegroundColor White
Write-Host "  This will check that all tables, views, and policies are created correctly." -ForegroundColor Gray
Write-Host ""

Write-Host "STEP 4: Get Your Credentials" -ForegroundColor Green
Write-Host "  After setup, get your credentials from:" -ForegroundColor White
Write-Host "  https://app.supabase.com/project/YOUR_PROJECT/settings/api" -ForegroundColor Gray
Write-Host "  - SUPABASE_URL" -ForegroundColor Gray
Write-Host "  - SUPABASE_ANON_KEY (for frontend)" -ForegroundColor Gray
Write-Host "  - SUPABASE_SERVICE_ROLE_KEY (for backend)" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Update frontend/.env.development with your Supabase credentials" -ForegroundColor White
Write-Host "  2. Update backend/.env with your Supabase credentials" -ForegroundColor White
Write-Host "  3. Continue with local deployment setup" -ForegroundColor White
Write-Host ""

