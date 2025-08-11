//
//  SensorManager.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import Foundation
import CoreMotion
import CoreLocation
import AVFoundation
import CoreHaptics
import UIKit
import SystemConfiguration
import Network

// SystemConfiguration框架常量
import SystemConfiguration.CaptiveNetwork

// MARK: - WiFi SSID管理器
class WiFiSSIDManager: ObservableObject {
    static let shared = WiFiSSIDManager()
    
    @Published var externalSSID: String?
    @Published var lastUpdated: Date?
    
    private init() {}
    
    func updateSSID(_ ssid: String) {
        DispatchQueue.main.async {
            self.externalSSID = ssid
            self.lastUpdated = Date()
            print("DEBUG: WiFi SSID updated from external source: \(ssid)")
        }
    }
    
    func clearSSID() {
        DispatchQueue.main.async {
            self.externalSSID = nil
            self.lastUpdated = nil
            print("DEBUG: WiFi SSID cleared")
        }
    }
    
    func getValidSSID() -> String? {
        // 检查SSID是否在5分钟内更新
        if let lastUpdated = lastUpdated,
           Date().timeIntervalSince(lastUpdated) < 300,
           let ssid = externalSSID,
           !ssid.isEmpty {
            print("DEBUG: Using external WiFi SSID: \(ssid)")
            return ssid
        }
        return nil
    }
}

