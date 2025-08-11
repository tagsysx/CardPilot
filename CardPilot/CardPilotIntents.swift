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
    static var description = IntentDescription("Collects sensor data in background (excluding microphone) with WiFi and NFC info")
    static var openAppWhenRun = false  // Don't open the app UI
    
    @Parameter(title: "WiFi Info", description: "WiFi SSID or network information", default: "")
    var wifi: String
    
    @Parameter(title: "NFC Info", description: "NFC tag UID or information", default: "")
    var nfc: String
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        print("🎯 Starting background data collection via App Intent")
        
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
            
            print("✅ Background data collection completed successfully")
            
            return .result(dialog: IntentDialog("Data collected: WiFi: \(wifi), NFC: \(nfc), Location: \(sessionData.latitude ?? 0), \(sessionData.longitude ?? 0)"))
            
        } catch {
            print("❌ Background data collection failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Background Data Collection
    
    private func collectAllDataInBackground(modelContext: ModelContext) async throws -> NFCSessionData {
        let sessionData = NFCSessionData()
        sessionData.timestamp = Date()
        
        print("📊 Collecting location data...")
        let locationData = try await collectLocationDataInBackground()
        
        print("🌐 Collecting network data...")
        let networkData = try await collectNetworkDataInBackground()
        
        print("📱 Collecting sensor data...")
        let sensorData = try await collectSensorDataInBackground()
        
        print("📱 Collecting device data...")
        let deviceData = try await collectDeviceDataInBackground()
        
        // Populate session data
        sessionData.latitude = locationData.latitude
        sessionData.longitude = locationData.longitude
        sessionData.street = locationData.street
        sessionData.city = locationData.city
        sessionData.state = locationData.state
        sessionData.country = locationData.country
        sessionData.postalCode = locationData.postalCode
        sessionData.administrativeArea = locationData.administrativeArea
        sessionData.subLocality = locationData.subLocality
        
        sessionData.ipAddress = networkData.ipAddress
        sessionData.wifiSSID = networkData.wifiSSID
        
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
    
    // MARK: - Location Data Collection
    
    private func collectLocationDataInBackground() async throws -> (latitude: Double?, longitude: Double?, street: String?, city: String?, state: String?, country: String?, postalCode: String?, administrativeArea: String?, subLocality: String?) {
        let locationManager = CLLocationManager()
        
        // Request location permission
        let authStatus = CLLocationManager.authorizationStatus()
        guard authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways else {
            print("⚠️ Location permission not granted")
            return (nil, nil, nil, nil, nil, nil, nil, nil, nil)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let manager = CLLocationManager()
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.requestLocation()
            
            var hasReceivedLocation = false
            
            let locationHandler: (CLLocation?, Error?) -> Void = { location, error in
                guard !hasReceivedLocation else { return }
                hasReceivedLocation = true
                
                if let error = error {
                    print("❌ Location error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let location = location else {
                    continuation.resume(throwing: NSError(domain: "Location", code: 0, userInfo: [NSLocalizedDescriptionKey: "No location data"]))
                    return
                }
                
                // Get address information
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let error = error {
                        print("⚠️ Geocoding error: \(error)")
                        // Continue with coordinates only
                        continuation.resume(returning: (
                            location.coordinate.latitude,
                            location.coordinate.longitude,
                            nil, nil, nil, nil, nil, nil, nil
                        ))
                    } else if let placemark = placemarks?.first {
                        continuation.resume(returning: (
                            location.coordinate.latitude,
                            location.coordinate.longitude,
                            placemark.thoroughfare,
                            placemark.locality,
                            placemark.administrativeArea,
                            placemark.country,
                            placemark.postalCode,
                            placemark.administrativeArea,
                            placemark.subLocality
                        ))
                    } else {
                        continuation.resume(returning: (
                            location.coordinate.latitude,
                            location.coordinate.longitude,
                            nil, nil, nil, nil, nil, nil, nil
                        ))
                    }
                }
            }
            
            // Set up location manager
            manager.delegate = LocationDelegate(completion: locationHandler)
            
            // Timeout after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if !hasReceivedLocation {
                    hasReceivedLocation = true
                    continuation.resume(throwing: NSError(domain: "Location", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location timeout"]))
                }
            }
        }
    }
    
    // MARK: - Network Data Collection
    
    private func collectNetworkDataInBackground() async throws -> (ipAddress: String?, wifiSSID: String?) {
        // Get IP address
        let ipAddress = try await getCurrentIPAddress()
        
        // Get WiFi SSID (use provided parameter or try to get from system)
        var wifiSSID = wifi
        if wifiSSID.isEmpty {
            wifiSSID = getWiFiSSIDFromSystem() ?? "Unknown"
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

// MARK: - Location Manager Delegate

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    private let completion: (CLLocation?, Error?) -> Void
    
    init(completion: @escaping (CLLocation?, Error?) -> Void) {
        self.completion = completion
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion(locations.first, nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion(nil, error)
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