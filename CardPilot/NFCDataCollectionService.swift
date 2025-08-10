//
//  NFCDataCollectionService.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import Foundation
import SwiftData
import CoreLocation

@MainActor
class NFCDataCollectionService: ObservableObject {
    private let locationManager = LocationManager()
    private let networkManager = NetworkManager()
    private let motionManager = MotionManager()
    private let currentAppDetector = CurrentAppDetector()
    private let sensorManager = SensorManager()
    private let nfcUsageTracker = NFCUsageTracker()
    
    @Published var isCollecting = false
    @Published var lastCollectionResult: NFCSessionData?
    @Published var lastError: String?
    @Published var collectionProgress: String = ""
    
    func collectAllData(modelContext: ModelContext, urlParameters: [String: Any]? = nil) async -> NFCSessionData {
        isCollecting = true
        lastError = nil
        collectionProgress = "Starting data collection..."
        
        let sessionData = NFCSessionData()
        
        do {
            // Collect all data concurrently where possible
            collectionProgress = "Collecting location, network, app, motion, and sensor data..."
            
            async let locationTask = collectLocationData()
            async let ipAddressTask = networkManager.getCurrentIPAddress()
            async let currentAppTask = getCurrentApp(parameters: urlParameters)
            async let imuDataTask = motionManager.collectIMUData()
            async let sensorDataTask = collectSensorData()
            
            // Wait for all tasks to complete
            let (locationData, ipAddress, currentApp, imuData, sensorData) = await (locationTask, ipAddressTask, currentAppTask, imuDataTask, sensorDataTask)
            
            collectionProgress = "Processing collected data..."
            
            // Update session data with collected information
            if let location = locationData.location {
                sessionData.latitude = location.coordinate.latitude
                sessionData.longitude = location.coordinate.longitude
            }
            
            // 添加宏观地点信息
            let details = locationData.details
            sessionData.street = details.street
            sessionData.city = details.city
            sessionData.state = details.state
            sessionData.country = details.country
            sessionData.postalCode = details.postalCode
            sessionData.administrativeArea = details.administrativeArea
            sessionData.subLocality = details.subLocality
            
            // 添加传感器数据
            sessionData.magnetometerData = sensorData.magnetometerData
            sessionData.barometerData = sensorData.barometerData
            sessionData.ambientLightData = sensorData.ambientLightData
            sessionData.proximityData = sensorData.proximityData
            sessionData.pedometerData = sensorData.pedometerData
            sessionData.temperatureData = sensorData.temperatureData
            sessionData.microphoneData = sensorData.microphoneData
            // weatherData不再使用，设置为nil
            sessionData.weatherData = nil
            
            sessionData.ipAddress = ipAddress
            // 解码网络数据以获取WiFi SSID
            if let networkData = sensorData.networkData,
               let decodedNetworkData = try? JSONDecoder().decode(NetworkData.self, from: networkData) {
                sessionData.wifiSSID = decodedNetworkData.wifiSSID
            }
            sessionData.currentAppName = currentApp
            sessionData.imuData = imuData
            
            // 设置NFC使用信息
            sessionData.nfcTagData = extractNFCTagData(from: urlParameters)
            sessionData.nfcUsageType = detectUsageType(from: URL(string: "cardpilot://")!, parameters: urlParameters ?? [:]).rawValue
            sessionData.nfcTriggerSource = extractTriggerSource(from: URL(string: "cardpilot://")!, parameters: urlParameters ?? [:])
            sessionData.nfcSessionDuration = Date().timeIntervalSince(sessionData.timestamp)
            
            // 设置屏幕状态信息
            let screenStateManager = ScreenStateManager()
            let screenIndicator = screenStateManager.getScreenStateIndicator()
            sessionData.screenState = screenIndicator.isCurrentlyOn ? "on" : "off"
            sessionData.screenBrightness = Double(screenIndicator.currentBrightness)
            
            // 序列化屏幕状态历史
            if let historyData = try? JSONEncoder().encode(screenStateManager.screenStateHistory) {
                sessionData.screenStateHistory = historyData
            }
            
            // Save to SwiftData
            collectionProgress = "Saving data..."
            modelContext.insert(sessionData)
            
            try modelContext.save()
            collectionProgress = "Data collection completed successfully"
            print("NFC session data saved successfully")
            
            // 如果是真实NFC触发，记录到NFC Usage
            await recordNFCUsageIfNeeded(urlParameters: urlParameters, modelContext: modelContext)
            
            // Validate data quality
            var warnings: [String] = []
            if sessionData.latitude == nil { warnings.append("Location") }
            if sessionData.ipAddress == nil { warnings.append("IP Address") }
            if sessionData.imuData == nil { warnings.append("Motion Data") }
            
            if !warnings.isEmpty {
                lastError = "Some data could not be collected: \(warnings.joined(separator: ", "))"
            }
            
        } catch {
            lastError = "Failed to save session data: \(error.localizedDescription)"
            print("Failed to save NFC session data: \(error)")
        }
        
        lastCollectionResult = sessionData
        isCollecting = false
        collectionProgress = ""
        
        return sessionData
    }
    
