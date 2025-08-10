# CardPilot iPhone Deployment Guide

## 📱 Deploy CardPilot to Your iPhone

### Prerequisites
1. **iPhone** connected to your Mac via USB or Wi-Fi
2. **Xcode** installed and project building successfully ✅ (Done!)
3. **Apple Developer Account** (free account works for personal use)

### Step 1: Connect Your iPhone
1. Connect your iPhone to your Mac using a USB cable
2. Trust this computer when prompted on your iPhone
3. In Xcode, your device should appear in the device list

### Step 2: Configure Developer Account
1. Open **Xcode Preferences** (Xcode → Preferences)
2. Go to **Accounts** tab
3. Click **+** and sign in with your Apple ID
4. Your Apple ID will be added as a developer account

### Step 3: Configure Project for Device
1. Open CardPilot project in Xcode
2. Select **CardPilot** project in the navigator
3. Select **CardPilot** target
4. Go to **Signing & Capabilities** tab
5. Check **"Automatically manage signing"**
6. Select your **Team** (your Apple ID)
7. Xcode will automatically create a bundle identifier

### Step 4: Select Your iPhone as Target
1. In Xcode toolbar, click the device selector (next to scheme)
2. Choose your iPhone from the list
3. If your iPhone doesn't appear:
   - Make sure it's connected and trusted
   - Check that it's unlocked
   - Try unplugging and reconnecting

### Step 5: Build and Run on Device
1. Click the **Run** button (▶️) in Xcode
2. Xcode will:
   - Build the app
   - Install it on your iPhone
   - Launch the app

### Step 6: Trust the Developer Certificate
**First time only:**
1. On your iPhone, go to **Settings → General → VPN & Device Management**
2. Find your Apple ID under "Developer App"
3. Tap it and select **"Trust [Your Apple ID]"**
4. Confirm by tapping **"Trust"**

### Step 7: Verify App Installation
1. CardPilot should now appear on your iPhone home screen
2. Tap it to launch and verify it works
3. Grant permissions when prompted:
   - **Location access** (for GPS data)
   - **Motion & Fitness** (for IMU sensors)

## 🔗 Step 2: Set Up NFC Shortcuts

### After App is Installed:
1. Open **Shortcuts** app on your iPhone
2. Tap **"+"** to create new shortcut
3. Add **"Open App"** action
4. Select **CardPilot** (should now appear in the list!)
5. Add **NFC trigger**:
   - Tap automation tab
   - Create Personal Automation
   - Choose **NFC**
   - Scan your NFC tag
   - Add the CardPilot shortcut
6. Save the automation

### URL Scheme Integration (Optional):
You can also trigger CardPilot with specific parameters:
```
cardpilot://trigger?sourceApp=Shortcuts
```

## 🔧 Troubleshooting

### If Build Fails on Device:
1. **Check iOS version**: CardPilot requires iOS 17.0+
2. **Storage space**: Ensure iPhone has enough space
3. **Network**: Some builds require internet for certificate validation

### If App Crashes on Device:
1. **Permissions**: Make sure to grant location and motion permissions
2. **Check Console**: Use Xcode → Window → Devices to see crash logs

### If App Doesn't Appear in Shortcuts:
1. **Verify installation**: App must be successfully installed on device
2. **Restart Shortcuts app**: Force close and reopen
3. **iOS version**: Ensure iOS supports the Shortcuts features you're using

## 📋 Next Steps After Deployment

1. **Test basic functionality**: Launch app, try manual data collection
2. **Set up NFC automation**: Create shortcuts for your NFC tags
3. **Test data collection**: Verify GPS, IP, and IMU data collection works
4. **Explore analytics**: Check the analytics tab for data visualization
5. **Export data**: Test CSV/JSON export functionality

## 🔒 Important Notes

- **Developer Certificate**: Expires after 7 days with free Apple ID
- **Renewal**: Rebuild and reinstall weekly, or get paid developer account ($99/year)
- **Distribution**: For App Store distribution, you'll need a paid developer account
- **Privacy**: All data stays on device - no external transmission

## ✅ Success Checklist

- [ ] iPhone connected and trusted
- [ ] Apple ID configured in Xcode
- [ ] Project builds successfully on device
- [ ] App appears on iPhone home screen
- [ ] Developer certificate trusted
- [ ] App launches without crashes
- [ ] Permissions granted (Location, Motion)
- [ ] App appears in Shortcuts app list
- [ ] NFC automation created and tested

Once these steps are complete, CardPilot will be fully functional on your iPhone and ready for NFC-triggered data collection!
