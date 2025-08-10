//
//  Item.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

@Model
final class NFCSessionData {
    var timestamp: Date
    var latitude: Double?
    var longitude: Double?
    var ipAddress: String?
    var wifiSSID: String? // WiFi网络名称
    var currentAppName: String?
    var imuData: Data? // Serialized IMU data for 5 seconds
    var nfcTagData: String? // NFC tag content (if available)
    var screenState: String? // Screen state: "on" or "off"
    var screenBrightness: Double? // Screen brightness (0.0 - 1.0)
    
    // 新增NFC使用信息
    var nfcUsageType: String? // NFC使用类型：支付、交通、门禁等
    var nfcTriggerSource: String? // NFC触发来源：快捷指令、手动、自动检测等
    var nfcSessionDuration: TimeInterval? // NFC会话持续时间
    
    // 屏幕状态历史信息
    var screenStateHistory: Data? // 序列化的屏幕状态历史数据
    
    // 宏观地点信息
    var street: String?
    var city: String?
    var state: String?
    var country: String?
    var postalCode: String?
    var administrativeArea: String?
    var subLocality: String?
    
    // 新增传感器数据
    var magnetometerData: Data? // 磁力计数据 (3轴磁场强度)
    var barometerData: Data? // 气压计数据 (气压值)
    var ambientLightData: Data? // 环境光传感器数据 (亮度值)
    var proximityData: Data? // 距离传感器数据 (距离值)
    var pedometerData: Data? // 计步器数据 (最近10分钟步数)
    var temperatureData: Data? // 温度传感器数据 (温度值)
    var microphoneData: Data? // 麦克风数据 (3秒环境音频)
    var weatherData: Data? // 天气数据 (当前天气信息)
    
    // 新增标签功能
    var locationTag: String? // 地点标签，用于标识NFC发生的位置
    
    init(timestamp: Date = Date(), 
         latitude: Double? = nil, 
         longitude: Double? = nil, 
         ipAddress: String? = nil, 
         wifiSSID: String? = nil,
         currentAppName: String? = nil, 
         imuData: Data? = nil,
         nfcTagData: String? = nil,
         screenState: String? = nil,
         screenBrightness: Double? = nil,
         nfcUsageType: String? = nil,
         nfcTriggerSource: String? = nil,
         nfcSessionDuration: TimeInterval? = nil,
         screenStateHistory: Data? = nil,
         street: String? = nil,
         city: String? = nil,
         state: String? = nil,
         country: String? = nil,
         postalCode: String? = nil,
         administrativeArea: String? = nil,
         subLocality: String? = nil,
         magnetometerData: Data? = nil,
         barometerData: Data? = nil,
         ambientLightData: Data? = nil,
         proximityData: Data? = nil,
         pedometerData: Data? = nil,
         temperatureData: Data? = nil,
         microphoneData: Data? = nil,
         weatherData: Data? = nil,
         locationTag: String? = nil) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.ipAddress = ipAddress
        self.wifiSSID = wifiSSID
        self.currentAppName = currentAppName
        self.imuData = imuData
        self.nfcTagData = nfcTagData
        self.screenState = screenState
        self.screenBrightness = screenBrightness
        self.nfcUsageType = nfcUsageType
        self.nfcTriggerSource = nfcTriggerSource
        self.nfcSessionDuration = nfcSessionDuration
        self.screenStateHistory = screenStateHistory
        self.street = street
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode
        self.administrativeArea = administrativeArea
        self.subLocality = subLocality
        self.magnetometerData = magnetometerData
        self.barometerData = barometerData
        self.ambientLightData = ambientLightData
        self.proximityData = proximityData
        self.pedometerData = pedometerData
        self.temperatureData = temperatureData
        self.microphoneData = microphoneData
        self.weatherData = weatherData
        self.locationTag = locationTag
    }
    
    var locationString: String {
        if let lat = latitude, let lon = longitude {
            var locationParts: [String] = []
            
            // 添加街道信息
            if let street = street, !street.isEmpty {
                locationParts.append(street)
            }
            
            // 添加城市信息
            if let city = city, !city.isEmpty {
                locationParts.append(city)
            }
            
            // 添加州/省信息
            if let state = state, !state.isEmpty {
                locationParts.append(state)
            }
            
            // 添加国家信息
            if let country = country, !country.isEmpty {
                locationParts.append(country)
            }
            
            // 如果有宏观地点信息，显示地点信息；否则显示坐标
            if !locationParts.isEmpty {
                return locationParts.joined(separator: ", ")
            } else {
                return "\(lat), \(lon)"
            }
        }
        return "Location not available"
    }
    
    // 获取完整的宏观地点信息字符串
    var detailedLocationString: String {
        var parts: [String] = []
        
        if let street = street, !street.isEmpty {
            parts.append("Street: \(street)")
        }
        if let city = city, !city.isEmpty {
            parts.append("City: \(city)")
        }
        if let state = state, !state.isEmpty {
            parts.append("State: \(state)")
        }
        if let country = country, !country.isEmpty {
            parts.append("Country: \(country)")
        }
        if let postalCode = postalCode, !postalCode.isEmpty {
            parts.append("Postal Code: \(postalCode)")
        }
        if let administrativeArea = administrativeArea, !administrativeArea.isEmpty {
            parts.append("Administrative Area: \(administrativeArea)")
        }
        if let subLocality = subLocality, !subLocality.isEmpty {
            parts.append("Sub-locality: \(subLocality)")
        }
        
        if parts.isEmpty {
            return "No detailed location information available"
        }
        
        return parts.joined(separator: "\n")
    }
}

