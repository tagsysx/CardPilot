#!/bin/bash

echo "🔧 Fixing CardPilot URL Scheme Registration..."

# Clean build
echo "1. Cleaning build..."
xcodebuild clean -project CardPilot.xcodeproj

# Remove derived data
echo "2. Clearing derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/CardPilot-*

# Check if device is connected
echo "3. Checking connected devices..."
xcrun devicectl list devices | grep -i "connected"

# Try to build for device
echo "4. Building for device..."
if xcrun devicectl list devices | grep -q "connected"; then
    DEVICE_NAME=$(xcrun devicectl list devices | grep "connected" | head -1 | awk '{print $1}')
    echo "Found device: $DEVICE_NAME"
    echo "Building for device..."
    xcodebuild -project CardPilot.xcodeproj -scheme CardPilot -destination "platform=iOS,name=$DEVICE_NAME" build
else
    echo "No device found. Building for simulator..."
    xcodebuild -project CardPilot.xcodeproj -scheme CardPilot -destination 'platform=iOS Simulator,name=iPhone 16' build
fi

echo "✅ Build complete. The URL scheme should now be registered."
echo ""
echo "📋 Next steps:"
echo "1. In Xcode, go to Project → Target → Info → URL Types"
echo "2. Add URL scheme 'cardpilot' if not present"
echo "3. Build and run on your iPhone"
echo "4. Test the NFC shortcut again"
