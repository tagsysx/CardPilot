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
        print("📱 App Intent mode: Using parameters from Shortcuts, not triggering location services")
        print("🌐 WiFi from Shortcuts: \(wifi)")
        print("🏷️ NFC from Shortcuts: \(nfc)")
        print("📍 GPS from Shortcuts: \(latitude), \(longitude)")
        
        // Set App Intent mode flag to prevent automatic location updates
        UserDefaults.standard.set(true, forKey: "isAppIntentMode")
        print("📱 App Intent mode flag set in UserDefaults")
        
        do {
            print("🔧 Step 1: Creating model context...")
            // Create a temporary model context for data storage
            let schema = Schema([NFCSessionData.self, NFCUsageRecord.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let modelContext = ModelContext(modelContainer)
            print("✅ Model context created successfully")
            
            print("🔧 Step 2: Starting data collection...")
            // Collect all data in background
            let sessionData = try await collectAllDataInBackground(modelContext: modelContext)
            print("✅ Data collection completed")
            
            print("🔧 Step 3: Saving data to persistent storage...")
            // Save to persistent storage
            modelContext.insert(sessionData)
            try modelContext.save()
            print("✅ Data saved successfully")
            
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
            print("❌ Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error user info: \(nsError.userInfo)")
            }
            throw error
        }
    }
    
    // MARK: - Background Data Collection
    
    private func collectAllDataInBackground(modelContext: ModelContext) async throws -> NFCSessionData {
        print("🔧 collectAllDataInBackground: Starting...")
        let sessionData = NFCSessionData()
        sessionData.timestamp = Date()
        print("✅ Session data initialized with timestamp: \(sessionData.timestamp)")
        
        print("🔧 Step 2.1: Setting GPS coordinates...")
        print("📍 Using GPS coordinates from Shortcuts parameters...")
        sessionData.latitude = latitude
        sessionData.longitude = longitude
        print("✅ GPS coordinates set: \(latitude), \(longitude)")
        
        // Parse address information from GPS coordinates
        if latitude != 0.0 && longitude != 0.0 {
            print("🔧 Step 2.2: Parsing address from GPS coordinates...")
            print("🏠 Parsing address from GPS coordinates...")
            let addressInfo = try await parseAddressFromCoordinates(latitude: latitude, longitude: longitude)
            sessionData.street = addressInfo.street
            sessionData.city = addressInfo.city
            sessionData.state = addressInfo.state
            sessionData.country = addressInfo.country
            sessionData.postalCode = addressInfo.postalCode
            sessionData.administrativeArea = addressInfo.state
            sessionData.subLocality = addressInfo.city
            print("✅ Address parsing completed: \(addressInfo.city ?? "Unknown"), \(addressInfo.state ?? "Unknown")")
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
        
        print("🔧 Step 2.3: Collecting network data...")
        print("🌐 Using WiFi data from Shortcuts parameters...")
        let networkData = try await collectNetworkDataInBackground()
        sessionData.ipAddress = networkData.ipAddress
        sessionData.wifiSSID = networkData.wifiSSID
        print("✅ Network data collected: IP: \(networkData.ipAddress ?? "Unknown"), WiFi: \(networkData.wifiSSID ?? "Unknown")")
        
        print("🔧 Step 2.4: Collecting sensor data...")
        print("📱 Collecting sensor data...")
        let sensorData = try await collectSensorDataInBackground()
        print("✅ Sensor data collection started...")
        
        sessionData.magnetometerData = sensorData.magnetometerData
        sessionData.barometerData = sensorData.barometerData
        sessionData.ambientLightData = sensorData.ambientLightData
        sessionData.proximityData = sensorData.proximityData
        sessionData.pedometerData = sensorData.pedometerData
        sessionData.temperatureData = sensorData.temperatureData
        sessionData.imuData = sensorData.imuData  // Store IMU data
        print("✅ Sensor data assigned to session")
        
        // Note: batteryData and systemResourceData are not stored in NFCSessionData model
        // They are collected but not persisted to avoid model changes
        
        print("🔧 Step 2.5: Setting metadata...")
        sessionData.currentAppName = "Shortcuts App Intent"
        sessionData.nfcTagData = nfc
        sessionData.nfcUsageType = "shortcuts_triggered"
        sessionData.nfcTriggerSource = "app_intent"
        sessionData.nfcSessionDuration = 0
        
        // Screen state (simplified for background)
        sessionData.screenState = "unknown"
        sessionData.screenBrightness = 0
        print("✅ Metadata set successfully")
        
        // Add NFC usage record if NFC info is not empty
        if !nfc.isEmpty {
            print("🔧 Step 2.6: Creating NFC usage record...")
            let nfcUsageRecord = NFCUsageRecord(
                timestamp: Date(),
                triggerSource: "app_intent",
                usageType: .unknown,
                nfcUID: nfc
            )
            
            modelContext.insert(nfcUsageRecord)
            print("✅ NFC usage record created and inserted")
        } else {
            print("⚠️ No NFC info provided, skipping NFC usage record")
        }
        
        print("✅ collectAllDataInBackground: Completed successfully")
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
    
    private func collectSensorDataInBackground() async throws -> (magnetometerData: Data?, barometerData: Data?, ambientLightData: Data?, proximityData: Data?, pedometerData: Data?, temperatureData: Data?, deviceOrientationData: Data?, batteryData: Data?, systemResourceData: Data?, imuData: Data?) {
        
        print("🔧 collectSensorDataInBackground: Starting sensor data collection...")
        
        // Set overall timeout for sensor data collection
        let overallTimeout = Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 second overall timeout
            print("⚠️ Overall sensor data collection timed out after 10 seconds")
        }
        
        defer {
            overallTimeout.cancel()
        }
        
        // Collect sensor data
        print("🔧 Collecting magnetometer data...")
        let magnetometerData = try? await collectMagnetometerData()
        print("✅ Magnetometer data: \(magnetometerData != nil ? "Collected" : "Not available")")
        
        print("🔧 Collecting barometer data...")
        let barometerData = try? await collectBarometerData()
        print("✅ Barometer data: \(barometerData != nil ? "Collected" : "Not available")")
        
        print("🔧 Collecting ambient light data...")
        let ambientLightData = collectAmbientLightData()
        print("✅ Ambient light data: \(ambientLightData != nil ? "Collected" : "Not available")")
        
        print("🔧 Collecting proximity data...")
        let proximityData = collectProximityData()
        print("✅ Proximity data: \(proximityData != nil ? "Collected" : "Not available")")
        
        print("🔧 Collecting IMU data...")
        let imuData = try? await collectIMUData()
        print("✅ IMU data: \(imuData != nil ? "Collected" : "Not available")")
        
        print("🔧 Collecting temperature data...")
        let temperatureData = collectTemperatureData()
        print("✅ Temperature data: \(temperatureData != nil ? "Collected" : "Not available")")
        
        // Set unused sensor data to nil
        let pedometerData: Data? = nil
        let deviceOrientationData: Data? = nil
        let batteryData: Data? = nil
        let systemResourceData: Data? = nil
        
        print("✅ collectSensorDataInBackground: All sensor data collected successfully")
        
        return (
            magnetometerData,
            barometerData,
            ambientLightData,
            proximityData,
            pedometerData,
            temperatureData,
            deviceOrientationData,
            batteryData,
            systemResourceData,
            imuData
        )
    }
    
    private func collectMagnetometerData() async throws -> Data? {
        print("🔧 collectMagnetometerData: Starting...")
        
        let motionManager = CMMotionManager()
        guard motionManager.isMagnetometerAvailable else { 
            print("⚠️ Magnetometer not available")
            return nil 
        }
        
        print("🔧 Magnetometer is available, starting data collection...")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
            motionManager.magnetometerUpdateInterval = 0.1
            
            // Set a timeout for magnetometer data collection
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 second timeout
                print("⚠️ Magnetometer data collection timed out after 3 seconds")
                motionManager.stopMagnetometerUpdates()
                continuation.resume(returning: nil)
            }
            
            motionManager.startMagnetometerUpdates(to: .main) { data, error in
                timeoutTask.cancel() // Cancel timeout task
                motionManager.stopMagnetometerUpdates()
                
                if let error = error {
                    print("❌ Magnetometer error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let data = data else {
                    print("⚠️ No magnetometer data received")
                    continuation.resume(returning: nil)
                    return
                }
                
                print("✅ Magnetometer data received")
                
                let magnetometerData = MagnetometerData(
                    timestamp: data.timestamp,
                    magneticFieldX: data.magneticField.x,
                    magneticFieldY: data.magneticField.y,
                    magneticFieldZ: data.magneticField.z,
                    heading: atan2(data.magneticField.y, data.magneticField.x) * 180 / .pi
                )
                
                do {
                    let encodedData = try JSONEncoder().encode(magnetometerData)
                    print("✅ Magnetometer data encoded successfully")
                    continuation.resume(returning: encodedData)
                } catch {
                    print("❌ Magnetometer data encoding error: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func collectBarometerData() async throws -> Data? {
        print("🔧 collectBarometerData: Starting...")
        
        guard CMAltimeter.isRelativeAltitudeAvailable() else { 
            print("⚠️ Barometer not available")
            return nil 
        }
        
        print("🔧 Barometer is available, starting data collection...")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
            let altimeter = CMAltimeter()
            
            // Set a timeout for barometer data collection
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 second timeout
                print("⚠️ Barometer data collection timed out after 3 seconds")
                altimeter.stopRelativeAltitudeUpdates()
                continuation.resume(returning: nil)
            }
            
            altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
                timeoutTask.cancel() // Cancel timeout task
                altimeter.stopRelativeAltitudeUpdates()
                
                if let error = error {
                    print("❌ Barometer error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let data = data else {
                    print("⚠️ No barometer data received")
                    continuation.resume(returning: nil)
                    return
                }
                
                print("✅ Barometer data received")
                
                let barometerData = BarometerData(
                    timestamp: data.timestamp,
                    pressure: 1013.25,
                    relativeAltitude: data.relativeAltitude.doubleValue
                )
                
                do {
                    let encodedData = try JSONEncoder().encode(barometerData)
                    print("✅ Barometer data encoded successfully")
                    continuation.resume(returning: encodedData)
                } catch {
                    print("❌ Barometer data encoding error: \(error)")
                    continuation.resume(returning: nil)
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
    
    private func collectIMUData() async throws -> Data? {
        print("🔧 collectIMUData: Starting...")
        
        // Read IMU collection duration from user settings
        let collectionDuration: TimeInterval = UserDefaults.standard.double(forKey: "imuCollectionDuration") > 0 ?
            UserDefaults.standard.double(forKey: "imuCollectionDuration") : 5.0
        
        print("🔧 IMU collection duration from settings: \(collectionDuration) seconds")
        
        let motionManager = CMMotionManager()
        guard motionManager.isDeviceMotionAvailable else {
            print("⚠️ Device motion not available")
            return nil
        }
        
        print("🔧 Device motion is available, starting data collection...")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
            motionManager.deviceMotionUpdateInterval = 0.1
            
            var dataPoints: [IMUDataPoint] = []
            let startTime = Date()
            
            // Set a timeout for IMU data collection based on user settings
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(collectionDuration * 1_000_000_000))
                print("⚠️ IMU data collection completed after \(collectionDuration) seconds")
                motionManager.stopDeviceMotionUpdates()
                
                if !dataPoints.isEmpty {
                    let imuSession = IMUSession(
                        dataPoints: dataPoints,
                        startTime: startTime,
                        endTime: Date()
                    )
                    
                    do {
                        let encodedData = try JSONEncoder().encode(imuSession)
                        print("✅ IMU data encoded successfully with \(dataPoints.count) data points")
                        continuation.resume(returning: encodedData)
                    } catch {
                        print("❌ IMU data encoding error: \(error)")
                        continuation.resume(returning: nil)
                    }
                } else {
                    print("⚠️ No IMU data points collected")
                    continuation.resume(returning: nil)
                }
            }
            
            motionManager.startDeviceMotionUpdates(to: .main) { data, error in
                if let error = error {
                    print("❌ IMU error: \(error)")
                    timeoutTask.cancel()
                    motionManager.stopDeviceMotionUpdates()
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let data = data else {
                    print("⚠️ No IMU data received")
                    return
                }
                
                let dataPoint = IMUDataPoint(
                    timestamp: data.timestamp,
                    accelerationX: data.userAcceleration.x,
                    accelerationY: data.userAcceleration.y,
                    accelerationZ: data.userAcceleration.z,
                    rotationRateX: data.rotationRate.x,
                    rotationRateY: data.rotationRate.y,
                    rotationRateZ: data.rotationRate.z
                )
                
                dataPoints.append(dataPoint)
                print("✅ IMU data point collected: \(dataPoints.count)")
                
                // Check if we've collected enough data based on user settings
                let elapsedTime = Date().timeIntervalSince(startTime)
                if elapsedTime >= collectionDuration {
                    timeoutTask.cancel()
                    motionManager.stopDeviceMotionUpdates()
                    
                    let imuSession = IMUSession(
                        dataPoints: dataPoints,
                        startTime: startTime,
                        endTime: Date()
                    )
                    
                    do {
                        let encodedData = try JSONEncoder().encode(imuSession)
                        print("✅ IMU data collection completed with \(dataPoints.count) data points")
                        continuation.resume(returning: encodedData)
                    } catch {
                        print("❌ IMU data encoding error: \(error)")
                        continuation.resume(returning: nil)
                    }
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
    
    // MARK: - Device Data Collection
    
    private func collectDeviceDataInBackground() async throws -> Void {
        // Additional device-specific data collection if needed
        return
    }
    
    // MARK: - App Shortcuts Provider
}

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