// Structure for IMU data points
struct IMUDataPoint: Codable {
    let timestamp: TimeInterval
    let accelerationX: Double
    let accelerationY: Double
    let accelerationZ: Double
    let rotationRateX: Double
    let rotationRateY: Double
    let rotationRateZ: Double
}

// Container for 5 seconds of IMU data
struct IMUSession: Codable {
    let dataPoints: [IMUDataPoint]
    let startTime: Date
    let endTime: Date
}

// 新增传感器数据结构

// 磁力计数据结构
struct MagnetometerData: Codable {
    let timestamp: TimeInterval
    let magneticFieldX: Double // X轴磁场强度 (μT)
    let magneticFieldY: Double // Y轴磁场强度 (μT)
    let magneticFieldZ: Double // Z轴磁场强度 (μT)
    let heading: Double // 磁航向 (度)
}

// 气压计数据结构
struct BarometerData: Codable {
    let timestamp: TimeInterval
    let pressure: Double // 气压值 (hPa)
    let relativeAltitude: Double? // 相对海拔 (米)
}

// 环境光传感器数据结构
struct AmbientLightData: Codable {
    let timestamp: TimeInterval
    let brightness: Double // 亮度值 (lux)
}

// 距离传感器数据结构
struct ProximityData: Codable {
    let timestamp: TimeInterval
    let distance: Double? // 距离值 (米)，nil表示无法检测
    let isClose: Bool // 是否接近物体
}

// 计步器数据结构
struct PedometerData: Codable {
    let timestamp: TimeInterval
    let stepCount: Int // 步数
    let distance: Double? // 距离 (米)
    let averagePace: Double? // 平均步频 (步/分钟)
    let startTime: Date // 开始时间
    let endTime: Date // 结束时间
}

// 温度传感器数据结构
struct TemperatureData: Codable {
    let timestamp: TimeInterval
    let temperature: Double // 温度值 (摄氏度)
    let humidity: Double? // 湿度值 (百分比)
}

// 麦克风数据结构
struct MicrophoneData: Codable {
    let timestamp: TimeInterval
    let audioData: Data // 音频数据 (3秒)
    let sampleRate: Double // 采样率 (Hz)
    let averageVolume: Double // 平均音量 (dB)
    let peakVolume: Double // 峰值音量 (dB)
}

// 天气数据结构
struct WeatherData: Codable {
    let timestamp: TimeInterval
    let temperature: Double // 当前温度 (摄氏度)
    let humidity: Double // 湿度 (百分比)
    let pressure: Double // 气压 (hPa)
    let windSpeed: Double? // 风速 (m/s)
    let windDirection: Double? // 风向 (度)
    let description: String // 天气描述
    let icon: String? // 天气图标代码
}

// 新增传感器数据结构

// 设备方向数据结构
struct DeviceOrientationData: Codable {
    let timestamp: TimeInterval
    let orientation: Int // 设备方向枚举值
    let orientationName: String // 方向名称
    let isPortrait: Bool // 是否竖屏
    let isLandscape: Bool // 是否横屏
    let isFlat: Bool // 是否平放
}

// 电池状态数据结构
struct BatteryData: Codable {
    let timestamp: TimeInterval
    let batteryLevel: Float // 电池电量 (0.0 - 1.0)
    let batteryState: Int // 电池状态枚举值
    let batteryStateName: String // 电池状态名称
    let isCharging: Bool // 是否正在充电
    let isLowPower: Bool // 是否低电量
}

// 网络状态数据结构
struct NetworkData: Codable {
    let timestamp: TimeInterval
    let connectionType: String // 连接类型
    let isConnected: Bool // 是否已连接
    let connectionQuality: String // 连接质量
    let wifiSSID: String? // WiFi SSID (如果可用)
}

// 系统资源数据结构
struct SystemResourceData: Codable {
    let timestamp: TimeInterval
    let cpuUsage: Double // CPU使用率 (百分比)
    let memoryUsage: Double // 内存使用率 (百分比)
    let thermalState: Int // 热状态枚举值
    let thermalStateName: String // 热状态名称
    let activeProcessorCount: Int // 活跃处理器数量
    let processorCount: Int // 总处理器数量
    let systemUptime: TimeInterval // 系统运行时间 (秒)
}
