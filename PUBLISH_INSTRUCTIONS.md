# Step-by-Step Publishing Instructions

Since Git isn't available in the command line, follow these steps in your IDE or GitHub Desktop.

## 🎯 Quick Steps (Using VS Code)

### Step 1: Open Source Control
1. Press `Ctrl+Shift+G` (or click Source Control icon in sidebar)
2. You should see all your changes listed

### Step 2: Stage Backend Files
1. In the Source Control panel, find the `backend/` folder
2. Click the **`+`** button next to `backend/` to stage all backend files
3. Or click the **`+`** next to individual files you want to add

**Files to stage:**
- ✅ `backend/src/index.ts`
- ✅ `backend/package.json`
- ✅ `backend/tsconfig.json`
- ✅ `backend/.gitignore`
- ✅ `backend/render.yaml`
- ✅ `backend/env.example`
- ✅ All `.md` documentation files
- ✅ `backend/server/.gitkeep`

**Files that should NOT be staged (should be ignored):**
- ❌ `node_modules/` (if exists)
- ❌ `dist/` (if exists)
- ❌ `.env` (if exists)

### Step 3: Commit Changes
1. In the message box at the top, type:
   ```
   Add backend implementation with Spotify OAuth integration
   ```
2. Press `Ctrl+Enter` or click the checkmark ✓ to commit

### Step 4: Publish Branch
1. Look for the **"Publish Branch"** or **"Push"** button at the top
2. Click it to push to GitHub
3. If prompted for authentication:
   - Use your GitHub username
   - Use a **Personal Access Token** as password (not your GitHub password)
   - Get token from: GitHub → Settings → Developer settings → Personal access tokens → Generate new token

---

## 🎯 Quick Steps (Using GitHub Desktop)

### Step 1: Open GitHub Desktop
1. Launch GitHub Desktop
2. Select your repository: `Antidote-Flutter`

### Step 2: Review Changes
1. You'll see all changed files in the left panel
2. Check that `backend/` files are listed

### Step 3: Stage and Commit
1. Check the box next to files you want to commit (or "Select All")
2. In the bottom left, type commit message:
   ```
   Add backend implementation with Spotify OAuth integration
   ```
3. Click **"Commit to [branch-name]"**

### Step 4: Push to GitHub
1. Click **"Push origin"** button at the top
2. If authentication is needed, GitHub Desktop will prompt you

---

## 🔧 If "Publish Branch" Button Doesn't Appear

### Option 1: Push Manually
1. After committing, look for **"..."** menu (three dots)
2. Click it → Select **"Push"** or **"Push to..."**
3. Select your remote (usually `origin`)
4. Select your branch name

### Option 2: Set Up Remote (If Not Already Done)
1. In VS Code: Command Palette (`Ctrl+Shift+P`)
2. Type: `Git: Add Remote`
3. Enter remote name: `origin`
4. Enter remote URL: `https://github.com/yourusername/your-repo.git`

---

## ✅ Verification Checklist

Before publishing, verify:

- [ ] All backend files are saved
- [ ] `.gitignore` exists in `backend/` folder
- [ ] No `node_modules/` folder in backend (should be ignored)
- [ ] No `.env` file in backend (should be ignored)
- [ ] Commit message is descriptive
- [ ] You're on the correct branch

---

## 🆘 Troubleshooting

### Issue: "Authentication Failed"

**Solution:**
1. GitHub no longer accepts passwords for Git operations
2. You need a **Personal Access Token**:
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scope: `repo` (full control of private repositories)
   - Generate and copy the token
   - Use this token as your password when pushing

### Issue: "Nothing to Commit"

**Possible reasons:**
- Files are already committed
- Files are ignored by `.gitignore`
- No changes detected

**Solution:**
- Check `git status` in terminal (if available)
- Or check Source Control panel for uncommitted changes

### Issue: "Large File Detected"

**Solution:**
- Verify `.gitignore` is working
- `node_modules/` should be ignored
- If a large file was already committed, you may need to remove it from history

### Issue: "Branch is Behind"

**Solution:**
1. Pull latest changes first:
   - Click **"..."** → **"Pull"** or **"Pull, Rebase"**
2. Resolve any conflicts if they occur
3. Then push your changes

---

## 📋 What Should Be Published

✅ **These files SHOULD be committed:**
```
backend/
├── src/
│   └── index.ts
├── package.json
├── tsconfig.json
├── .gitignore
├── render.yaml
├── env.example
├── README.md
├── RENDER_DEPLOYMENT.md
├── SPOTIFY_OAUTH_MIGRATION.md
├── (all other .md files)
└── server/
    └── .gitkeep
```

❌ **These should NOT be committed (ignored by .gitignore):**
```
backend/
├── node_modules/     ❌
├── dist/            ❌
├── .env             ❌
└── *.log            ❌
```

---

## 🚀 After Publishing

Once published successfully:

1. **Verify on GitHub:**
   - Go to your GitHub repository
   - Check that `backend/` folder appears
   - Verify files are there

2. **Deploy to Render:**
   - Follow `backend/RENDER_DEPLOYMENT.md`
   - Connect your GitHub repo to Render
   - Render will auto-detect and deploy

---

## 💡 Pro Tips

1. **Always check Source Control panel** before committing
2. **Use descriptive commit messages**
3. **Test locally first** (if possible)
4. **Keep `.gitignore` updated**
5. **Never commit secrets** (`.env` files)

---

**Need more help?** Check `backend/GIT_PUBLISH_FIX.md` for detailed troubleshooting.