    private func collectLocationData() async -> (location: CLLocation?, details: DetailedLocationInfo) {
        return await locationManager.getCurrentLocationWithDetails()
    }
    
    private func getCurrentApp(parameters: [String: Any]?) -> String {
        // 首先检查URL参数中的sourceApp
        if let urlParams = parameters,
           let sourceApp = urlParams["sourceApp"] as? String,
           !sourceApp.isEmpty {
            return sourceApp
        }
        
        // 其次尝试从Shortcuts参数获取
        if let app = currentAppDetector.getCurrentAppNameFromShortcuts(parameters: parameters) {
            return app
        }
        
        // 最后回退到默认检测
        return currentAppDetector.getCurrentAppName() ?? "Unknown"
    }
    
    // Method to handle URL scheme launches
    func handleURLScheme(_ url: URL, modelContext: ModelContext) async -> NFCSessionData {
        // Extract parameters from URL
        var parameters: [String: Any] = [:]
        
        if let appName = currentAppDetector.handleURLScheme(url) {
            parameters["triggeringApp"] = appName
        }
        
        // 自动记录NFC使用情况
        let usageTracker = NFCUsageTracker()
        await usageTracker.recordNFCUsage(
            usageType: detectUsageType(from: url, parameters: parameters),
            triggerSource: extractTriggerSource(from: url, parameters: parameters),
            modelContext: modelContext
        )
        
        return await collectAllData(modelContext: modelContext, urlParameters: parameters)
    }
    
    // Method to be called from Shortcuts app
    func handleShortcutTrigger(modelContext: ModelContext, shortcutParameters: [String: Any]? = nil) async -> NFCSessionData {
        return await collectAllData(modelContext: modelContext, urlParameters: shortcutParameters)
    }
    
    // MARK: - NFC Usage Type Detection
    
    private func detectUsageType(from url: URL, parameters: [String: Any]) -> NFCUsageType {
        // 优先检查URL参数中的type字段
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let typeParam = components?.queryItems?.first(where: { $0.name == "type" })?.value {
            switch typeParam.lowercased() {
            case "payment", "pay":
                return .payment
            case "transport", "bus", "metro", "train":
                return .transport
            case "access", "door", "key", "entry":
                return .access
            case "identification", "id", "identity":
                return .identification
            default:
                break
            }
        }
        
        // 其次检查URL中的关键词
        let urlString = url.absoluteString.lowercased()
        if urlString.contains("payment") || urlString.contains("pay") {
            return .payment
        } else if urlString.contains("transport") || urlString.contains("bus") || urlString.contains("metro") {
            return .transport
        } else if urlString.contains("access") || urlString.contains("door") || urlString.contains("key") {
            return .access
        } else if urlString.contains("id") || urlString.contains("identity") {
            return .identification
        }
        
        // 检查触发应用
        if let triggeringApp = parameters["triggeringApp"] as? String {
            let appName = triggeringApp.lowercased()
            if appName.contains("wallet") || appName.contains("pay") {
                return .payment
            } else if appName.contains("transport") || appName.contains("metro") {
                return .transport
            }
        }
        
        // 默认推测为支付类型（最常见的NFC使用场景）
        return .payment
    }
    
    private func extractTriggerSource(from url: URL, parameters: [String: Any]) -> String {
        // 提取触发源信息
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // 优先使用URL参数中的sourceApp
        if let sourceApp = components?.queryItems?.first(where: { $0.name == "sourceApp" })?.value {
            return "nfc_shortcut_\(sourceApp.lowercased())"
        }
        
        // 其次使用参数中的triggeringApp
        if let triggeringApp = parameters["triggeringApp"] as? String {
            return "nfc_shortcut_\(triggeringApp.lowercased())"
        }
        
        // 默认返回手动触发
        return "manual"
    }
    
    private func extractNFCTagData(from parameters: [String: Any]?) -> String? {
        // 从参数中提取NFC标签数据
        guard let parameters = parameters else { return nil }
        
                        // 优先检查nfc参数（NFC UID或其他输入）
                if let nfc = parameters["nfc"] as? String, !nfc.isEmpty {
                    return nfc
                }
        
        // 检查是否有NFC标签数据
        if let nfcData = parameters["nfcTagData"] as? String {
            return nfcData
        }
        
        // 检查是否有标签ID
        if let tagId = parameters["tagId"] as? String {
            return "Tag ID: \(tagId)"
        }
        
        // 检查是否有标签类型
        if let tagType = parameters["tagType"] as? String {
            return "Tag Type: \(tagType)"
        }
        
        return nil
    }
    
