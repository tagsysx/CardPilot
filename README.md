# CardPilot - NFC Data Collection App

**Current Version**: 1.4.2
**Last Updated**: 2025/8/11

CardPilot is an iOS app designed to automatically collect and record device data when triggered by NFC interactions through iOS Shortcuts. The app captures GPS location, IP address, IMU sensor data, and information about the triggering context.

## Features

- **GPS Location Tracking**: Records precise latitude and longitude coordinates with detailed address information
- **Network Information**: Captures device IP address (local and public) and WiFi network details (SSID)
- **Motion Sensor Data**: Collects 5 seconds of accelerometer, gyroscope, and magnetometer data
- **Audio Recording**: Captures ambient audio data during NFC sessions
- **App Context Detection**: Identifies the triggering application or context
- **iOS Shortcuts Integration**: Designed to be triggered via iOS Shortcuts app
- **URL Scheme Support**: Can be launched with custom URL schemes
- **Data Persistence**: All collected data is stored locally using SwiftData
- **Beautiful UI**: Modern interface to view and manage collected sessions

## Version 1.4 Updates

### 🚀 New Features
- **App Intents Support**: Added native iOS 16+ App Intents for seamless Shortcuts integration
- **Background Data Collection**: App Intents can collect data without opening the app interface
- **Enhanced Parameter Handling**: Better WiFi, NFC, and GPS coordinate parameter support

### 🐛 Bug Fixes
- **Fixed Swift Task Continuation Misuse**: Resolved fatal error in sensor data collection functions
- **Improved Concurrency Safety**: Added guards to prevent multiple continuation resumes
- **Enhanced Sensor Data Collection**: Fixed magnetometer, barometer, and IMU data collection timeouts

### 🔧 Technical Improvements
- Optimized sensor data collection with proper timeout handling
- Enhanced error handling for concurrent operations
- Improved data collection reliability and stability

## How It Works

1. **NFC Trigger**: When an NFC tag is scanned, iOS Shortcuts can automatically launch CardPilot
2. **Data Collection**: The app simultaneously collects:
   - Current GPS coordinates with detailed address information
   - Device IP address and WiFi network details (SSID)
   - 5 seconds of IMU sensor data (accelerometer + gyroscope + magnetometer)
   - Ambient audio data
   - Information about the triggering app/context
3. **Data Storage**: All data is timestamped and stored locally
4. **Data Viewing**: Users can view detailed information about each NFC session

## Setup Instructions

### 🎯 Method 1: App Intents (Recommended for iOS 16+)

**App Intents provide the best user experience with native Shortcuts integration and background data collection.**

#### Setup Steps

1. **Open the Shortcuts app** on your iOS device
2. **Create a new shortcut**
3. **Add NFC trigger** - This automatically creates a "Shortcut Input" variable
4. **Add "Get Details of WiFi Network"** action to capture WiFi name
5. **Add "Get Details of WiFi Network"** action and select "SSID"
6. **Add "Get Current Location"** action to get GPS coordinates
7. **Choose "CardPilit" app**
8. **Add "Collect Sensor Data"** action** - This appears under CardPilot app
9. **Configure parameters**:
   - **WiFi Info**: Set to WiFi SSID variables (name[SSID]) from step 4 and 5
   - **NFC Info**: Set to "Shortcut Input" variable (contains NFC tag data)
   - **Latitude**: Set to "Latitude" variable from "Get Current Location"
   - **Longitude**: Set to "Longitude" variable from "Get Current Location"
10. **Save the shortcut**

#### Example Shortcut Workflow
```
NFC Trigger → Get WiFi Network → Get Current Location → Collect Sensor Data
```

#### Benefits of App Intents
- ✅ **Background Execution**: Data collection happens without opening the app
- ✅ **Native Integration**: Seamless Shortcuts workflow
- ✅ **Parameter Validation**: Type-safe parameters prevent errors
- ✅ **Privacy Compliance**: Automatically skips microphone recording
- ✅ **Better Performance**: No app switching or UI loading

### 🔗 Method 2: URL Scheme Integration

