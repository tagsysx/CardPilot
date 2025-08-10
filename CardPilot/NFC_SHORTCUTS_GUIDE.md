# 📱 CardPilot NFC Shortcuts Integration Guide

## 🎯 Automatic NFC Usage Tracking

CardPilot now features **automatic NFC usage tracking** - every time you tap an NFC tag to trigger the app, it automatically records your NFC usage with timestamp, location, and usage type!

## 🔄 Collection Modes

### 1. **Background Mode** (Recommended for NFC)
- **Trigger**: NFC tag tap
- **Interface**: Minimal overlay showing collection progress
- **Auto-Exit**: Yes (closes automatically after 3 seconds)
- **User Experience**: Tap → Collect → Close (seamless)

### 2. **Interactive Mode**
- **Trigger**: Manual app launch or specific URL
- **Interface**: Full app interface
- **Auto-Exit**: No (stays open for exploration)
- **User Experience**: Full app experience

## 🏗️ Setup Instructions

### Step 1: Create NFC Shortcut (Background Mode)

1. **Open Shortcuts app** on your iPhone
2. **Tap "+" to create new shortcut**
3. **Add "Open URLs" action** (not "Open App")
4. **Set URL to**:
   ```
   cardpilot://collect?sourceApp=Shortcuts&autoExit=true
   ```
5. **Add NFC trigger**:
   - Tap "Add to Siri"
   - Choose "NFC"
   - Scan your NFC tag
   - Name it (e.g., "CardPilot Data Collection")
6. **Save the shortcut**

### Step 2: Test the NFC Tag

1. **Tap your NFC tag** with your iPhone
2. **CardPilot should**:
   - Launch with minimal overlay
   - Show "Collecting Data..." with progress
   - Display collection results briefly
   - Auto-close after 3 seconds
3. **Check collected data** in CardPilot's Sessions tab later
4. **View NFC usage history** in the new "NFC使用" tab

## 📊 Automatic NFC Usage Recording

### What Gets Recorded Automatically:
- ⏰ **Exact timestamp** of each NFC use
- 📍 **GPS location** where the NFC was used
- 🏷️ **Usage type** (Payment, Transport, Access, etc.)
- 📱 **Trigger source** (which shortcut/app triggered it)
- 📊 **Usage statistics** and frequency analysis

### Smart Type Detection:
CardPilot automatically detects the type of NFC usage based on:
- URL parameters (e.g., `cardpilot://collect?type=payment`)
- Context keywords in the triggering app
- Default assumption for common use cases

### Privacy & Control:
- All data stays on your device
- View all records in the "NFC使用" tab
- Delete individual records or clear all data
- Export usage statistics for analysis

## 🔗 URL Scheme Options

### Background Collection (Auto-Exit)
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true
```
- **Best for**: General NFC usage
- **Behavior**: Collect data, record usage, auto-close

### Payment NFC Usage
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&type=payment
```
- **Usage Type**: Payment/Apple Pay
- **Best for**: Payment terminals, shopping

### Transport NFC Usage
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&type=transport
```
- **Usage Type**: Public transportation
- **Best for**: Bus/metro card readers

### Access Control NFC Usage
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&type=access
```
- **Usage Type**: Access control/door entry
- **Best for**: Office buildings, secure areas

### Background Collection (Manual Close)
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=false
```
- **Best for**: When you want to see results
- **Behavior**: Shows collection overlay, manual close

### Legacy Trigger (Auto-Exit)
```
cardpilot://trigger?sourceApp=Shortcuts
```
- **Best for**: Backward compatibility
- **Behavior**: Same as background mode with auto-exit

### Full App Mode
Just use **"Open App"** action in Shortcuts instead of URL

## 📋 Advanced Shortcuts Setup

### Option A: Simple NFC Automation
```
Action 1: Open URLs
URL: cardpilot://collect?sourceApp=Shortcuts&autoExit=true
Trigger: NFC
```

### Option B: Enhanced NFC with Notifications
```
Action 1: Open URLs
URL: cardpilot://collect?sourceApp=Shortcuts&autoExit=true

Action 2: Wait (4 seconds)

Action 3: Show Notification
Title: "Data Collected"
Body: "CardPilot has collected your sensor data"
```

### Option C: Conditional Collection
```
Action 1: Ask for Input (Choose from Menu)
Options: "Quick Collection", "Full App", "Cancel"

Action 2: If (Quick Collection)
  → Open URLs: cardpilot://collect?autoExit=true

Action 3: If (Full App)
  → Open App: CardPilot

Action 4: If (Cancel)
  → Stop Shortcut
```

## 🎨 What You'll See

### Background Collection Flow:
1. **NFC Tap** → Shortcut triggers
2. **CardPilot launches** with dark overlay
3. **Collection progress** shows:
   - Animated NFC icon
   - "Collecting Data..." text
   - Progress indicator
   - Real-time status updates
4. **Results summary** displays:
   - ✓ Location collected
   - ✓ Network data
   - ✓ Motion sensors
5. **Auto-close countdown** (3 seconds)
6. **App closes** automatically

### Collection Interface Features:
- **Minimal Design**: Dark overlay, won't interfere with other apps
- **Progress Feedback**: Real-time status of data collection
- **Results Summary**: Quick view of what data was collected
- **Haptic Feedback**: Tactile confirmation of success/completion
- **Error Display**: Shows if any sensors failed to collect data

## 🔧 Troubleshooting

### NFC Tag Not Working?
1. **Check URL**: Make sure it's exactly `cardpilot://collect?sourceApp=Shortcuts&autoExit=true`
2. **Test Shortcut**: Run the shortcut manually first
3. **NFC Settings**: Ensure NFC is enabled in Settings → Control Center
4. **Tag Quality**: Try a different NFC tag

### App Not Auto-Closing?
1. **Check URL parameter**: Must include `autoExit=true`
2. **Wait for completion**: Auto-close happens after collection finishes
3. **Manual close**: Tap "Close" if needed

### Collection Fails?
1. **Permissions**: Grant Location and Motion access in Settings
2. **Network**: Ensure device has internet for IP detection
3. **Try again**: Some sensors may need a moment to initialize

## 📊 Data Verification

After NFC collection:
1. **Open CardPilot normally**
2. **Go to Sessions tab**
3. **Check latest entry** for collected data:
   - GPS coordinates
   - IP address
   - Motion sensor readings
   - Timestamp
4. **View Analytics** for insights

## 🎯 Best Practices

### For NFC Tags:
- **Label your tags** (e.g., "Car", "Office", "Home")
- **Test regularly** to ensure they work
- **Use quality tags** for better reliability

### For Shortcuts:
- **Keep URLs simple** - avoid complex parameters
- **Test before deployment** on actual NFC tags
- **Use descriptive names** for your shortcuts

### For Data Collection:
- **Grant all permissions** for best results
- **Ensure good signal** (GPS, cellular/WiFi)
- **Hold still briefly** during collection (for better IMU data)

## 🔄 Migration from Old Setup

If you had previous CardPilot shortcuts:

1. **Open existing shortcut**
2. **Replace "Open App" action** with "Open URLs"
3. **Set URL to**: `cardpilot://collect?sourceApp=Shortcuts&autoExit=true`
4. **Test with your NFC tag**

This provides a much better user experience with the seamless background collection!