    // MARK: - 传感器数据收集
    private func collectSensorData() async -> SensorDataCollection {
        collectionProgress = "Collecting sensor data..."
        
        do {
            // 获取位置用于天气数据
            let locationData = await locationManager.getCurrentLocationWithDetails()
            
            // 收集所有传感器数据
            await sensorManager.collectAllSensorData(for: locationData.location)
            
            // 等待音频录制完成（3秒）
            try await Task.sleep(nanoseconds: 3_000_000_000)
            
            // 序列化传感器数据，使用安全的编码方式
            let magnetometerData = try? JSONEncoder().encode(sensorManager.magnetometerData)
            let barometerData = try? JSONEncoder().encode(sensorManager.barometerData)
            let ambientLightData = try? JSONEncoder().encode(sensorManager.ambientLightData)
            let proximityData = try? JSONEncoder().encode(sensorManager.proximityData)
            let pedometerData = try? JSONEncoder().encode(sensorManager.pedometerData)
            let temperatureData = try? JSONEncoder().encode(sensorManager.temperatureData)
            let microphoneData = try? JSONEncoder().encode(sensorManager.microphoneData)
            let deviceOrientationData = try? JSONEncoder().encode(sensorManager.deviceOrientationData)
            let batteryData = try? JSONEncoder().encode(sensorManager.batteryData)
            let networkData = try? JSONEncoder().encode(sensorManager.networkData)
            let systemResourceData = try? JSONEncoder().encode(sensorManager.systemResourceData)
            // weatherData不再使用，设置为nil
            let weatherData: Data? = nil
            
            return SensorDataCollection(
                magnetometerData: magnetometerData,
                barometerData: barometerData,
                ambientLightData: ambientLightData,
                proximityData: proximityData,
                pedometerData: pedometerData,
                temperatureData: temperatureData,
                microphoneData: microphoneData,
                deviceOrientationData: deviceOrientationData,
                batteryData: batteryData,
                networkData: networkData,
                systemResourceData: systemResourceData,
                weatherData: weatherData
            )
        } catch {
            print("Error collecting sensor data: \(error)")
            // 返回空的传感器数据集合
            return SensorDataCollection(
                magnetometerData: nil,
                barometerData: nil,
                ambientLightData: nil,
                proximityData: nil,
                pedometerData: nil,
                temperatureData: nil,
                microphoneData: nil,
                deviceOrientationData: nil,
                batteryData: nil,
                networkData: nil,
                systemResourceData: nil,
                weatherData: nil
            )
        }
    }
}

// 传感器数据收集结果
struct SensorDataCollection {
    let magnetometerData: Data?
    let barometerData: Data?
    let ambientLightData: Data?
    let proximityData: Data?
    let pedometerData: Data?
    let temperatureData: Data?
    let microphoneData: Data?
    let deviceOrientationData: Data?
    let batteryData: Data?
    let networkData: Data?
    let systemResourceData: Data?
    let weatherData: Data?
}

// MARK: - NFC Usage Recording Extension
extension NFCDataCollectionService {
    
    /// 如果传入了NFC UID，记录到NFC Usage
    private func recordNFCUsageIfNeeded(urlParameters: [String: Any]?, modelContext: ModelContext) async {
        guard let urlParameters = urlParameters else { return }
        
        // 检查是否传入了NFC UID
        let sourceApp = urlParameters["sourceApp"] as? String ?? "Unknown"
        let nfc = urlParameters["nfc"] as? String
        
        // 只要传入了nfc参数且不为空，就记录到NFC Usage
        if let nfcUID = nfc, !nfcUID.isEmpty {
            // 推测NFC使用类型（基于UID模式）
            let usageType = inferNFCUsageType(nfcUID: nfcUID)
            
            print("📝 检测到NFC UID传入，UID: \(nfcUID)，来源: \(sourceApp)，记录到NFC Usage")
            
            await nfcUsageTracker.recordNFCUsage(
                usageType: usageType,
                triggerSource: sourceApp.lowercased() == "nfc" ? "nfc_detected" : "shortcuts_triggered",
                nfcUID: nfcUID,
                modelContext: modelContext
            )
        }
    }
    
    /// 基于NFC UID推测使用类型
    private func inferNFCUsageType(nfcUID: String) -> NFCUsageType {
        // 简单的启发式规则来推测卡片类型
        // 实际项目中可以基于历史数据、卡片特征等进行更精确的判断
        
        let uid = nfcUID.lowercased()
        
        // 一些常见的卡片UID模式（这些是示例，实际需要根据具体情况调整）
        if uid.contains("04") && uid.count >= 8 {
            // 通常以04开头的可能是支付卡
            return .payment
        } else if uid.hasPrefix("08") {
            // 08开头可能是门禁卡
            return .access
        } else if uid.hasPrefix("02") {
            // 02开头可能是交通卡
            return .transport
        }
        
        // 默认为未知类型
        return .unknown
    }
}
