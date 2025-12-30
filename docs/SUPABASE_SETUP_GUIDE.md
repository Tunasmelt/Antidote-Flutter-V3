# Supabase Setup Guide for Antidote Flutter

This guide covers all Supabase configurations needed for authentication and database operations.

## Table of Contents
1. [Database Setup](#database-setup)
2. [Authentication Configuration](#authentication-configuration)
3. [Spotify OAuth Setup](#spotify-oauth-setup)
4. [Redirect URLs Configuration](#redirect-urls-configuration)
5. [Edge Functions (Optional)](#edge-functions-optional)
6. [Verification Steps](#verification-steps)

---

## Database Setup

### Step 1: Run Database Schema
1. Go to your Supabase project: https://app.supabase.com
2. Navigate to **SQL Editor**
3. Run the following scripts in order:

```sql
-- 1. First, run schema.sql
-- This creates all tables (users, playlists, tracks, analyses, battles, recommendations)

-- 2. Then, run indexes.sql
-- This creates indexes for performance

-- 3. Then, run functions.sql
-- This creates database functions and triggers

-- 4. Then, run rls_policies.sql
-- This enables Row Level Security and creates policies

-- 5. Then, run enable_rls_source_tables.sql
-- This enables RLS on source tables for views

-- 6. Finally, run setup_complete.sql (optional - combines everything)
-- Or run verify_setup.sql to verify everything is set up correctly
```

**Files to run (in order):**
- `database/schema.sql`
- `database/indexes.sql`
- `database/functions.sql`
- `database/rls_policies.sql`
- `database/enable_rls_source_tables.sql`

**Verification:**
- Run `database/verify_setup.sql` to check everything is configured correctly

---

## Authentication Configuration

### Step 2: Enable Email/Password Authentication
1. Go to **Authentication** → **Providers** in Supabase Dashboard
2. Enable **Email** provider
3. Configure settings:
   - ✅ Enable email confirmations (optional, recommended for production)
   - ✅ Enable secure email change (optional)
   - Set email templates if needed

### Step 3: Configure Site URL and Redirect URLs
1. Go to **Authentication** → **URL Configuration**
2. Set **Site URL**: 
   - Development: `http://localhost` (for web) or your app scheme
   - Production: `https://yourdomain.com`
3. Add **Redirect URLs**:
   ```
   com.antidote.app://auth/callback
   com.antidote.app://reset-password
   http://localhost:3000/auth/callback
   https://yourdomain.com/auth/callback
   ```

---

## Spotify OAuth Setup

### Step 4: Configure Spotify OAuth Provider

**Important:** Supabase OAuth for Spotify requires special configuration because Spotify doesn't provide OAuth tokens directly through Supabase's standard OAuth flow.

#### Option A: Using Supabase OAuth (Simpler, but limited token access)

1. Go to **Authentication** → **Providers** in Supabase Dashboard
2. Find **Spotify** provider and enable it
3. Configure:
   - **Client ID**: Your Spotify Client ID (from Spotify Developer Dashboard)
   - **Client Secret**: Your Spotify Client Secret (from Spotify Developer Dashboard)
   - **Redirect URL**: Must match one of these:
     ```
     https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
     ```
   - **Scopes**: Add these scopes (space-separated):
     ```
     user-read-private user-read-email playlist-read-private playlist-read-collaborative user-library-read user-top-read user-read-recently-played
     ```

4. **Note:** With Supabase OAuth, the Spotify access token may not be directly accessible. You may need to use a different approach (see Option B).

#### Option B: Direct Spotify OAuth (Recommended for full token access)

Since Supabase OAuth may not expose Spotify tokens directly, you have two options:

**Option B1: Use Supabase Edge Function for Token Exchange**
- Create an edge function that exchanges the OAuth code for tokens
- Store tokens in user metadata or a separate table

**Option B2: Implement Direct Spotify OAuth in Flutter**
- Bypass Supabase OAuth for Spotify
- Use direct Spotify OAuth flow
- Store tokens in secure storage
- Still use Supabase for user authentication (email/password)

---

## Redirect URLs Configuration

### Step 5: Configure Deep Linking (Mobile Apps)

For Flutter mobile apps, you need to configure deep linking:

#### Android Configuration
1. In `android/app/src/main/AndroidManifest.xml`, add:
```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="com.antidote.app" />
    </intent-filter>
</activity>
```

#### iOS Configuration
1. In `ios/Runner/Info.plist`, add:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.antidote.app</string>
        </array>
    </dict>
</array>
```

#### Web Configuration
- For web, use standard HTTP/HTTPS redirect URLs
- Add to Supabase redirect URLs: `http://localhost:PORT/auth/callback`

---

## Edge Functions (Optional)

### Step 6: Create Edge Function for Spotify Token Refresh (Optional)

If you need to refresh Spotify tokens server-side, create a Supabase Edge Function:

1. Go to **Edge Functions** in Supabase Dashboard
2. Create a new function: `refresh-spotify-token`
3. Code:
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { refresh_token } = await req.json()
    
    const response = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: refresh_token,
        client_id: Deno.env.get('SPOTIFY_CLIENT_ID') || '',
      }),
    })
    
    const data = await response.json()
    
    return new Response(
      JSON.stringify(data),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
```

4. Add environment variable:
   - `SPOTIFY_CLIENT_ID`: Your Spotify Client ID

---

## Verification Steps

### Step 7: Verify Setup

1. **Check Database Tables:**
   ```sql
   -- Run in SQL Editor
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations');
   ```
   Should return 6 tables.

2. **Check RLS Policies:**
   ```sql
   SELECT tablename, policyname 
   FROM pg_policies 
   WHERE schemaname = 'public';
   ```
   Should show policies for all tables.

3. **Check Authentication:**
   - Go to **Authentication** → **Users**
   - Try creating a test user via email/password
   - Verify user appears in `public.users` table

4. **Check Spotify OAuth:**
   - Go to **Authentication** → **Providers** → **Spotify**
   - Verify it's enabled
   - Test OAuth flow (may need to test in app)

---

## Required Supabase Settings Summary

### Authentication Settings
- ✅ Email provider enabled
- ✅ Spotify OAuth provider enabled (with Client ID and Secret)
- ✅ Redirect URLs configured
- ✅ Site URL configured

### Database Settings
- ✅ All tables created (`users`, `playlists`, `tracks`, `analyses`, `battles`, `recommendations`)
- ✅ RLS enabled on all tables
- ✅ RLS policies created for all tables
- ✅ Indexes created for performance
- ✅ Functions and triggers created

### API Settings
- ✅ Get your **Project URL** and **Anon Key** from:
  - **Settings** → **API**
  - Use these in `.env.development` and `.env.production`
- ✅ Get your **Service Role Key** from:
  - **Settings** → **API**
  - Use this in backend `.env` (keep secret!)

---

## Important Notes

1. **Spotify OAuth Limitation:**
   - Supabase OAuth for Spotify may not provide direct access to Spotify tokens
   - The app tries to extract tokens from `session.providerToken`
   - If this doesn't work, you may need to implement direct Spotify OAuth

2. **Service Role Key:**
   - Only use in backend (never expose to frontend)
   - Bypasses RLS - use carefully
   - Required for backend operations that need admin access

3. **Anon Key:**
   - Safe to use in frontend
   - Respects RLS policies
   - Used in Flutter app

4. **Deep Linking:**
   - Must be configured for mobile apps
   - OAuth callbacks won't work without it

---

## Troubleshooting

### Issue: Spotify OAuth not working
- Check redirect URLs match exactly
- Verify Spotify Client ID and Secret are correct
- Check scopes are properly configured
- Verify deep linking is set up for mobile

### Issue: Users table not populating
- Check if `handle_new_user` trigger exists
- Verify RLS policies allow inserts
- Check Supabase logs for errors

### Issue: RLS blocking queries
- Verify user is authenticated
- Check RLS policies are correct
- Ensure `auth.uid()` matches `user_id` in queries

---

## Next Steps

After completing Supabase setup:
1. Update `.env.development` with your Supabase credentials
2. Update `backend/.env` with your Supabase Service Role Key
3. Test authentication flow in the app
4. Verify database operations work correctly