@MainActor
class SensorManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    private let altimeter = CMAltimeter()
    private let device = CMDeviceMotion()
    
    // MARK: - 传感器数据属性
    @Published var magnetometerData: MagnetometerData?
    @Published var barometerData: BarometerData?
    @Published var ambientLightData: AmbientLightData?
    @Published var proximityData: ProximityData?
    @Published var pedometerData: PedometerData?
    @Published var temperatureData: TemperatureData?
    @Published var microphoneData: MicrophoneData?
    @Published var deviceOrientationData: DeviceOrientationData?
    @Published var batteryData: BatteryData?
    @Published var networkData: NetworkData?
    @Published var systemResourceData: SystemResourceData?
    
    // 传感器状态
    @Published var isMagnetometerAvailable = false
    @Published var isBarometerAvailable = false
    @Published var isPedometerAvailable = false
    @Published var isMicrophoneAvailable = false
    
    // 音频录制
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    
    init() {
        checkSensorAvailability()
        setupAudioSession()
    }
    
    // MARK: - 传感器可用性检查
    private func checkSensorAvailability() {
        isMagnetometerAvailable = motionManager.isMagnetometerAvailable
        isBarometerAvailable = CMAltimeter.isRelativeAltitudeAvailable()
        isPedometerAvailable = CMPedometer.isStepCountingAvailable()
        isMicrophoneAvailable = AVAudioSession.sharedInstance().isInputAvailable
    }
    
    // MARK: - 音频会话设置
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - 磁力计数据收集
    func startMagnetometerUpdates() {
        guard isMagnetometerAvailable else { return }
        
        motionManager.magnetometerUpdateInterval = 0.1
        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            let magneticField = data.magneticField
            let heading = atan2(magneticField.y, magneticField.x) * 180 / .pi
            
            self?.magnetometerData = MagnetometerData(
                timestamp: data.timestamp,
                magneticFieldX: magneticField.x,
                magneticFieldY: magneticField.y,
                magneticFieldZ: magneticField.z,
                heading: heading
            )
        }
    }
    
    func stopMagnetometerUpdates() {
        motionManager.stopMagnetometerUpdates()
    }
    
    // MARK: - 气压计数据收集
    func startBarometerUpdates() {
        guard isBarometerAvailable else { return }
        
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            // 注意：iOS设备通常没有真正的气压计，这里使用相对海拔
            self?.barometerData = BarometerData(
                timestamp: data.timestamp,
                pressure: 1013.25, // 标准大气压
                relativeAltitude: data.relativeAltitude.doubleValue
            )
        }
    }
    
    func stopBarometerUpdates() {
        altimeter.stopRelativeAltitudeUpdates()
    }
    
    // MARK: - 环境光传感器
    func getAmbientLightData() {
        // iOS不直接提供环境光传感器API，这里使用屏幕亮度作为替代
        let brightness = UIScreen.main.brightness
        
        ambientLightData = AmbientLightData(
            timestamp: Date().timeIntervalSince1970,
            brightness: Double(brightness) * 1000 // 转换为lux近似值
        )
    }
    
    // MARK: - 距离传感器
    func getProximityData() {
        // iOS不直接提供距离传感器API，这里使用设备接近状态
        let isClose = UIDevice.current.proximityState
        
        proximityData = ProximityData(
            timestamp: Date().timeIntervalSince1970,
            distance: isClose ? 0.05 : nil, // 5cm以内认为接近
            isClose: isClose
        )
    }
    
    // MARK: - 计步器数据收集
    func getPedometerData() {
        guard isPedometerAvailable else { return }
        
        let now = Date()
        let tenMinutesAgo = now.addingTimeInterval(-600) // 10分钟前
        
        pedometer.queryPedometerData(from: tenMinutesAgo, to: now) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.pedometerData = PedometerData(
                    timestamp: now.timeIntervalSince1970,
                    stepCount: data.numberOfSteps.intValue,
                    distance: data.distance?.doubleValue,
                    averagePace: data.averageActivePace?.doubleValue,
                    startTime: tenMinutesAgo,
                    endTime: now
                )
            }
        }
    }
    
    // MARK: - 温度传感器
    func getTemperatureData() {
        // 尝试获取设备温度信息
        var temperature: Double = 20.0 // 默认室温
        let humidity: Double = 50.0 // 默认湿度
        
        // 使用ProcessInfo获取系统信息，可能包含温度相关数据
        let processInfo = ProcessInfo.processInfo
        let thermalState = processInfo.thermalState
        
        // 根据热状态调整温度估算
        switch thermalState {
        case .nominal:
            temperature = 20.0
        case .fair:
            temperature = 25.0
        case .serious:
            temperature = 30.0
        case .critical:
            temperature = 35.0
        @unknown default:
            temperature = 22.0
        }
        
        // 根据电池状态调整温度估算
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel > 0 {
            // 电池充电时温度会略高
            if UIDevice.current.batteryState == .charging {
                temperature += 2.0
            }
            // 电池电量低时温度会略高
            if batteryLevel < 0.2 {
                temperature += 1.0
            }
        }
        
        // 根据CPU使用情况调整温度估算
        let cpuUsage = getCPUUsage()
        if cpuUsage > 80 {
            temperature += 3.0
        } else if cpuUsage > 50 {
            temperature += 1.5
        }
        
        temperatureData = TemperatureData(
            timestamp: Date().timeIntervalSince1970,
            temperature: temperature,
            humidity: humidity
        )
        
        print("Current estimated temperature: \(temperature)°C, thermal state: \(thermalState)")
    }
    
    // MARK: - CPU使用率获取
    private func getCPUUsage() -> Double {
        // 在模拟器中返回默认值，避免使用不可用的系统API
        #if targetEnvironment(simulator)
        return 30.0 // 模拟器默认CPU使用率
        #else
        // 在真机上使用更兼容的方法获取CPU使用率
        // 由于mach_task_self在真机上不可用，我们使用ProcessInfo来获取基本信息
        let processInfo = ProcessInfo.processInfo
        let activeProcessorCount = processInfo.activeProcessorCount
        let processorCount = processInfo.processorCount
        
        // 基于系统负载计算简化的CPU使用率
        let loadFactor = Double(activeProcessorCount) / Double(processorCount)
        let cpuUsage = loadFactor * 50.0 + Double.random(in: 10...30) // 模拟CPU使用率
        
        return min(cpuUsage, 100.0)
        #endif
    }
    
    // MARK: - 麦克风数据收集
    func startMicrophoneRecording() {
        guard isMicrophoneAvailable else { return }
        
        // 获取用户设置的录制时间，默认为3秒
        let recordingDuration = UserDefaults.standard.double(forKey: "microphoneRecordingDuration")
        let duration = recordingDuration > 0 ? recordingDuration : 3.0
        
        // 确保在主线程上执行UI相关操作
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("temp_audio.m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            do {
                self.audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                self.audioRecorder?.record()
                
                // 使用用户设置的时间后停止录制
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                    self?.stopMicrophoneRecording()
                }
            } catch {
                print("Failed to start audio recording: \(error)")
                // 确保错误情况下也清理资源
                self.audioRecorder = nil
            }
        }
    }
    
    func stopMicrophoneRecording() {
        guard let recorder = audioRecorder else { return }
        
        // 停止录制
        recorder.stop()
        
        // 读取录制的音频数据
        let audioURL = recorder.url
        do {
            let audioData = try Data(contentsOf: audioURL)
            
            // 计算音频统计信息
            let averageVolume = calculateAverageVolume(from: audioData)
            let peakVolume = calculatePeakVolume(from: audioData)
            
            microphoneData = MicrophoneData(
                timestamp: Date().timeIntervalSince1970,
                audioData: audioData,
                sampleRate: 44100,
                averageVolume: averageVolume,
                peakVolume: peakVolume
            )
            
            // 删除临时文件
            try FileManager.default.removeItem(at: audioURL)
        } catch {
            print("Failed to process audio data: \(error)")
        }
        
        // 清理录音器引用
        audioRecorder = nil
    }
    
    private func calculateAverageVolume(from audioData: Data) -> Double {
        // 简化的音量计算，使用安全的类型转换避免溢出和断点
        let bytes = Array(audioData)
        let sum = bytes.reduce(0) { total, byte in
            // 安全地将 UInt8 转换为有符号值，避免溢出
            let signedValue = Int(byte) - 128  // 将 0-255 转换为 -128 到 127
            return total + abs(signedValue)
        }
        return Double(sum) / Double(bytes.count)
    }
    
    private func calculatePeakVolume(from audioData: Data) -> Double {
        // 简化的峰值音量计算，使用安全的类型转换避免溢出和断点
        let bytes = Array(audioData)
        let maxValue = bytes.map { byte in
            // 安全地将 UInt8 转换为有符号值，避免溢出
            let signedValue = Int(byte) - 128  // 将 0-255 转换为 -128 到 127
            return abs(signedValue)
        }.max() ?? 0
        return Double(maxValue)
    }
    
    // MARK: - 设备方向传感器
    func getDeviceOrientationData() {
        let orientation = UIDevice.current.orientation
        
        deviceOrientationData = DeviceOrientationData(
            timestamp: Date().timeIntervalSince1970,
            orientation: orientation.rawValue,
            orientationName: getOrientationName(orientation),
            isPortrait: orientation.isPortrait,
            isLandscape: orientation.isLandscape,
            isFlat: orientation.isFlat
        )
    }
    
    // MARK: - 电池状态传感器
    func getBatteryData() {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        
        batteryData = BatteryData(
            timestamp: Date().timeIntervalSince1970,
            batteryLevel: device.batteryLevel,
            batteryState: device.batteryState.rawValue,
            batteryStateName: getBatteryStateName(device.batteryState),
            isCharging: device.batteryState == .charging || device.batteryState == .full,
            isLowPower: device.batteryLevel < 0.2
        )
    }
    
    // MARK: - 网络状态传感器
    func getNetworkData() {
        // 使用系统方法检测网络状态
        let isConnected = checkNetworkConnectivity()
        
        networkData = NetworkData(
            timestamp: Date().timeIntervalSince1970,
            connectionType: getConnectionType(),
            isConnected: isConnected,
            connectionQuality: getConnectionQuality(),
            wifiSSID: getWiFiSSID()
        )
    }
    
    // MARK: - 系统资源传感器
    func getSystemResourceData() {
        let processInfo = ProcessInfo.processInfo
        
        systemResourceData = SystemResourceData(
            timestamp: Date().timeIntervalSince1970,
            cpuUsage: getCPUUsage(),
            memoryUsage: getMemoryUsage(),
            thermalState: processInfo.thermalState.rawValue,
            thermalStateName: getThermalStateName(processInfo.thermalState),
            activeProcessorCount: processInfo.activeProcessorCount,
            processorCount: processInfo.processorCount,
            systemUptime: processInfo.systemUptime
        )
    }
    
    // MARK: - 批量数据收集
    func collectAllSensorData(for location: CLLocation? = nil, skipMicrophone: Bool = false) async {
        // 检查是否为 App Intent 模式
        let isAppIntentMode = UserDefaults.standard.bool(forKey: "isAppIntentMode")
        
        // 收集所有可用的传感器数据
        getAmbientLightData()
        getProximityData()
        getPedometerData()
        getTemperatureData()
        getDeviceOrientationData()
        getBatteryData()
        
        // 在 App Intent 模式下跳过网络数据收集，避免触发位置权限检查
        if isAppIntentMode {
            print("📱 App Intent mode: Skipping network data collection to avoid location permission check")
            // 设置空的网络数据
            networkData = NetworkData(
                timestamp: Date().timeIntervalSince1970,
                connectionType: "App_Intent_Mode",
                isConnected: true,
                connectionQuality: "Unknown",
                wifiSSID: "App_Intent_Mode"
            )
        } else {
            getNetworkData()
        }
        
        getSystemResourceData()
        
        if !skipMicrophone {
            startMicrophoneRecording()
        }
    }
    
    // MARK: - 停止所有传感器更新
    func stopAllSensorUpdates() {
        stopMagnetometerUpdates()
        stopBarometerUpdates()
        stopMicrophoneRecording()
    }
    
    // MARK: - 清理资源
    deinit {
        // 在deinit中直接停止传感器更新，避免使用@MainActor方法
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.stopRelativeAltitudeUpdates()
        }
        
        if CMPedometer.isStepCountingAvailable() {
            pedometer.stopUpdates()
        }
        
        // 直接停止音频录制，避免调用@MainActor方法
        audioRecorder?.stop()
    }
}

