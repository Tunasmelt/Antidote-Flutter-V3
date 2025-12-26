# Render Deployment Guide

Complete guide for deploying the Antidote backend to Render.

## 🚀 Quick Deploy (5 minutes)

### Step 1: Prepare Your Code

Make sure your backend code is in a GitHub repository:

```bash
# If not already in a repo
cd backend
git init
git add .
git commit -m "Initial backend setup"
git remote add origin https://github.com/yourusername/antidote-backend.git
git push -u origin main
```

### Step 2: Create Render Account

1. Go to https://render.com
2. Sign up with GitHub (recommended for easy deployment)
3. Authorize Render to access your repositories

### Step 3: Create Web Service

1. Click **"New +"** → **"Web Service"**
2. Connect your GitHub repository
3. Select the repository with your backend code
4. Configure the service:

**Basic Settings:**
- **Name:** `antidote-backend` (or your preferred name)
- **Region:** Choose closest to your users
- **Branch:** `main` (or your default branch)
- **Root Directory:** `backend` (if backend is in a subdirectory)

**Build & Deploy:**
- **Runtime:** `Node`
- **Build Command:** `npm install && npm run build`
- **Start Command:** `npm start`

**Environment Variables:**
Click **"Add Environment Variable"** and add:

```bash
SPOTIFY_CLIENT_ID=your_spotify_client_id_here
PORT=10000
NODE_ENV=production
```

**Important:** Render uses port `10000` by default, or check the `PORT` environment variable.

### Step 4: Deploy

1. Click **"Create Web Service"**
2. Render will automatically:
   - Clone your repo
   - Install dependencies
   - Build your app
   - Deploy it
3. Wait for deployment to complete (~2-3 minutes)

### Step 5: Get Your URL

Once deployed, you'll get a URL like:
```
https://antidote-backend.onrender.com
```

**Update your Flutter app** with this URL in `env_config.dart`:
```dart
API_BASE_URL=https://antidote-backend.onrender.com
```

---

## 📋 Detailed Configuration

### Build Settings

**Build Command:**
```bash
npm install && npm run build
```

**Start Command:**
```bash
npm start
```

**Alternative (if using ts-node-dev for dev):**
```bash
# Build command
npm install && npm run build

# Start command  
node dist/index.js
```

### Environment Variables

Required environment variables in Render dashboard:

| Variable | Value | Description |
|----------|-------|-------------|
| `SPOTIFY_CLIENT_ID` | Your Client ID | Spotify Client ID (public) |
| `PORT` | `10000` | Render's default port |
| `NODE_ENV` | `production` | Environment mode |

**Optional:**
- `DATABASE_URL` - If using a database
- `SUPABASE_URL` - If using Supabase
- `SUPABASE_SERVICE_KEY` - If using Supabase

### Port Configuration

Update your `src/index.ts` to use Render's port:

```typescript
const PORT = process.env.PORT || 5000;
```

Render automatically sets `PORT` environment variable, so this will work automatically.

---

## 🔧 Render-Specific Considerations

### 1. Service Sleep (Free Tier)

**Issue:** Free tier services sleep after 15 minutes of inactivity.

**Solution:**
- Use **UptimeRobot** (free) to ping your service every 5 minutes
- Or upgrade to paid tier ($7/month) for always-on

**UptimeRobot Setup:**
1. Sign up at https://uptimerobot.com
2. Add new monitor:
   - Type: HTTP(s)
   - URL: `https://your-app.onrender.com/health`
   - Interval: 5 minutes
3. This keeps your service awake

### 2. Cold Start Delay

**Issue:** After sleep, first request takes ~30 seconds.

**Solution:**
- Acceptable for free tier
- Or implement request queuing in Flutter app
- Or upgrade to paid tier

### 3. Build Timeout

**Issue:** Builds may timeout on free tier (limited resources).

**Solution:**
- Optimize dependencies
- Use `npm ci` instead of `npm install` (faster)
- Remove unused packages

### 4. Health Check Endpoint

Make sure you have a health check endpoint (already in code):

```typescript
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
```

This is used by UptimeRobot to keep service awake.

---

## 📝 Deployment Checklist

- [ ] Code pushed to GitHub
- [ ] Render account created
- [ ] Web service created
- [ ] Environment variables set
- [ ] Build command configured
- [ ] Start command configured
- [ ] Service deployed successfully
- [ ] Health endpoint tested
- [ ] API endpoints tested
- [ ] Flutter app updated with new URL
- [ ] UptimeRobot configured (optional)

---

## 🧪 Testing Your Deployment

### 1. Test Health Endpoint

```bash
curl https://your-app.onrender.com/health
```

Should return:
```json
{"status":"ok","timestamp":"2025-01-XX..."}
```

### 2. Test API Endpoint

```bash
# Get token from Flutter app after Spotify OAuth
TOKEN="your_user_token"

curl -X POST https://your-app.onrender.com/api/analyze \
  -H "Content-Type: application/json" \
  -H "X-Spotify-Token: $TOKEN" \
  -d '{"url": "https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd"}'
```

### 3. Check Logs

In Render dashboard:
- Go to your service
- Click **"Logs"** tab
- View real-time logs
- Check for errors

