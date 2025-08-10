# 🚀 Quick Fix for CardPilot URL Scheme

## The Problem
The error "app is not installed" happens because the URL scheme `cardpilot://` is not properly registered with iOS.

## ✅ Solution (Use Xcode - Recommended)

### Step 1: Open in Xcode
1. Open `CardPilot.xcodeproj` in Xcode
2. Select CardPilot project in left sidebar
3. Select CardPilot target

### Step 2: Add URL Scheme
1. Go to **Info** tab
2. Scroll to **URL Types**
3. Click **+** to add new URL Type
4. Fill in:
   - **Identifier**: `com.cardpilot.url`
   - **URL Schemes**: `cardpilot`
   - **Role**: `Editor`

### Step 3: Configure Signing
1. Go to **Signing & Capabilities** tab
2. Check **"Automatically manage signing"**
3. Select your **Team** (Apple ID)

### Step 4: Deploy to iPhone
1. Select your iPhone in device selector
2. Click **Run** (▶️)
3. Trust certificate on iPhone if prompted

### Step 5: Test URL Scheme
1. Open **Safari** on iPhone
2. Type: `cardpilot://collect?sourceApp=Safari&autoExit=true`
3. Press **Go**
4. CardPilot should launch!

## 🎯 Expected Result

Once fixed:
- Safari test → CardPilot launches ✅
- NFC shortcut → CardPilot launches ✅
- Background collection works seamlessly ✅

## 🔧 Troubleshooting

### If URL scheme still doesn't work:
1. **Check Bundle ID**: Make sure it matches in project settings
2. **Clean and rebuild**: Product → Clean Build Folder
3. **Restart iPhone**: Sometimes iOS needs a restart to register new URL schemes
4. **Re-deploy app**: Delete app from iPhone and reinstall

### If code signing fails:
1. **Add Apple ID**: Xcode → Preferences → Accounts → Add Apple ID
2. **Trust certificate**: Settings → General → VPN & Device Management
3. **Use different Bundle ID**: Change `org.tagsys.CardPilot` to something unique

## 📱 NFC Shortcut Setup (After Fix)

Once URL scheme works:

1. **Shortcuts app** → **Automation** → **+**
2. **Create Personal Automation** → **NFC**
3. **Scan NFC tag**
4. **Add Action** → **Open URLs**
5. **URL**: `cardpilot://collect?sourceApp=Shortcuts&autoExit=true`
6. **Turn OFF** "Ask Before Running"
7. **Test with NFC tag**

The seamless tap-and-collect experience will work perfectly! 🎉
