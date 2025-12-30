# Supabase Edge Function Setup for Spotify Token Refresh

This guide shows how to create the optional `refresh-spotify-token` Edge Function for refreshing Spotify access tokens.

## ⚠️ Note: This is Optional

The app will work without this Edge Function. If the function doesn't exist:
- Token refresh will fail gracefully
- Users will need to reconnect Spotify when tokens expire
- The app will prompt users to reconnect

However, creating this function provides a better user experience by automatically refreshing tokens.

---

## Step 1: Install Supabase CLI

### Windows (PowerShell):
```powershell
# Using Scoop
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Or using npm
npm install -g supabase
```

### macOS/Linux:
```bash
# Using Homebrew
brew install supabase/tap/supabase

# Or using npm
npm install -g supabase
```

---

## Step 2: Initialize Supabase Functions (if not already done)

```bash
# Navigate to your project root
cd C:\Users\ADMIN\Desktop\Antidote-Flutter

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF
```

---

## Step 3: Create the Edge Function

```bash
# Create the function
supabase functions new refresh-spotify-token
```

This creates a directory: `supabase/functions/refresh-spotify-token/`

---

## Step 4: Write the Function Code

Create/edit `supabase/functions/refresh-spotify-token/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Verify the user is authenticated
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get refresh token from request body
    const { refresh_token } = await req.json()
    if (!refresh_token) {
      return new Response(
        JSON.stringify({ error: 'Missing refresh_token' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get Spotify Client ID from environment
    const spotifyClientId = Deno.env.get('SPOTIFY_CLIENT_ID')
    if (!spotifyClientId) {
      return new Response(
        JSON.stringify({ error: 'Spotify Client ID not configured' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Refresh the token with Spotify
    const response = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: refresh_token,
        client_id: spotifyClientId,
      }),
    })

    if (!response.ok) {
      const errorData = await response.text()
      return new Response(
        JSON.stringify({ error: 'Failed to refresh token', details: errorData }),
        { 
          status: response.status, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const data = await response.json()
    
    return new Response(
      JSON.stringify({
        access_token: data.access_token,
        expires_in: data.expires_in || 3600,
        refresh_token: data.refresh_token || refresh_token, // Spotify may not return new refresh token
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
```

---

## Step 5: Set Environment Variables

You need to set the `SPOTIFY_CLIENT_ID` secret for the function:

### Option A: Using Supabase Dashboard
1. Go to **Edge Functions** → **refresh-spotify-token**
2. Click **Settings** or **Manage secrets**
3. Add secret: `SPOTIFY_CLIENT_ID` = `your_spotify_client_id`

### Option B: Using Supabase CLI
```bash
# Set the secret
supabase secrets set SPOTIFY_CLIENT_ID=your_spotify_client_id --project-ref YOUR_PROJECT_REF
```

---

## Step 6: Deploy the Function

```bash
# Deploy the function
supabase functions deploy refresh-spotify-token --project-ref YOUR_PROJECT_REF
```

Or deploy from the Supabase Dashboard:
1. Go to **Edge Functions**
2. Click **Deploy** or **Create function**
3. Upload the function code

---

## Step 7: Test the Function

### Using Supabase Dashboard:
1. Go to **Edge Functions** → **refresh-spotify-token**
2. Click **Invoke**
3. Test with a sample request:
```json
{
  "refresh_token": "your_test_refresh_token"
}
```

### Using curl:
```bash
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/refresh-spotify-token' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"refresh_token": "your_test_refresh_token"}'
```

---

## Alternative: Direct Client-Side Refresh (No Edge Function)

If you don't want to use an Edge Function, you can modify the app to refresh tokens directly from the client. However, this requires exposing the Spotify Client Secret, which is **NOT RECOMMENDED**.

The current implementation gracefully handles the missing Edge Function by:
1. Trying to refresh via Supabase OAuth first
2. Falling back to the Edge Function
3. If both fail, prompting the user to reconnect

---

## Troubleshooting

### Issue: Function returns 401 Unauthorized
- **Fix**: Ensure the Authorization header includes a valid Supabase JWT token
- **Verify**: Check that the user is authenticated in the app

### Issue: Function returns 500 - Spotify Client ID not configured
- **Fix**: Set the `SPOTIFY_CLIENT_ID` secret in Supabase Dashboard
- **Verify**: Check Edge Function secrets in Dashboard

### Issue: Function returns 400 - Failed to refresh token
- **Fix**: The refresh token may be invalid or expired
- **Verify**: User needs to reconnect Spotify

### Issue: CORS errors
- **Fix**: Ensure CORS headers are included in the response
- **Verify**: Check the function code includes `corsHeaders`

---

## Security Notes

1. **Never expose Spotify Client Secret** - Only Client ID is needed
2. **Function requires authentication** - Users must be logged in to Supabase
3. **Refresh tokens are sensitive** - Handle them securely
4. **Rate limiting** - Consider adding rate limiting to prevent abuse

---

## Next Steps

After deploying the function:
1. Test token refresh in the app
2. Monitor function logs in Supabase Dashboard
3. Verify tokens are refreshed automatically
4. Check that users don't need to reconnect frequently