**URL Scheme method works on all iOS versions and provides more control over app behavior.**

#### URL Scheme Configuration

First, you need to configure the URL scheme in your iOS device:

1. **Go to Settings** → **Shortcuts** → **Advanced**
2. **Enable "Allow Running Shortcuts"** if not already enabled
3. **The URL scheme `cardpilot://` is automatically registered** when the app is installed

#### Basic Setup

1. **Open the Shortcuts app** on your iOS device
2. **Create a new shortcut**
3. **Add NFC trigger**
4. **Add "Get Current WiFi Network"** action
5. **Add "Get Details of WiFi Network"** action and select "SSID"
6. **Add "Open URLs"** action (not "Open App")
7. **Set the URL** to: `cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true&ssid=[WiFi Variable]&nfc=[Shortcut Input]`
8. **Replace variables**:
   - `[WiFi Variable]` with the SSID variable from step 5
   - `[Shortcut Input]` with the "Shortcut Input" variable (contains NFC tag data)
9. **Save the shortcut**

#### URL Format
```
cardpilot://collect?[parameter1=value1]&[parameter2=value2]&...
```

#### Complete URL Example
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true&ssid=MyWiFi&nfc=123456789
```

#### Supported URL Parameters

| Parameter | Type | Required | Description | Example Values |
|-----------|------|----------|-------------|----------------|
| `sourceApp` | String | No | Name of the triggering application | `Shortcuts`, `NFC`, `Manual` |
| `autoExit` | Boolean | No | Whether to automatically exit app after data collection | `true`, `false` |
| `silent` | Boolean | No | Whether to enable silent mode (reduced UI feedback) | `true`, `false` |
| `ssid` | String | No | WiFi network name (usually passed from Shortcuts) | `MyWiFi`, `Office_5G` |
| `nfc` | String | No | NFC tag UID or identifier | `123456789`, `tag_001` |

#### Advanced URL Scheme Examples

**Basic NFC Collection:**
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true
```

**With WiFi and NFC Data:**
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true&ssid=[WiFi Variable]&nfc=[Shortcut Input]
```

**Manual Testing (without auto-exit):**
```
cardpilot://collect?sourceApp=Manual&autoExit=false&silent=false
```

**Silent Background Collection:**
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true
```

