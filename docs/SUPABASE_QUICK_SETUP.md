# Supabase Quick Setup Checklist

Use this checklist to quickly set up Supabase for Antidote Flutter.

## ✅ Step-by-Step Checklist

### 1. Database Setup (SQL Editor)
- [ ] Run `database/schema.sql` - Creates all tables
- [ ] Run `database/indexes.sql` - Creates indexes
- [ ] Run `database/functions.sql` - Creates functions and triggers
- [ ] Run `database/rls_policies.sql` - Enables RLS and creates policies
- [ ] Run `database/enable_rls_source_tables.sql` - Enables RLS on source tables
- [ ] Run `database/verify_setup.sql` - Verify everything is correct

### 2. Authentication Configuration
- [ ] Go to **Authentication** → **Providers**
- [ ] Enable **Email** provider
- [ ] Go to **Authentication** → **URL Configuration**
- [ ] Set **Site URL**: `http://localhost` (dev) or your production URL
- [ ] Add **Redirect URLs**:
  - `com.antidote.app://auth/callback`
  - `com.antidote.app://reset-password`
  - `http://localhost:PORT/auth/callback` (for web)

### 3. Spotify OAuth Setup
- [ ] Go to **Authentication** → **Providers** → **Spotify**
- [ ] Enable Spotify provider
- [ ] Enter **Client ID** (from Spotify Developer Dashboard)
- [ ] Enter **Client Secret** (from Spotify Developer Dashboard)
- [ ] Set **Redirect URL**: `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`
- [ ] Add **Scopes**:
  ```
  user-read-private user-read-email playlist-read-private playlist-read-collaborative user-library-read user-top-read user-read-recently-played
  ```

### 4. Get API Credentials
- [ ] Go to **Settings** → **API**
- [ ] Copy **Project URL** → Use in `.env.development` and `.env.production` as `SUPABASE_URL`
- [ ] Copy **anon public** key → Use in `.env.development` and `.env.production` as `SUPABASE_ANON_KEY`
- [ ] Copy **service_role** key → Use in `backend/.env` as `SUPABASE_SERVICE_ROLE_KEY` (keep secret!)

### 5. Test Setup
- [ ] Create a test user via email/password in Supabase Dashboard
- [ ] Verify user appears in `public.users` table (should be automatic via trigger)
- [ ] Test Spotify OAuth flow (may need to test in app)

## 🔑 Required Credentials

### From Supabase Dashboard:
1. **Project URL**: `https://xxxxx.supabase.co`
2. **Anon Key**: `eyJhbGc...` (public, safe for frontend)
3. **Service Role Key**: `eyJhbGc...` (secret, backend only!)

### From Spotify Developer Dashboard:
1. **Client ID**: `xxxxx...`
2. **Client Secret**: `xxxxx...`
3. **Redirect URI**: `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`

## 📝 Environment Variables to Update

### `antidote_flutter/.env.development`:
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SPOTIFY_CLIENT_ID=xxxxx...
API_BASE_URL=http://localhost:5000
SPOTIFY_REDIRECT_URI=com.antidote.app://auth/callback
```

### `backend/.env`:
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
SPOTIFY_CLIENT_ID=xxxxx...
```

## ⚠️ Important Notes

1. **Service Role Key is SECRET** - Never commit to git or expose to frontend
2. **Spotify OAuth** - Supabase OAuth may not expose tokens directly. The app tries to extract from session.
3. **Deep Linking** - Must be configured in Flutter for mobile OAuth callbacks
4. **RLS Policies** - Ensure all tables have RLS enabled and policies created

## 🐛 Common Issues

### Issue: User profile not created automatically
- **Fix**: Check that `handle_new_user` trigger exists in `functions.sql`
- **Verify**: Run `SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';`

### Issue: RLS blocking queries
- **Fix**: Ensure user is authenticated and RLS policies are correct
- **Verify**: Check policies with `SELECT * FROM pg_policies WHERE schemaname = 'public';`

### Issue: Spotify OAuth not working
- **Fix**: Verify redirect URLs match exactly, check Client ID/Secret
- **Verify**: Check Supabase logs for OAuth errors

## 📚 Full Documentation

See `SUPABASE_SETUP_GUIDE.md` for detailed explanations and troubleshooting.

