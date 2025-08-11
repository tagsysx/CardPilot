# CardPilot - NFC Data Collection App

**Current Version**: 1.1  
**Last Updated**: August 11, 2025

CardPilot is an iOS app designed to automatically collect and record device data when triggered by NFC interactions through iOS Shortcuts. The app captures GPS location, IP address, IMU sensor data, and information about the triggering context.

## Features

- **GPS Location Tracking**: Records precise latitude and longitude coordinates with detailed address information
- **Network Information**: Captures device IP address (local and public)
- **Motion Sensor Data**: Collects 5 seconds of accelerometer, gyroscope, and magnetometer data
- **Audio Recording**: Captures ambient audio data during NFC sessions
- **App Context Detection**: Identifies the triggering application or context
- **iOS Shortcuts Integration**: Designed to be triggered via iOS Shortcuts app
- **URL Scheme Support**: Can be launched with custom URL schemes
- **Data Persistence**: All collected data is stored locally using SwiftData
- **Beautiful UI**: Modern interface to view and manage collected sessions

## Version 1.1 Updates

### 🐛 Bug Fixes
- **Fixed NFC session duplicate recording issue**
  - Resolved the problem where each NFC trigger created two identical session records
  - Optimized URL scheme handling process to avoid duplicate calls
  - Improved application performance and stability

### 🔧 Technical Improvements
- Simplified code structure and reduced redundant logic
- Optimized data collection workflow
- Enhanced error handling mechanisms

## How It Works

1. **NFC Trigger**: When an NFC tag is scanned, iOS Shortcuts can automatically launch CardPilot
2. **Data Collection**: The app simultaneously collects:
   - Current GPS coordinates with detailed address information
   - Device IP address
   - 5 seconds of IMU sensor data (accelerometer + gyroscope + magnetometer)
   - Ambient audio data
   - Information about the triggering app/context
3. **Data Storage**: All data is timestamped and stored locally
4. **Data Viewing**: Users can view detailed information about each NFC session

## Setup Instructions

### 1. iOS Shortcuts Configuration

To set up CardPilot with iOS Shortcuts for NFC triggering:

1. Open the **Shortcuts** app on your iOS device
2. Create a new shortcut
3. Add the "NFC" trigger
4. Add the "Open App" action and select CardPilot
5. Optionally, add "Get Text from Input" to pass context information
6. Save the shortcut

### 2. URL Scheme Integration

CardPilot supports custom URL schemes for external triggering. The app uses the following URL format:

#### Basic Format
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

#### Detailed Parameter Descriptions

**sourceApp Parameter**
- Used to identify the application or source that triggered data collection
- Will be displayed in the collected data for subsequent analysis
- Common values: `Shortcuts` (Shortcuts app), `NFC` (NFC tag), `Manual` (manual trigger)

**autoExit Parameter**
- When set to `true`, the app will automatically exit after data collection is complete
- When set to `false` or not set, users need to manually exit the app
- Suitable for automation scenarios to reduce user intervention

**silent Parameter**
- When set to `true`, reduces user interface feedback and prompts
- When set to `false` or not set, displays normal user interface
- Suitable for background or automated data collection

**ssid Parameter**
- Passes WiFi network name to record current network environment
- Due to iOS privacy restrictions, usually obtained and passed through Shortcuts app
- If not provided, the app will attempt to get network connection status

**nfc Parameter**
- Passes NFC tag UID or custom identifier
- Used to associate specific NFC tags with usage scenarios
- Facilitates subsequent data analysis and tag management

#### Minimal URL Example

For basic data collection only, you can use the simplest URL:
```
cardpilot://collect
```

#### Automation Scenario URL Example

URL suitable for Shortcuts automation:
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true
```

### 3. Manual Testing

The app includes a manual trigger button for testing data collection functionality without NFC.

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

### Architecture

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Local data persistence
- **CoreLocation**: GPS coordinate access and geocoding
- **CoreMotion**: Accelerometer, gyroscope, and magnetometer data
- **AVFoundation**: Audio recording capabilities
- **Combine**: Reactive programming for data flows

## Usage Examples

### Basic NFC Trigger
1. Set up iOS Shortcut with NFC trigger
2. Tap NFC tag with device
3. CardPilot automatically launches and collects data
4. View collected data in the app interface

### URL Scheme Trigger

#### Using in iOS Shortcuts
In the Shortcuts app, add an "Open URL" action:
```
cardpilot://collect?sourceApp=Shortcuts&autoExit=true&silent=true&nfc=[NFC_UID]
```

#### Programmatic Calls in Other Apps
```swift
// Basic call
if let url = URL(string: "cardpilot://collect") {
    UIApplication.shared.open(url)
}

// Call with parameters
let urlString = "cardpilot://collect?sourceApp=MyApp&autoExit=true&silent=true&ssid=\(wifiSSID)&nfc=\(nfcUID)"
if let url = URL(string: urlString) {
    UIApplication.shared.open(url)
}
```

#### Testing in Safari
You can also test by directly entering the URL in Safari:
```
cardpilot://collect?sourceApp=Safari&autoExit=false
```

### Manual Trigger
Use the "Trigger Data Collection" button in the app for testing.

## Development Notes

- Minimum iOS version: 17.0
- Built with Swift 5.9+ and SwiftUI
- Uses async/await for concurrent operations
- Implements proper error handling and user feedback
- Follows iOS Human Interface Guidelines

## Privacy & Security

- All data is stored locally on device
- No data is transmitted to external servers
- Users can delete individual sessions or all data
- App requests only necessary permissions
- Location and motion data collection is transparent to users

## Future Enhancements

Potential improvements could include:
- Export functionality for collected data
- Cloud synchronization options
- Advanced analytics and visualizations
- Custom data collection intervals
- Integration with additional sensor types

## Support

For technical support or feature requests, please refer to the project documentation or contact the development team.