---

## 🔍 Troubleshooting

### Build Fails

**Error:** "Build command failed"

**Solutions:**
1. Check build logs in Render dashboard
2. Verify `package.json` has build script:
   ```json
   "scripts": {
     "build": "tsc"
   }
   ```
3. Ensure TypeScript compiles without errors locally
4. Check Node version compatibility

### Service Won't Start

**Error:** "Service failed to start"

**Solutions:**
1. Check start command: `npm start`
2. Verify `package.json` has start script:
   ```json
   "scripts": {
     "start": "node dist/index.js"
   }
   ```
3. Check logs for specific error
4. Verify port is set correctly (Render uses PORT env var)

### Environment Variables Not Working

**Error:** "SPOTIFY_CLIENT_ID is undefined"

**Solutions:**
1. Go to Render dashboard → Your service → Environment
2. Verify variables are set correctly
3. Restart service after adding variables
4. Check variable names match exactly

### Service Sleeps Too Often

**Issue:** Service keeps sleeping

**Solutions:**
1. Set up UptimeRobot to ping `/health` every 5 minutes
2. Or upgrade to paid tier ($7/month) for always-on
3. Accept cold starts (free tier limitation)

### CORS Errors

**Error:** "CORS policy blocked"

**Solutions:**
1. Verify CORS is configured in your code:
   ```typescript
   app.use(cors({
     origin: true,  // Allows all origins
     credentials: true,
   }));
   ```
2. Check Flutter app is using correct URL
3. Verify headers are being sent correctly

---

## 📊 Monitoring

### View Logs

1. Go to Render dashboard
2. Select your service
3. Click **"Logs"** tab
4. View real-time logs

### Monitor Usage

1. Go to Render dashboard
2. Select your service
3. View **"Metrics"** tab
4. Monitor:
   - CPU usage
   - Memory usage
   - Request count
   - Response times

### Set Up Alerts

1. Go to Render dashboard
2. Select your service
3. Click **"Alerts"**
4. Configure email alerts for:
   - Service down
   - High error rate
   - Resource limits

---

## 🔄 Updating Your Service

### Automatic Deployments

Render automatically deploys when you push to your GitHub branch:

1. Make changes to your code
2. Commit and push to GitHub
3. Render detects changes
4. Automatically rebuilds and redeploys
5. Service updates in ~2-3 minutes

### Manual Deploy

1. Go to Render dashboard
2. Select your service
3. Click **"Manual Deploy"**
4. Choose branch/commit
5. Click **"Deploy"**

### Rollback

1. Go to Render dashboard
2. Select your service
3. Click **"Events"** tab
4. Find previous successful deployment
5. Click **"Redeploy"**

---

## 💰 Free Tier Limits

**What's Included:**
- ✅ 750 hours/month
- ✅ 512MB RAM
- ✅ Automatic SSL
- ✅ Automatic deployments
- ✅ Custom domains

**Limitations:**
- ⚠️ Service sleeps after 15 min inactivity
- ⚠️ Cold start delay (~30 seconds)
- ⚠️ Limited to 1 free web service
- ⚠️ Build time limits

**Upgrade Options:**
- **Starter:** $7/month - Always-on, no sleep
- **Standard:** $25/month - More resources
- **Pro:** $85/month - Production-ready

---

## 🎯 Best Practices

### 1. Optimize Build Time

```json
// package.json - Use npm ci for faster installs
"scripts": {
  "build": "npm ci && npm run build"
}
```

### 2. Use Health Checks

Keep your health endpoint simple and fast:
```typescript
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});
```

### 3. Monitor Logs

Regularly check logs for:
- Errors
- Slow requests
- Memory issues
- API failures

### 4. Environment Variables

Never commit secrets:
- ✅ Use Render's environment variables
- ✅ Keep `.env` in `.gitignore`
- ✅ Document required variables

### 5. Error Handling

Return proper error codes:
```typescript
// Good error response
res.status(401).json({
  error: 'Spotify token required',
  code: 'TOKEN_REQUIRED'
});
```

---

## 📱 Update Flutter App

After deployment, update your Flutter app:

**File:** `antidote_flutter/lib/config/env_config.dart`

```dart
static String get apiBaseUrl {
  if (kDebugMode) {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
  } else {
    // Production - use Render URL
    return dotenv.env['API_BASE_URL'] ?? 'https://your-app.onrender.com';
  }
}
```

**Or in `.env.production`:**
```env
API_BASE_URL=https://your-app.onrender.com
```

---

## ✅ Success Checklist

- [ ] Service deployed successfully
- [ ] Health endpoint responds
- [ ] API endpoints work with Spotify tokens
- [ ] Flutter app connects to Render URL
- [ ] UptimeRobot configured (optional)
- [ ] Logs show no errors
- [ ] Environment variables set correctly

---

## 🆘 Need Help?

- **Render Docs:** https://render.com/docs
- **Render Support:** https://render.com/support
- **Check Logs:** Render dashboard → Your service → Logs
- **Community:** Render Discord/Slack

---

**Your backend is now live on Render!** 🎉

Test it with your Flutter app and enjoy free hosting!