#### Simple NFC-only Setup
If you only need NFC triggering without WiFi details:
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true
```

### 📱 Method Comparison

| Feature | App Intents | URL Scheme |
|---------|------------|------------|
| **iOS Version** | ✅ iOS 16+ | ✅ iOS 14+ |
| **Background Execution** | ✅ No app opening | ❌ Opens app interface |
| **Native Integration** | ✅ Full Shortcuts support | ⚠️ Basic URL opening |
| **Parameter Validation** | ✅ Type-safe parameters | ⚠️ String parsing |
| **User Experience** | ✅ Seamless workflow | ⚠️ App switching |
| **Privacy Compliance** | ✅ Microphone auto-skip | ⚠️ Manual control |
| **Setup Complexity** | ⚠️ More steps | ✅ Simpler setup |
| **Customization** | ⚠️ Limited parameters | ✅ Full URL control |
| **Debugging** | ⚠️ Limited visibility | ✅ Full app interface |
| **Offline Support** | ✅ Always available | ✅ Always available |

## Data Collection Strategy

### App Intents Approach (Recommended)
- **GPS Coordinates**: Provided by Shortcuts as separate Latitude and Longitude parameters
- **Address Information**: Automatically parsed from GPS coordinates using reverse geocoding
- **WiFi SSID**: Prioritized from Shortcuts, fallback to system detection
- **NFC Data**: Directly from Shortcuts parameters
- **Sensor Data**: All available sensors collected in background (excluding microphone)

### URL Scheme Approach
- **GPS Coordinates**: Collected by the app when launched
- **Address Information**: Automatically generated from GPS coordinates
- **WiFi SSID**: From Shortcuts parameters or system detection
- **NFC Data**: From Shortcuts parameters
- **Sensor Data**: All available sensors collected (including microphone if permitted)

## Usage Examples

### App Intents Example (iOS 16+)
1. **NFC Trigger** → Automatically scans NFC tag
2. **Get WiFi Network** → Captures current WiFi SSID
3. **Get Current Location** → Gets GPS coordinates
4. **Collect Sensor Data** → Background data collection
5. **Data automatically saved** without opening CardPilot app

**Advantages:**
- ✅ Completely seamless user experience
- ✅ No app switching or loading screens
- ✅ Data collection happens in background
- ✅ Automatic parameter validation

### URL Scheme Example
1. **NFC Trigger** → Scans NFC tag
2. **Get WiFi Network** → Captures WiFi SSID
3. **Open URL** → Launches CardPilot with parameters
4. **App opens** and collects data
5. **Auto-exit** after completion (if configured)

**Advantages:**
- ✅ Works on all iOS versions
- ✅ Full control over app behavior
- ✅ Can customize collection parameters
- ✅ Easy to debug and troubleshoot

### Manual Testing
Use the "Trigger Data Collection" button in the app for testing without NFC.

### Testing URL Schemes
You can test URL schemes directly in Safari by typing:
```
cardpilot://collect?sourceApp=Test&autoExit=false&silent=false
```

## Permissions Required

The app requires the following permissions:

- **Location Access**: To record GPS coordinates and detailed address information
- **Motion & Fitness**: To access accelerometer, gyroscope, and magnetometer data
- **NFC Access**: To read NFC tag content and context information
- **Microphone Access**: To record ambient audio data during sessions
- **Bluetooth Access**: To connect with external devices and peripherals
- **Network Access**: To determine IP address and perform geocoding

These permissions are automatically requested when needed and are used only for data collection purposes.

## Data Structure

Each NFC session records:

```swift
- Timestamp: When the session was triggered
- GPS Location: Latitude and longitude coordinates
- Address Information: Street, city, state, country, postal code
- IP Address: Device's current IP address
- WiFi Network: Current WiFi network name (SSID) when available
- Current App: Name of the triggering application
- IMU Data: 5 seconds of motion sensor readings (accelerometer, gyroscope, magnetometer)
- Audio Data: Ambient audio recordings during the session
```

## Technical Implementation

### Core Components

1. **NFCSessionData**: SwiftData model for storing session information
2. **LocationManager**: Handles GPS coordinate collection and geocoding
3. **NetworkManager**: Manages IP address detection
4. **SensorManager**: Collects IMU sensor data and audio recordings
5. **CurrentAppDetector**: Attempts to identify triggering application
6. **NFCDataCollectionService**: Orchestrates all data collection operations
7. **App Intents**: Native iOS 16+ Shortcuts integration

### Architecture

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Local data persistence
- **CoreLocation**: GPS coordinate access and geocoding
- **CoreMotion**: Accelerometer, gyroscope, and magnetometer data
- **AVFoundation**: Audio recording capabilities
- **Combine**: Reactive programming for data flows
- **App Intents**: Native iOS automation framework

## Development Notes

- **Minimum iOS version**: 17.0
- **App Intents support**: iOS 16+ (recommended)
- **URL Scheme support**: iOS 14+ (fallback)
- **Built with**: Swift 5.9+ and SwiftUI
- **Uses**: async/await for concurrent operations
- **Implements**: Proper error handling and user feedback
- **Follows**: iOS Human Interface Guidelines

## Privacy & Security

- All data is stored locally on device
- No data is transmitted to external servers
- Users can delete individual sessions or all data
- App requests only necessary permissions
- Location and motion data collection is transparent to users
- App Intents automatically skip microphone recording for privacy

## Future Enhancements

Potential improvements could include:
- Export functionality for collected data
- Cloud synchronization options
- Advanced analytics and visualizations
- Custom data collection intervals
- Integration with additional sensor types
- Enhanced App Intents with more automation options

## Support

For technical support or feature requests, please refer to the project documentation or contact the development team.

---

**Note**: App Intents provide the best user experience for iOS 16+ users, while URL Scheme remains a reliable fallback for older iOS versions and advanced customization needs.