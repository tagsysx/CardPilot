import AppIntents
import Foundation
import CoreLocation
import CoreMotion
import SystemConfiguration
import Network
import SwiftData
import UIKit
import Darwin

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
        
        // 使用do-catch包装每个数据收集步骤，确保单个失败不影响整体
        print("🔧 Step 2.1: Setting GPS coordinates...")
        print("📍 Using GPS coordinates from Shortcuts parameters...")
        sessionData.latitude = latitude
        sessionData.longitude = longitude
        print("✅ GPS coordinates set: \(latitude), \(longitude)")
        
        // Parse address information from GPS coordinates
        if latitude != 0.0 && longitude != 0.0 {
            print("🔧 Step 2.2: Parsing address from GPS coordinates...")
            print("🏠 Parsing address from GPS coordinates...")
            do {
                let addressInfo = try await parseAddressFromCoordinates(latitude: latitude, longitude: longitude)
                sessionData.street = addressInfo.street
                sessionData.city = addressInfo.city
                sessionData.state = addressInfo.state
                sessionData.country = addressInfo.country
                sessionData.postalCode = addressInfo.postalCode
                sessionData.administrativeArea = addressInfo.state
                sessionData.subLocality = addressInfo.city
                print("✅ Address parsing completed: \(addressInfo.city ?? "Unknown"), \(addressInfo.state ?? "Unknown")")
            } catch {
                print("⚠️ Address parsing failed: \(error), continuing with other data collection")
                // 地址解析失败不影响其他数据收集
                sessionData.street = nil
                sessionData.city = nil
                sessionData.state = nil
                sessionData.country = nil
                sessionData.postalCode = nil
                sessionData.administrativeArea = nil
                sessionData.subLocality = nil
            }
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
        do {
            let networkData = try await collectNetworkDataInBackground()
            sessionData.ipAddress = networkData.ipAddress
            sessionData.wifiSSID = networkData.wifiSSID
            print("✅ Network data collected: IP: \(networkData.ipAddress ?? "Unknown"), WiFi: \(networkData.wifiSSID ?? "Unknown")")
        } catch {
            print("⚠️ Network data collection failed: \(error), using fallback values")
            // 网络数据收集失败时使用备选值
            sessionData.ipAddress = "Network Error"
            sessionData.wifiSSID = wifi.isEmpty ? "Unknown" : wifi
        }
        
        print("🔧 Step 2.4: Collecting sensor data...")
        print("📱 Collecting sensor data...")
        do {
            let sensorData = try await collectSensorDataInBackground()
            sessionData.magnetometerData = sensorData.magnetometerData
            sessionData.barometerData = sensorData.barometerData
            sessionData.ambientLightData = sensorData.ambientLightData
            sessionData.proximityData = sensorData.proximityData
            sessionData.pedometerData = sensorData.pedometerData
            sessionData.temperatureData = sensorData.temperatureData
            sessionData.imuData = sensorData.imuData
            print("✅ Sensor data assigned to session")
        } catch {
            print("⚠️ Sensor data collection failed: \(error), continuing with basic data")
            // 传感器数据收集失败时设置为nil，不影响基本功能
            sessionData.magnetometerData = nil
            sessionData.barometerData = nil
            sessionData.ambientLightData = nil
            sessionData.proximityData = nil
            sessionData.pedometerData = nil
            sessionData.temperatureData = nil
            sessionData.imuData = nil
        }
        
        // Note: batteryData and systemResourceData are not stored in NFCSessionData model
        // They are collected but not persisted to avoid model changes
        
        print("🔧 Step 2.5: Collecting screen state data...")
        let screenData = collectScreenStateData()
        sessionData.screenState = screenData.state
        sessionData.screenBrightness = screenData.brightness
        sessionData.screenStateHistory = screenData.history
        print("✅ Screen state data collected")
        
        print("🔧 Step 2.6: Setting metadata...")
        sessionData.currentAppName = "Shortcuts App Intent"
        sessionData.nfcTagData = nfc
        sessionData.nfcUsageType = "shortcuts_triggered"
        sessionData.nfcTriggerSource = "app_intent"
        sessionData.nfcSessionDuration = 0
        print("✅ Metadata set successfully")
        
        // Add NFC usage record if NFC info is not empty
        if !nfc.isEmpty {
            print("🔧 Step 2.7: Creating NFC usage record...")
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
        
        // 检查网络连接状态
        guard await isNetworkAvailable() else {
            print("⚠️ No network connection available, skipping address parsing")
            // 返回nil而不是抛出错误，这样应用不会崩溃
            return (nil, nil, nil, nil, nil)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    print("⚠️ Geocoding error: \(error)")
                    // 检查是否是网络相关错误
                    if let clError = error as? CLError, clError.code == .network {
                        print("⚠️ Network error during geocoding, returning nil for address fields")
                        continuation.resume(returning: (nil, nil, nil, nil, nil))
                    } else {
                        print("⚠️ Other geocoding error, returning nil for address fields")
                        continuation.resume(returning: (nil, nil, nil, nil, nil))
                    }
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    print("⚠️ No placemark found for coordinates")
                    continuation.resume(returning: (nil, nil, nil, nil, nil))
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
    
    // MARK: - Network Availability Check
    
    private func isNetworkAvailable() async -> Bool {
        // 使用Network框架检查网络连接状态
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        return await withCheckedContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                let isAvailable = path.status == .satisfied
                print("🌐 Network status: \(isAvailable ? "Available" : "Unavailable")")
                continuation.resume(returning: isAvailable)
                monitor.cancel()
            }
            monitor.start(queue: queue)
            
            // 设置超时，避免无限等待
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if monitor.pathUpdateHandler != nil {
                    print("⚠️ Network check timed out, assuming unavailable")
                    continuation.resume(returning: false)
                    monitor.cancel()
                }
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
        // 首先检查网络连接
        guard await isNetworkAvailable() else {
            print("⚠️ No network connection available, returning local IP or fallback")
            // 尝试获取本地IP地址作为备选
            if let localIP = getLocalIPAddress() {
                return localIP
            }
            return "No Network"
        }
        
        // 尝试获取公网IP地址
        do {
            let url = URL(string: "https://api.ipify.org")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let publicIP = String(data: data, encoding: .utf8) ?? "Unknown"
            print("✅ Public IP address obtained: \(publicIP)")
            return publicIP
        } catch {
            print("⚠️ Failed to get public IP address: \(error), trying local IP")
            // 如果获取公网IP失败，尝试本地IP
            if let localIP = getLocalIPAddress() {
                return localIP
            }
            return "Unknown"
        }
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        
        // 获取本地机器上所有接口的列表
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // 遍历每个接口
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // 检查IPv4或IPv6接口
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // 检查接口名称
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "pdp_ip0" { // WiFi或蜂窝网络
                    
                    // 将接口地址转换为人类可读的字符串
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
    
    private func getWiFiSSIDFromSystem() -> String? {
        #if targetEnvironment(simulator)
        return "Simulator_WiFi"
        #else
        // Try to get WiFi SSID (limited on iOS 14+)
        do {
            guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
                print("⚠️ Failed to get supported interfaces")
                return nil
            }
            
            for interfaceName in interfaceNames {
                if let networkInfo = CNCopyCurrentNetworkInfo(interfaceName as CFString) as? [String: Any],
                   let ssid = networkInfo[kCNNetworkInfoKeySSID as String] as? String {
                    print("✅ WiFi SSID obtained from system: \(ssid)")
                    return ssid
                }
            }
            
            print("⚠️ No WiFi SSID found in system interfaces")
            return nil
        } catch {
            print("⚠️ Error getting WiFi SSID from system: \(error)")
            return nil
        }
        #endif
    }
    
    // MARK: - Sensor Data Collection
    
    private func collectSensorDataInBackground() async throws -> (magnetometerData: Data?, barometerData: Data?, ambientLightData: Data?, proximityData: Data?, pedometerData: Data?, temperatureData: Data?, deviceOrientationData: Data?, batteryData: Data?, systemResourceData: Data?, imuData: Data?) {
        
        print("🔧 collectSensorDataInBackground: Starting sensor data collection...")
        
        // Note: Individual sensor collection functions have their own timeouts
        
        // Collect sensor data with individual error handling
        var magnetometerData: Data? = nil
        var barometerData: Data? = nil
        var imuData: Data? = nil
        
        print("🔧 Collecting magnetometer data...")
        do {
            magnetometerData = try await collectMagnetometerData()
            print("✅ Magnetometer data: \(magnetometerData != nil ? "Collected" : "Not available")")
        } catch {
            print("⚠️ Magnetometer data collection failed: \(error)")
            magnetometerData = nil
        }
        
        print("🔧 Collecting barometer data...")
        do {
            barometerData = try await collectBarometerData()
            print("✅ Barometer data: \(barometerData != nil ? "Collected" : "Not available")")
        } catch {
            print("⚠️ Barometer data collection failed: \(error)")
            barometerData = nil
        }
        
        print("🔧 Collecting ambient light data...")
        let ambientLightData = collectAmbientLightData()
        print("✅ Ambient light data: \(ambientLightData != nil ? "Collected" : "Not available")")
        
        print("🔧 Collecting proximity data...")
        let proximityData = collectProximityData()
        print("✅ Proximity data: \(proximityData != nil ? "Collected" : "Not available")")
        
        print("🔧 Collecting IMU data...")
        do {
            imuData = try await collectIMUData()
            print("✅ IMU data: \(imuData != nil ? "Collected" : "Not available")")
        } catch {
            print("⚠️ IMU data collection failed: \(error)")
            imuData = nil
        }
        
        print("🔧 Collecting temperature data...")
        let temperatureData = collectTemperatureData()
        print("✅ Temperature data: \(temperatureData != nil ? "Collected" : "Not available")")
        
        // Set unused sensor data to nil
        let pedometerData: Data? = nil
        let deviceOrientationData: Data? = nil
        let batteryData: Data? = nil
        let systemResourceData: Data? = nil
        
        print("✅ collectSensorDataInBackground: Sensor data collection completed")
        
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
            
            // Use a flag to ensure continuation is only resumed once
            var hasResumed = false
            
            // Set a timeout for magnetometer data collection
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 second timeout
                print("⚠️ Magnetometer data collection timed out after 3 seconds")
                motionManager.stopMagnetometerUpdates()
                
                // Only resume if not already resumed
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: nil)
                }
            }
            
            motionManager.startMagnetometerUpdates(to: .main) { data, error in
                timeoutTask.cancel() // Cancel timeout task
                motionManager.stopMagnetometerUpdates()
                
                // Only proceed if not already resumed
                guard !hasResumed else { return }
                hasResumed = true
                
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
            
            // Use a flag to ensure continuation is only resumed once
            var hasResumed = false
            
            // Set a timeout for barometer data collection
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 second timeout
                print("⚠️ Barometer data collection timed out after 3 seconds")
                altimeter.stopRelativeAltitudeUpdates()
                
                // Only resume if not already resumed
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: nil)
                }
            }
            
            altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
                timeoutTask.cancel() // Cancel timeout task
                altimeter.stopRelativeAltitudeUpdates()
                
                // Only proceed if not already resumed
                guard !hasResumed else { return }
                hasResumed = true
                
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
        do {
            let brightness = UIScreen.main.brightness
            let ambientLightData = AmbientLightData(
                timestamp: Date().timeIntervalSince1970,
                brightness: Double(brightness) * 1000
            )
            
            let encodedData = try JSONEncoder().encode(ambientLightData)
            print("✅ Ambient light data encoded successfully")
            return encodedData
        } catch {
            print("⚠️ Failed to encode ambient light data: \(error)")
            return nil
        }
    }
    
    private func collectProximityData() -> Data? {
        do {
            let isClose = UIDevice.current.proximityState
            let proximityData = ProximityData(
                timestamp: Date().timeIntervalSince1970,
                distance: isClose ? 0.05 : nil,
                isClose: isClose
            )
            
            let encodedData = try JSONEncoder().encode(proximityData)
            print("✅ Proximity data encoded successfully")
            return encodedData
        } catch {
            print("⚠️ Failed to encode proximity data: \(error)")
            return nil
        }
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
            
            // Use a flag to ensure continuation is only resumed once
            var hasResumed = false
            
            // Set a timeout for IMU data collection based on user settings
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(collectionDuration * 1_000_000_000))
                print("⚠️ IMU data collection completed after \(collectionDuration) seconds")
                motionManager.stopDeviceMotionUpdates()
                
                // Only resume if not already resumed
                guard !hasResumed else { return }
                hasResumed = true
                
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
                    
                    // Only resume if not already resumed
                    guard !hasResumed else { return }
                    hasResumed = true
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
                    
                    // Only resume if not already resumed
                    guard !hasResumed else { return }
                    hasResumed = true
                    
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
        do {
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
            
            let encodedData = try JSONEncoder().encode(temperatureData)
            print("✅ Temperature data encoded successfully")
            return encodedData
        } catch {
            print("⚠️ Failed to encode temperature data: \(error)")
            return nil
        }
    }
    
    // MARK: - Device Data Collection
    
    private func collectDeviceDataInBackground() async throws -> Void {
        // Additional device-specific data collection if needed
        return
    }
    
    // MARK: - Screen State Data Collection
    
    private func collectScreenStateData() -> (state: String, brightness: Double, history: Data?) {
        // 获取当前屏幕状态
        let currentBrightness = UIScreen.main.brightness
        let currentState = currentBrightness > 0 ? "on" : "off"
        
        // 创建屏幕状态历史记录
        let screenStateEvent = ScreenStateEvent(
            timestamp: Date(),
            isScreenOn: currentBrightness > 0,
            reason: "App Intent triggered",
            brightness: currentBrightness
        )
        
        // 编码为Data
        let historyData = try? JSONEncoder().encode([screenStateEvent])
        
        print("✅ Screen state collected: \(currentState), brightness: \(currentBrightness)")
        
        return (currentState, currentBrightness, historyData)
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