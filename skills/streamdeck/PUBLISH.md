# Publishing to GitHub

## Quick Start

### 1. Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `openclaw-streamdeck` (or your preferred name)
3. Description: "Stream Deck integration for OpenClaw AI assistant"
4. Make it **Public** (or Private if you prefer)
5. **DO NOT** initialize with README (we already have one)
6. Click **Create repository**

### 2. Push Your Code

Open PowerShell in the streamdeck folder and run:

```powershell
# Navigate to the skill folder
cd "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck"

# Initialize git repository
git init

# Add all files
git add .

# Commit with descriptive message
git commit -m "Initial release: Stream Deck integration for OpenClaw

Features:
- Auto-detection of Stream Deck hardware
- One-click PowerShell setup
- 10 custom icons in OpenClaw coral red
- Profile generators for MK.2, XL, Plus models
- WCAG 2.1 AA accessible design"

# Add your GitHub repository (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/openclaw-streamdeck.git

# Push to GitHub
git push -u origin main
```

### 3. Create a Release

1. Go to your GitHub repository
2. Click **"Create a new release"** (or go to Releases → Draft new release)
3. Click **"Choose a tag"** → Type `v1.0.0` → Click **"Create new tag"**
4. Release title: `v1.0.0 - Initial Release`
5. Description:
```markdown
## 🦞 OpenClaw Stream Deck Integration v1.0.0

Control your OpenClaw AI assistant from Stream Deck hardware!

### ✨ Features
- Auto-detects all Stream Deck models
- One-click PowerShell installation
- 10 custom coral red icons
- 15+ AI control actions
- WCAG 2.1 AA accessible

### 📦 Installation
1. Download `openclaw-streamdeck.zip` from Assets
2. Extract and run `scripts/auto-setup-v3.ps1`
3. Import profiles into Stream Deck software

### 🎥 Demo Video
[Link to your YouTube video when ready]

### Requirements
- Windows 10/11
- Stream Deck hardware & software
- OpenClaw installed

---
**Full documentation:** See README.md
```

6. Click **"Publish release"**

The GitHub Actions workflow will automatically:
- ✅ Verify all files are present
- ✅ Create a release package
- ✅ Upload `openclaw-streamdeck.zip`

### 4. Share!

Now you can share:
- **GitHub Repo:** `https://github.com/YOUR_USERNAME/openclaw-streamdeck`
- **Direct Download:** Release page with zip file
- **YouTube Video:** Link in release description

### Optional: Add Topics

In your GitHub repository, click the gear icon next to "About" and add topics:
- `openclaw`
- `stream-deck`
- `elgato`
- `ai-assistant`
- `powershell`
- `automation`

### Optional: Enable GitHub Pages

1. Go to Settings → Pages
2. Source: Deploy from a branch
3. Branch: main / root
4. Click Save
5. Your docs will be at: `https://YOUR_USERNAME.github.io/openclaw-streamdeck`

## Updating

When you make changes:

```powershell
cd "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck"

git add .
git commit -m "Description of changes"
git push origin main

# Create new release
git tag v1.0.1
git push origin v1.0.1
```

Then create a new release on GitHub with the new tag.

## Troubleshooting

### Git not installed?
Download from: https://git-scm.com/download/win

### Permission denied?
Make sure you're logged into GitHub in your browser and have created the repository first.

### Push rejected?
If you initialized with README on GitHub:
```powershell
git pull origin main --rebase
git push origin main
```

## Files That Will Be Published

✅ Included:
- All PowerShell scripts
- PNG icons
- Documentation (README.md, SKILL.md)
- LICENSE
- GitHub Actions workflow

❌ Excluded:
- .git folder
- release/ folder
- Local cache files
- IDE settings

---

**Questions?** Open an issue on GitHub or ask in the OpenClaw Discord!
