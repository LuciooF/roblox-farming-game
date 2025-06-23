# 🚀 Roblox Deployment Setup Guide

This guide will help you set up automatic deployment of your farming game to Roblox using GitHub Actions.

## 🔑 Required Information

You need to get these values from your Roblox account:

### 1. Create a Roblox Experience (Game)
1. Go to [Roblox Create](https://create.roblox.com/dashboard/creations)
2. Click "Create" → "Experience"
3. Choose a template (any will work, you'll replace it)
4. Note down the **Experience ID** (found in the URL: `roblox.com/games/EXPERIENCE_ID/`)

### 2. Get your Place ID
1. In your experience, go to "Configure"
2. Go to "Places" tab
3. Note down the **Place ID** of your main place

### 3. Create an API Key
1. Go to [Roblox Creator Hub](https://create.roblox.com/credentials)
2. Click "Create API Key"
3. Name: `GitHub Actions Deploy`
4. Permissions needed:
   - `universe-places:write` (to publish places)
   - `universe:read` (to read experience info)
5. **Copy the API key immediately** (you can't see it again!)

## 🔒 Setting up GitHub Secrets

1. Go to your GitHub repository
2. Click "Settings" → "Secrets and variables" → "Actions"
3. Click "New repository secret" for each of these:

### Required Secrets:
```
ROBLOX_EXPERIENCE_ID = your_experience_id_here
ROBLOX_PLACE_ID = your_place_id_here
ROBLOX_API_KEY = your_api_key_here
```

## 📋 Step-by-Step Setup

### Step 1: Create Roblox Experience
```bash
# Go to https://create.roblox.com/dashboard/creations
# Click "Create" → "Experience" 
# Name it "Farming Game" or similar
# Save the Experience ID (from URL)
```

### Step 2: Get Place ID
```bash
# In your experience, go to Configure → Places
# Copy the Place ID of your main place
```

### Step 3: Generate API Key
```bash
# Go to https://create.roblox.com/credentials
# Create API Key with these permissions:
# - universe-places:write
# - universe:read
# Copy the key immediately!
```

### Step 4: Add GitHub Secrets
```bash
# Go to your repo → Settings → Secrets → Actions
# Add these three secrets:
# ROBLOX_EXPERIENCE_ID = 123456789
# ROBLOX_PLACE_ID = 987654321  
# ROBLOX_API_KEY = your_long_api_key_string
```

## 🚀 Deployment

Once setup is complete:

### Automatic Deployment
- **Push to main/master** → Automatically deploys to Roblox
- **Pull Request** → Builds but doesn't deploy (for testing)

### Manual Deployment
1. Go to your repo → "Actions" tab
2. Click "Deploy to Roblox" workflow
3. Click "Run workflow" → "Run workflow"

## 📁 Project Structure

The deployment expects this structure (which you already have):
```
├── src/
│   ├── client/         # Client scripts
│   ├── server/         # Server scripts  
│   └── shared/         # Shared modules
├── default.project.json # Rojo build config
├── wally.toml          # Dependency config
└── .github/workflows/  # GitHub Actions
```

## 🛠️ Local Development

To test builds locally:
```bash
# Install Rojo
npm install -g @roblox/rojo

# Build place file
rojo build --output test.rbxl

# Serve for live sync during development
rojo serve
```

## 🔍 Troubleshooting

### Common Issues:

**"Invalid API Key"**
- Check the API key is copied correctly
- Ensure it has the right permissions
- API keys expire, you may need to create a new one

**"Experience not found"**
- Double-check the Experience ID
- Make sure you own the experience
- Experience must be public or you must be the owner

**"Place not found"**  
- Verify the Place ID matches your main place
- Check it's the correct place within your experience

**Build fails**
- Check that all dependencies in wally.toml are valid
- Ensure default.project.json syntax is correct

## 🎮 Testing Your Deployed Game

1. After successful deployment, go to your Roblox experience
2. Click "Play" to test the live version
3. Invite friends using the experience link
4. Check the console for any errors

## 📝 Example GitHub Secrets

Your secrets should look like this:
```
ROBLOX_EXPERIENCE_ID: 1234567890
ROBLOX_PLACE_ID: 9876543210  
ROBLOX_API_KEY: ABCdef123456789XYZuvwxyz...
```

## 🎯 Next Steps

After setup:
1. Make a small code change
2. Push to main branch
3. Watch the "Actions" tab for deployment progress
4. Test your live game on Roblox!

---

🌾 **Happy Farming!** Your game will now automatically deploy to Roblox every time you push code changes!