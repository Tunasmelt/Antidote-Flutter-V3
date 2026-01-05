# Security Policy

## ⚠️ CRITICAL SECURITY NOTICES

### Before Production Deployment

**This application requires the following security measures to be completed:**

## 🔴 MANDATORY Actions

### 1. Rotate All Exposed Credentials

**The following credentials have been committed to git and MUST be rotated:**

- ✅ Supabase URL and Keys
- ✅ Spotify Client ID and Secret
- ✅ Database credentials

**Actions Required:**
1. Go to Supabase Dashboard → Settings → API → Generate new keys
2. Go to Spotify Developer Dashboard → Your App → Settings → Reset client secret
3. Update all environment variables with new credentials
4. Remove old credentials from git history:
   ```bash
   git filter-branch --force --index-filter \
   "git rm --cached --ignore-unmatch backend/.env frontend/.env.* -r" \
   --prune-empty --tag-name-filter cat -- --all
   
   git push origin --force --all
   ```

### 2. Configure Production Environment Variables

**Backend (.env):**
```bash
# Server
NODE_ENV=production
PORT=5000

# Spotify (REQUIRED)
SPOTIFY_CLIENT_ID=your_new_client_id
SPOTIFY_CLIENT_SECRET=your_new_client_secret  # MUST BE SET

# Supabase (REQUIRED)
SUPABASE_URL=your_new_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_new_service_role_key

# Frontend URL for CORS
FRONTEND_URL=https://antidote.app

# Logging
LOG_LEVEL=info
```

**Frontend (.env.production):**
```bash
# Supabase
SUPABASE_URL=your_new_supabase_url
SUPABASE_ANON_KEY=your_new_anon_key

# API
API_BASE_URL=https://api.antidote.app  # MUST UPDATE WITH REAL URL

# Spotify
SPOTIFY_CLIENT_ID=your_new_client_id
SPOTIFY_REDIRECT_URI=com.antidote.app://auth/callback

# App
APP_NAME=Antidote v3
APP_VERSION=1.0.0
```

### 3. Install Security Dependencies

**Backend:**
```bash
cd backend
npm install helmet express-rate-limit express-validator winston
```

### 4. Security Headers

The CORS configuration has been updated to whitelist specific origins. Ensure you add your production domain to the whitelist in `backend/src/index.ts`.

### 5. Rate Limiting

Rate limiting is currently only applied to unauthenticated analysis/battle endpoints. Additional rate limiting needs to be added to:
- Auth endpoints (signin, signup, callback)
- Token refresh endpoint
- Global API rate limit

**Recommended:** Install `express-rate-limit` and apply to all sensitive endpoints.

### 6. Input Validation

Currently missing comprehensive input validation. **Required before production:**
- Install `express-validator`
- Add validation for all POST/PUT/PATCH endpoints
- Sanitize user inputs to prevent XSS/SQL injection

### 7. Monitoring and Logging

Currently using console.log/console.error. **Required before production:**
- Install `winston` for structured logging
- Set up error tracking (Sentry, LogRocket, etc.)
- Configure log aggregation service
- Set up alerts for critical errors

## 🟠 RECOMMENDED Actions

### 8. Health Checks

Implement comprehensive health checks that verify:
- Database connectivity
- External API availability (Spotify)
- System resources

### 9. Secret Management

Move from .env files to proper secret management:
- AWS Secrets Manager
- Azure Key Vault
- HashiCorp Vault
- Google Cloud Secret Manager

### 10. Security Audits

Before production:
- Run `npm audit` and fix all vulnerabilities
- Run Flutter security scan
- Conduct penetration testing
- Review all database queries for SQL injection risks
- Audit all user inputs for XSS vulnerabilities

## Reporting Security Issues

**DO NOT** open public GitHub issues for security vulnerabilities.

Email security concerns to: security@antidote.app

## Security Checklist

- [ ] All credentials rotated
- [ ] .env files removed from git history
- [ ] Production environment variables configured
- [ ] CORS whitelist updated with production domains
- [ ] Rate limiting added to all endpoints
- [ ] Input validation implemented
- [ ] Security headers configured (helmet)
- [ ] Proper logging and monitoring setup
- [ ] Health checks implemented
- [ ] npm audit shows 0 vulnerabilities
- [ ] Secret management solution in place
- [ ] Security audit completed

## Deployment Readiness

**Status: ⚠️ NOT READY FOR PRODUCTION**

Complete all items in the checklist above before deploying to production.