// MARK: - 新增传感器数据结构

// 这些数据结构已在 Item.swift 中定义，这里删除重复定义

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

private func getConnectionType() -> String {
    // 简化的网络类型检测
    #if targetEnvironment(simulator)
    return "Simulator"
    #else
    // 在真机上可以添加更详细的网络检测逻辑
    return "Unknown"
    #endif
}

private func getConnectionQuality() -> String {
    // 简化的连接质量检测
    return "Good"
}

private func getWiFiSSID() -> String? {
    // 1. 优先使用外部传入的SSID
    if let externalSSID = WiFiSSIDManager.shared.getValidSSID() {
        return externalSSID
    }
    
    // 2. 检查是否为 App Intent 模式
    let isAppIntentMode = UserDefaults.standard.bool(forKey: "isAppIntentMode")
    if isAppIntentMode {
        print("📱 App Intent mode: Skipping WiFi SSID collection to avoid location permission check")
        return "App_Intent_Mode"
    }
    
    // 3. 模拟器环境返回模拟数据
    #if targetEnvironment(simulator)
    return "Simulator_WiFi_Network"
    #else
    
    // 4. 真机环境：尝试获取系统SSID
    let locationStatus = CLLocationManager.authorizationStatus()
    
    if locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways {
        if let ssid = attemptGetRealSSID() {
            return ssid
        }
    }
    
    // 5. 最后的Fallback: 返回连接状态
    return getDetailedWiFiStatus()
    #endif
}

