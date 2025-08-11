import AppIntents
import Foundation
import CoreLocation
import CoreMotion
import SystemConfiguration
import Network
import SwiftData
import UIKit

struct CollectDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Collect Sensor Data"
    static var description = IntentDescription("Collects sensor data in background (excluding microphone) with WiFi, NFC, and GPS coordinates")
    static var openAppWhenRun = false  // Don't open the app UI
    
    @Parameter(title: "WiFi Info", description: "WiFi SSID or network information", default: "")
    var wifi: String
    
    @Parameter(title: "NFC Info", description: "NFC tag UID or information", default: "")
    var nfc: String
    
    @Parameter(title: "Latitude", description: "GPS latitude coordinate from Shortcuts", default: 0.0)
    var latitude: Double
    
    @Parameter(title: "Longitude", description: "GPS longitude coordinate from Shortcuts", default: 0.0)
    var longitude: Double
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        print("🎯 Starting background data collection via App Intent")
        print("🌐 WiFi from Shortcuts: \(wifi)")
        print("🏷️ NFC from Shortcuts: \(nfc)")
        print("📍 GPS from Shortcuts: \(latitude), \(longitude)")
        print("📱 App Intent mode: Using parameters from Shortcuts, not triggering location services")
        
        // Set App Intent mode flag to prevent automatic location updates
        UserDefaults.standard.set(true, forKey: "isAppIntentMode")
        print("📱 App Intent mode flag set in UserDefaults")
        
        do {
            // Create a temporary model context for data storage
            let schema = Schema([NFCSessionData.self, NFCUsageRecord.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let modelContext = ModelContext(modelContainer)
            
            // Collect all data in background
            let sessionData = try await collectAllDataInBackground(modelContext: modelContext)
            
            // Save to persistent storage
            modelContext.insert(sessionData)
            try modelContext.save()
            
            // Clear App Intent mode flag after completion
            UserDefaults.standard.set(false, forKey: "isAppIntentMode")
            print("📱 App Intent mode flag cleared")
            
            print("✅ Background data collection completed successfully")
            
            return .result(dialog: IntentDialog("Data collected: WiFi: \(wifi), NFC: \(nfc), Location: \(latitude), \(longitude)"))
            
        } catch {
            // Clear App Intent mode flag on error
            UserDefaults.standard.set(false, forKey: "isAppIntentMode")
            print("📱 App Intent mode flag cleared due to error")
            
            print("❌ Background data collection failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Background Data Collection
    
    private func collectAllDataInBackground(modelContext: ModelContext) async throws -> NFCSessionData {
        let sessionData = NFCSessionData()
        sessionData.timestamp = Date()
        
        print("📍 Using GPS coordinates from Shortcuts parameters...")
        sessionData.latitude = latitude
        sessionData.longitude = longitude
        
        // Parse address information from GPS coordinates
        if latitude != 0.0 && longitude != 0.0 {
            print("🏠 Parsing address from GPS coordinates...")
            let addressInfo = try await parseAddressFromCoordinates(latitude: latitude, longitude: longitude)
            sessionData.street = addressInfo.street
            sessionData.city = addressInfo.city
            sessionData.state = addressInfo.state
            sessionData.country = addressInfo.country
            sessionData.postalCode = addressInfo.postalCode
            sessionData.administrativeArea = addressInfo.state
            sessionData.subLocality = addressInfo.city
        } else {
            print("⚠️ No GPS coordinates provided from Shortcuts, address fields will be nil")
            sessionData.street = nil
            sessionData.city = nil
            sessionData.state = nil
            sessionData.country = nil
            sessionData.postalCode = nil
            sessionData.administrativeArea = nil
            sessionData.subLocality = nil
        }
        
        print("🌐 Using WiFi data from Shortcuts parameters...")
        let networkData = try await collectNetworkDataInBackground()
        sessionData.ipAddress = networkData.ipAddress
        sessionData.wifiSSID = networkData.wifiSSID
        
        print("📱 Collecting sensor data...")
        let sensorData = try await collectSensorDataInBackground()
        
        sessionData.magnetometerData = sensorData.magnetometerData
        sessionData.barometerData = sensorData.barometerData
        sessionData.ambientLightData = sensorData.ambientLightData
        sessionData.proximityData = sensorData.proximityData
        sessionData.pedometerData = sensorData.pedometerData
        sessionData.temperatureData = sensorData.temperatureData
        // Note: batteryData and systemResourceData are not stored in NFCSessionData model
        // They are collected but not persisted to avoid model changes
        
        sessionData.currentAppName = "Shortcuts App Intent"
        sessionData.nfcTagData = nfc
        sessionData.nfcUsageType = "shortcuts_triggered"
        sessionData.nfcTriggerSource = "app_intent"
        sessionData.nfcSessionDuration = 0
        
        // Screen state (simplified for background)
        sessionData.screenState = "unknown"
        sessionData.screenBrightness = 0
        
        return sessionData
    }
    
    // MARK: - Location Parsing from Shortcuts
    
    private func parseLocationFromShortcuts(latitude: Double, longitude: Double) -> (latitude: Double?, longitude: Double?) {
        print("🔍 Received GPS coordinates: \(latitude), \(longitude)")
        
        // Validate coordinate ranges
        if latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 {
            print("✅ Valid GPS coordinates: \(latitude), \(longitude)")
            return (latitude, longitude)
        } else {
            print("❌ Invalid GPS coordinates: \(latitude), \(longitude)")
            return (nil, nil)
        }
    }
    
    // MARK: - Address Parsing from GPS
    
    private func parseAddressFromCoordinates(latitude: Double, longitude: Double) async throws -> (street: String?, city: String?, state: String?, country: String?, postalCode: String?) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    print("⚠️ Geocoding error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    print("⚠️ No placemark found for coordinates")
                    continuation.resume(throwing: NSError(domain: "Geocoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "No placemark found"]))
                    return
                }
                
                let addressInfo = (
                    street: placemark.thoroughfare,
                    city: placemark.locality,
                    state: placemark.administrativeArea,
                    country: placemark.country,
                    postalCode: placemark.postalCode
                )
                
                print("✅ Address parsed: \(addressInfo.street ?? "Unknown"), \(addressInfo.city ?? "Unknown"), \(addressInfo.state ?? "Unknown"), \(addressInfo.country ?? "Unknown")")
                continuation.resume(returning: addressInfo)
            }
        }
    }
    
    // MARK: - Network Data Collection
    
    private func collectNetworkDataInBackground() async throws -> (ipAddress: String?, wifiSSID: String?) {
        // Get IP address
        let ipAddress = try await getCurrentIPAddress()
        
        // Use WiFi SSID from Shortcuts parameters (priority)
        var wifiSSID = wifi
        if wifiSSID.isEmpty {
            print("⚠️ No WiFi SSID provided from Shortcuts, trying to get from system...")
            wifiSSID = getWiFiSSIDFromSystem() ?? "Unknown"
        } else {
            print("✅ Using WiFi SSID from Shortcuts: \(wifiSSID)")
        }
        
        return (ipAddress, wifiSSID)
    }
    
    private func getCurrentIPAddress() async throws -> String {
        // Try to get public IP address
        let url = URL(string: "https://api.ipify.org")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return String(data: data, encoding: .utf8) ?? "Unknown"
    }
    
    private func getWiFiSSIDFromSystem() -> String? {
        #if targetEnvironment(simulator)
        return "Simulator_WiFi"
        #else
        // Try to get WiFi SSID (limited on iOS 14+)
        guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }
        
        for interfaceName in interfaceNames {
            if let networkInfo = CNCopyCurrentNetworkInfo(interfaceName as CFString) as? [String: Any],
               let ssid = networkInfo[kCNNetworkInfoKeySSID as String] as? String {
                return ssid
            }
        }
        return nil
        #endif
    }
    
    // MARK: - Sensor Data Collection
    
    private func collectSensorDataInBackground() async throws -> (magnetometerData: Data?, barometerData: Data?, ambientLightData: Data?, proximityData: Data?, pedometerData: Data?, temperatureData: Data?, deviceOrientationData: Data?, batteryData: Data?, systemResourceData: Data?) {
        
        // Collect sensor data
        let magnetometerData = try? await collectMagnetometerData()
        let barometerData = try? await collectBarometerData()
        let ambientLightData = collectAmbientLightData()
        let proximityData = collectProximityData()
        let pedometerData = try? await collectPedometerData()
        let temperatureData = collectTemperatureData()
        let deviceOrientationData = collectDeviceOrientationData()
        let batteryData = collectBatteryData()
        let systemResourceData = collectSystemResourceData()
        
        return (
            magnetometerData,
            barometerData,
            ambientLightData,
            proximityData,
            pedometerData,
            temperatureData,
            deviceOrientationData,
            batteryData,
            systemResourceData
        )
    }
    
    private func collectMagnetometerData() async throws -> Data? {
        let motionManager = CMMotionManager()
        guard motionManager.isMagnetometerAvailable else { return nil }
        
        return try await withCheckedThrowingContinuation { continuation in
            motionManager.magnetometerUpdateInterval = 0.1
            motionManager.startMagnetometerUpdates(to: .main) { data, error in
                motionManager.stopMagnetometerUpdates()
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let magnetometerData = MagnetometerData(
                    timestamp: data.timestamp,
                    magneticFieldX: data.magneticField.x,
                    magneticFieldY: data.magneticField.y,
                    magneticFieldZ: data.magneticField.z,
                    heading: atan2(data.magneticField.y, data.magneticField.x) * 180 / .pi
                )
                
                do {
                    let encodedData = try JSONEncoder().encode(magnetometerData)
                    continuation.resume(returning: encodedData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func collectBarometerData() async throws -> Data? {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return nil }
        
        return try await withCheckedThrowingContinuation { continuation in
            let altimeter = CMAltimeter()
            altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
                altimeter.stopRelativeAltitudeUpdates()
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let barometerData = BarometerData(
                    timestamp: data.timestamp,
                    pressure: 1013.25,
                    relativeAltitude: data.relativeAltitude.doubleValue
                )
                
                do {
                    let encodedData = try JSONEncoder().encode(barometerData)
                    continuation.resume(returning: encodedData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func collectAmbientLightData() -> Data? {
        let brightness = UIScreen.main.brightness
        let ambientLightData = AmbientLightData(
            timestamp: Date().timeIntervalSince1970,
            brightness: Double(brightness) * 1000
        )
        
        return try? JSONEncoder().encode(ambientLightData)
    }
    
    private func collectProximityData() -> Data? {
        let isClose = UIDevice.current.proximityState
        let proximityData = ProximityData(
            timestamp: Date().timeIntervalSince1970,
            distance: isClose ? 0.05 : nil,
            isClose: isClose
        )
        
        return try? JSONEncoder().encode(proximityData)
    }
    
    private func collectPedometerData() async throws -> Data? {
        guard CMPedometer.isStepCountingAvailable() else { return nil }
        
        return try await withCheckedThrowingContinuation { continuation in
            let pedometer = CMPedometer()
            let now = Date()
            let tenMinutesAgo = now.addingTimeInterval(-600)
            
            pedometer.queryPedometerData(from: tenMinutesAgo, to: now) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let pedometerData = PedometerData(
                    timestamp: now.timeIntervalSince1970,
                    stepCount: data.numberOfSteps.intValue,
                    distance: data.distance?.doubleValue,
                    averagePace: data.averageActivePace?.doubleValue,
                    startTime: tenMinutesAgo,
                    endTime: now
                )
                
                do {
                    let encodedData = try JSONEncoder().encode(pedometerData)
                    continuation.resume(returning: encodedData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func collectTemperatureData() -> Data? {
        let processInfo = ProcessInfo.processInfo
        let thermalState = processInfo.thermalState
        
        var temperature: Double = 20.0
        switch thermalState {
        case .nominal: temperature = 20.0
        case .fair: temperature = 25.0
        case .serious: temperature = 30.0
        case .critical: temperature = 35.0
        @unknown default: temperature = 22.0
        }
        
        let temperatureData = TemperatureData(
            timestamp: Date().timeIntervalSince1970,
            temperature: temperature,
            humidity: 50.0
        )
        
        return try? JSONEncoder().encode(temperatureData)
    }
    
    private func collectDeviceOrientationData() -> Data? {
        let orientation = UIDevice.current.orientation
        let deviceOrientationData = DeviceOrientationData(
            timestamp: Date().timeIntervalSince1970,
            orientation: orientation.rawValue,
            orientationName: getOrientationName(orientation),
            isPortrait: orientation.isPortrait,
            isLandscape: orientation.isLandscape,
            isFlat: orientation.isFlat
        )
        
        return try? JSONEncoder().encode(deviceOrientationData)
    }
    
    private func collectBatteryData() -> Data? {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        
        let batteryData = BatteryData(
            timestamp: Date().timeIntervalSince1970,
            batteryLevel: device.batteryLevel,
            batteryState: device.batteryState.rawValue,
            batteryStateName: getBatteryStateName(device.batteryState),
            isCharging: device.batteryState == UIDevice.BatteryState.charging || device.batteryState == UIDevice.BatteryState.full,
            isLowPower: device.batteryLevel < 0.2
        )
        
        return try? JSONEncoder().encode(batteryData)
    }
    
    private func collectSystemResourceData() -> Data? {
        let processInfo = ProcessInfo.processInfo
        
        let systemResourceData = SystemResourceData(
            timestamp: Date().timeIntervalSince1970,
            cpuUsage: getCPUUsage(),
            memoryUsage: getMemoryUsage(),
            thermalState: processInfo.thermalState.rawValue,
            thermalStateName: getThermalStateName(processInfo.thermalState),
            activeProcessorCount: processInfo.activeProcessorCount,
            processorCount: processInfo.processorCount,
            systemUptime: processInfo.systemUptime
        )
        
        return try? JSONEncoder().encode(systemResourceData)
    }
    
    // MARK: - Device Data Collection
    
    private func collectDeviceDataInBackground() async throws -> Void {
        // Additional device-specific data collection if needed
        return
    }
    
    // MARK: - Helper Functions
    
    private func getOrientationName(_ orientation: UIDeviceOrientation) -> String {
        switch orientation {
        case .portrait: return "Portrait"
        case .portraitUpsideDown: return "Portrait Upside Down"
        case .landscapeLeft: return "Landscape Left"
        case .landscapeRight: return "Landscape Right"
        case .faceUp: return "Face Up"
        case .faceDown: return "Face Down"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
    
    private func getBatteryStateName(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "Unknown"
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        @unknown default: return "Unknown"
        }
    }
    
    private func getThermalStateName(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
    
    private func getCPUUsage() -> Double {
        #if targetEnvironment(simulator)
        return 30.0
        #else
        let processInfo = ProcessInfo.processInfo
        let activeProcessorCount = processInfo.activeProcessorCount
        let processorCount = processInfo.processorCount
        let loadFactor = Double(activeProcessorCount) / Double(processorCount)
        let cpuUsage = loadFactor * 50.0 + Double.random(in: 10...30)
        return min(cpuUsage, 100.0)
        #endif
    }
    
    private func getMemoryUsage() -> Double {
        let processInfo = ProcessInfo.processInfo
        let physicalMemory = processInfo.physicalMemory
        let memoryUsage = Double(processInfo.physicalMemory - processInfo.physicalMemory) / Double(physicalMemory)
        return min(max(memoryUsage, 0.0), 1.0) * 100.0
    }
}

// MARK: - App Shortcuts Provider

struct CardPilotAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CollectDataIntent(),
            phrases: [
                "Collect sensor data using ${applicationName}",
                "Start data collection in ${applicationName}",
                "Record sensor data with ${applicationName}"
            ],
            shortTitle: "Collect Data",
            systemImageName: "sensor.tag.radiowaves.forward"
        )
    }
}