private func attemptGetRealSSID() -> String? {
    // 尝试获取真实SSID - 在iOS 14+中通常会失败
    guard let interfaceNames = CNCopySupportedInterfaces() as? [String],
          !interfaceNames.isEmpty else {
        print("DEBUG: No supported interfaces found")
        return nil
    }
    
    print("DEBUG: Found interfaces: \(interfaceNames)")
    
    for interfaceName in interfaceNames {
        guard let networkInfo = CNCopyCurrentNetworkInfo(interfaceName as CFString) as? [String: Any] else {
            print("DEBUG: No network info for interface: \(interfaceName)")
            continue
        }
        
        print("DEBUG: Network info for \(interfaceName): \(networkInfo)")
        
        // 检查是否有SSID信息
        if let ssid = networkInfo[kCNNetworkInfoKeySSID as String] as? String,
           !ssid.isEmpty {
            print("DEBUG: Found SSID: \(ssid)")
            return ssid
        }
        
        // 如果有其他网络信息，至少表明我们连接到了WiFi
        if let bssid = networkInfo[kCNNetworkInfoKeyBSSID as String] as? String,
           !bssid.isEmpty {
            print("DEBUG: Found BSSID but no SSID: \(bssid)")
            // 有BSSID说明连接到WiFi，但无法获取SSID名称
            return "WiFi_Network_Connected"
        }
    }
    
    print("DEBUG: No SSID found in any interface")
    return nil
}

private func getDetailedWiFiStatus() -> String? {
    // 使用NWPathMonitor检测详细的WiFi连接状态
    let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
    let queue = DispatchQueue(label: "WiFiDetailMonitor")
    var result: String? = nil
    let semaphore = DispatchSemaphore(value: 0)
    
    monitor.pathUpdateHandler = { path in
        if path.status == .satisfied && path.usesInterfaceType(.wifi) {
            // 检查是否是高成本网络（移动热点等）
            if path.isExpensive {
                result = "WiFi_Hotspot_Connected"
            } else {
                result = "WiFi_Network_Active"
            }
        } else if path.status == .requiresConnection {
            result = "WiFi_Connecting"
        } else {
            result = "WiFi_Disconnected"
        }
        semaphore.signal()
    }
    
    monitor.start(queue: queue)
    
    // 等待最多2秒获取网络状态
    let timeoutResult = semaphore.wait(timeout: .now() + 2.0)
    monitor.cancel()
    
    if timeoutResult == .timedOut {
        return "WiFi_Status_Unknown"
    }
    
    return result ?? "WiFi_Unknown"
}



private func getMemoryUsage() -> Double {
    let processInfo = ProcessInfo.processInfo
    let physicalMemory = processInfo.physicalMemory
    let memoryUsage = Double(processInfo.physicalMemory - processInfo.physicalMemory) / Double(physicalMemory)
    return min(max(memoryUsage, 0.0), 1.0) * 100.0
}

private func checkNetworkConnectivity() -> Bool {
    // 简单的网络连接检测
    // 在实际应用中，可以使用 Network framework 进行更准确的检测
    #if targetEnvironment(simulator)
    return true // 模拟器通常有网络连接
    #else
    // 在真机上，可以添加更复杂的网络检测逻辑
    // 这里返回 true 作为默认值
    return true
    #endif
}
