//
//  DataExportManager.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import Foundation
import SwiftUI

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    case csvPrivacy = "CSV (No Location)"
    case jsonPrivacy = "JSON (No Location)"
    case audioSamples = "Audio Samples"
    
    var fileExtension: String {
        switch self {
        case .csv, .csvPrivacy: return "csv"
        case .json, .jsonPrivacy: return "json"
        case .audioSamples: return "zip"
        }
    }
    
    var mimeType: String {
        switch self {
        case .csv, .csvPrivacy: return "text/csv"
        case .json, .jsonPrivacy: return "application/json"
        case .audioSamples: return "application/zip"
        }
    }
    
    var includesLocation: Bool {
        switch self {
        case .csv, .json: return true
        case .csvPrivacy, .jsonPrivacy: return false
        case .audioSamples: return false
        }
    }
    
    var description: String {
        switch self {
        case .csv:
            return "CSV format with all data including location"
        case .json:
            return "JSON format with all data including location"
        case .csvPrivacy:
            return "CSV format without location data"
        case .jsonPrivacy:
            return "JSON format without location data"
        case .audioSamples:
            return "ZIP file containing audio samples and metadata"
        }
    }
}

enum DataTypeFilter: String, CaseIterable {
    case allData = "All Data"
    case nfcData = "NFC Data"
    case locationData = "Location Data"
    case sensorData = "Sensor Data"
    case screenStateData = "Screen State Data"
    
    var description: String {
        switch self {
        case .allData:
            return "Export all available data"
        case .nfcData:
            return "Export only sessions with NFC data"
        case .locationData:
            return "Export only sessions with location data"
        case .sensorData:
            return "Export only sessions with sensor data"
        case .screenStateData:
            return "Export only sessions with screen state history"
        }
    }
}

class DataExportManager: ObservableObject {
    
    func exportData(_ sessions: [NFCSessionData], format: ExportFormat) -> URL? {
        let fileName = "CardPilot_Export_\(DateFormatter.fileNameFormatter.string(from: Date())).\(format.fileExtension)"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            let exportData: Data
            
            switch format {
            case .csv:
                exportData = try generateCSV(from: sessions, includeLocation: true)
            case .json:
                exportData = try generateJSON(from: sessions, includeLocation: true)
            case .csvPrivacy:
                exportData = try generateCSV(from: sessions, includeLocation: false)
            case .jsonPrivacy:
                exportData = try generateJSON(from: sessions, includeLocation: false)
            case .audioSamples:
                exportData = try generateAudioSamplesExport(from: sessions)
            }
            
            try exportData.write(to: fileURL)
            return fileURL
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }
    
    private func generateCSV(from sessions: [NFCSessionData], includeLocation: Bool = true) throws -> Data {
        var csvContent: String
        
        if includeLocation {
            csvContent = "Timestamp,Address,Location,IP Address,App Name,NFC,Location Tag,Screen State,Screen Brightness,Screen State History Count,IMU Data Points,IMU Data Details,Magnetometer Status,Magnetometer X (μT),Magnetometer Y (μT),Magnetometer Z (μT),Magnetometer Heading (deg),Barometer Status,Barometer Pressure (hPa),Barometer Altitude (m),Ambient Light Status,Ambient Light (lux),Proximity Status,Proximity Distance (m),Proximity Is Close,Pedometer Status,Pedometer Steps,Pedometer Distance (m),Pedometer Pace (steps/min),Temperature Status,Temperature (°C),Temperature Humidity (%),Microphone Status,Microphone Sample Rate (Hz),Microphone Avg Volume (dB),Microphone Peak Volume (dB),Audio File Size (bytes),Device Orientation Status,Device Orientation,Device Orientation Name,Device Is Portrait,Device Is Landscape,Device Is Flat,Battery Status,Battery Level (%),Battery State,Battery State Name,Battery Is Charging,Battery Is Low Power,Network Status,Network Connection Type,Network Is Connected,Network Connection Quality,Network WiFi SSID,System Resource Status,CPU Usage (%),Memory Usage (%),Thermal State,Thermal State Name,Active Processors,Total Processors,System Uptime (s),Weather Status,Data Quality Score\n"
        } else {
            csvContent = "Timestamp,IP Address,App Name,NFC,Location Tag,Screen State,Screen Brightness,Screen State History Count,IMU Data Points,IMU Data Details,Magnetometer Status,Magnetometer X (μT),Magnetometer Y (μT),Magnetometer Z (μT),Magnetometer Heading (deg),Barometer Status,Barometer Pressure (hPa),Barometer Altitude (m),Ambient Light Status,Ambient Light (lux),Proximity Status,Proximity Distance (m),Proximity Is Close,Pedometer Status,Pedometer Steps,Pedometer Distance (m),Pedometer Pace (steps/min),Temperature Status,Temperature (°C),Temperature Humidity (%),Microphone Status,Microphone Sample Rate (Hz),Microphone Avg Volume (dB),Microphone Peak Volume (dB),Audio File Size (bytes),Device Orientation Status,Device Orientation,Device Orientation Name,Device Is Portrait,Device Is Landscape,Device Is Flat,Battery Status,Battery Level (%),Battery State,Battery State Name,Battery Is Charging,Battery Is Low Power,Network Status,Network Connection Type,Network Is Connected,Network Connection Quality,Network WiFi SSID,System Resource Status,CPU Usage (%),Memory Usage (%),Thermal State,Thermal State Name,Active Processors,Total Processors,System Uptime (s),Weather Status,Data Quality Score\n"
        }
        
        for session in sessions {
            let timestamp = DateFormatter.csvFormatter.string(from: session.timestamp)
            let ipAddress = session.ipAddress?.replacingOccurrences(of: ",", with: ";") ?? ""
            let appName = session.currentAppName?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            // NFC相关信息 - 通过buildNFCString函数处理
            
            // 屏幕状态信息
            let screenState = session.screenState?.replacingOccurrences(of: ",", with: ";") ?? ""
            let screenBrightness = session.screenBrightness?.description ?? ""
            
            // 屏幕状态历史计数
            var screenStateHistoryCount = "0"
            if let screenStateHistoryData = session.screenStateHistory {
                if let screenStateHistory = try? JSONDecoder().decode([ScreenStateEvent].self, from: screenStateHistoryData) {
                    screenStateHistoryCount = "\(screenStateHistory.count)"
                }
            }
            
            // Count IMU data points and details
            var imuPointsCount = "0"
            var imuDataDetails = ""
            if let imuData = session.imuData {
                do {
                    let imuSession = try JSONDecoder().decode(IMUSession.self, from: imuData)
                    imuPointsCount = "\(imuSession.dataPoints.count)"
                    
                    // 计算IMU统计信息
                    if !imuSession.dataPoints.isEmpty {
                        let accelerations = imuSession.dataPoints.map { sqrt($0.accelerationX*$0.accelerationX + $0.accelerationY*$0.accelerationY + $0.accelerationZ*$0.accelerationZ) }
                        let rotations = imuSession.dataPoints.map { sqrt($0.rotationRateX*$0.rotationRateX + $0.rotationRateY*$0.rotationRateY + $0.rotationRateZ*$0.rotationRateZ) }
                        
                        let avgAccel = accelerations.reduce(0, +) / Double(accelerations.count)
                        let avgRotation = rotations.reduce(0, +) / Double(rotations.count)
                        let maxAccel = accelerations.max() ?? 0
                        let maxRotation = rotations.max() ?? 0
                        
                        imuDataDetails = "Accel:\(String(format: "%.2f", avgAccel))g Max:\(String(format: "%.2f", maxAccel))g Rot:\(String(format: "%.2f", avgRotation))°/s Max:\(String(format: "%.2f", maxRotation))°/s"
                    }
                } catch {
                    imuPointsCount = "Error"
                    imuDataDetails = "Decode Error"
                }
            }
            
            // 详细的传感器数据
            let magnetometerStatus = session.magnetometerData != nil ? "Available" : "N/A"
            var magnetometerX = "", magnetometerY = "", magnetometerZ = "", magnetometerHeading = ""
            if let magnetometerData = session.magnetometerData {
                if let magnetometer = try? JSONDecoder().decode(MagnetometerData.self, from: magnetometerData) {
                    magnetometerX = String(format: "%.2f", magnetometer.magneticFieldX)
                    magnetometerY = String(format: "%.2f", magnetometer.magneticFieldY)
                    magnetometerZ = String(format: "%.2f", magnetometer.magneticFieldZ)
                    magnetometerHeading = String(format: "%.1f", magnetometer.heading)
                }
            }
            
            let barometerStatus = session.barometerData != nil ? "Available" : "N/A"
            var barometerPressure = "", barometerAltitude = ""
            if let barometerData = session.barometerData {
                if let barometer = try? JSONDecoder().decode(BarometerData.self, from: barometerData) {
                    barometerPressure = String(format: "%.1f", barometer.pressure)
                    barometerAltitude = barometer.relativeAltitude != nil ? String(format: "%.1f", barometer.relativeAltitude!) : "N/A"
                }
            }
            
            let ambientLightStatus = session.ambientLightData != nil ? "Available" : "N/A"
            var ambientLightValue = ""
            if let ambientLightData = session.ambientLightData {
                if let ambientLight = try? JSONDecoder().decode(AmbientLightData.self, from: ambientLightData) {
                    ambientLightValue = String(format: "%.1f", ambientLight.brightness)
                }
            }
            
            let proximityStatus = session.proximityData != nil ? "Available" : "N/A"
            var proximityDistance = "", proximityIsClose = ""
            if let proximityData = session.proximityData {
                if let proximity = try? JSONDecoder().decode(ProximityData.self, from: proximityData) {
                    proximityDistance = proximity.distance != nil ? String(format: "%.3f", proximity.distance!) : "N/A"
                    proximityIsClose = proximity.isClose ? "Yes" : "No"
                }
            }
            
            let pedometerStatus = session.pedometerData != nil ? "Available" : "N/A"
            var pedometerSteps = "", pedometerDistance = "", pedometerPace = ""
            if let pedometerData = session.pedometerData {
                if let pedometer = try? JSONDecoder().decode(PedometerData.self, from: pedometerData) {
                    pedometerSteps = "\(pedometer.stepCount)"
                    pedometerDistance = pedometer.distance != nil ? String(format: "%.1f", pedometer.distance!) : "N/A"
                    pedometerPace = pedometer.averagePace != nil ? String(format: "%.1f", pedometer.averagePace!) : "N/A"
                }
            }
            
            let temperatureStatus = session.temperatureData != nil ? "Available" : "N/A"
            var temperatureValue = "", temperatureHumidity = ""
            if let temperatureData = session.temperatureData {
                if let temperature = try? JSONDecoder().decode(TemperatureData.self, from: temperatureData) {
                    temperatureValue = String(format: "%.1f", temperature.temperature)
                    temperatureHumidity = temperature.humidity != nil ? String(format: "%.1f", temperature.humidity!) : "N/A"
                }
            }
            
            let microphoneStatus = session.microphoneData != nil ? "Available" : "N/A"
            var microphoneSampleRate = "", microphoneAvgVolume = "", microphonePeakVolume = "", audioFileSize = ""
            if let microphoneData = session.microphoneData {
                if let microphone = try? JSONDecoder().decode(MicrophoneData.self, from: microphoneData) {
                    microphoneSampleRate = String(format: "%.0f", microphone.sampleRate)
                    microphoneAvgVolume = String(format: "%.1f", microphone.averageVolume)
                    microphonePeakVolume = String(format: "%.1f", microphone.peakVolume)
                    audioFileSize = "\(microphone.audioData.count)"
                }
            }
            
            let weatherStatus = session.weatherData != nil ? "Available" : "N/A"
            
            // 计算数据质量分数
            let dataQualityScore = calculateDataQualityScore(
                hasIMU: session.imuData != nil,
                hasMagnetometer: session.magnetometerData != nil,
                hasBarometer: session.barometerData != nil,
                hasAmbientLight: session.ambientLightData != nil,
                hasProximity: session.proximityData != nil,
                hasPedometer: session.pedometerData != nil,
                hasTemperature: session.temperatureData != nil,
                hasMicrophone: session.microphoneData != nil,
                hasWeather: session.weatherData != nil,
                hasScreenState: session.screenStateHistory != nil
            )
            
            // 合并地址字段
            let address = buildAddressString(
                street: session.street,
                city: session.city,
                state: session.state,
                country: session.country,
                postalCode: session.postalCode,
                administrativeArea: session.administrativeArea,
                subLocality: session.subLocality
            )
            
            // 合并位置字段（经纬度）
            let location = buildLocationString(
                latitude: session.latitude,
                longitude: session.longitude
            )
            
            // 合并NFC字段
            let nfc = buildNFCString(
                nfcTagData: session.nfcTagData,
                nfcUsageType: session.nfcUsageType,
                nfcTriggerSource: session.nfcTriggerSource,
                nfcSessionDuration: session.nfcSessionDuration
            )
            
            // 获取标签信息
            let locationTag = session.locationTag?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            if includeLocation {
                csvContent += "\"\(timestamp)\",\"\(address)\",\"\(location)\",\"\(ipAddress)\",\"\(appName)\",\"\(nfc)\",\"\(locationTag)\",\"\(screenState)\",\"\(screenBrightness)\",\"\(screenStateHistoryCount)\",\"\(imuPointsCount)\",\"\(imuDataDetails)\",\"\(magnetometerStatus)\",\"\(magnetometerX)\",\"\(magnetometerY)\",\"\(magnetometerZ)\",\"\(magnetometerHeading)\",\"\(barometerStatus)\",\"\(barometerPressure)\",\"\(barometerAltitude)\",\"\(ambientLightStatus)\",\"\(ambientLightValue)\",\"\(proximityStatus)\",\"\(proximityDistance)\",\"\(proximityIsClose)\",\"\(pedometerStatus)\",\"\(pedometerSteps)\",\"\(pedometerDistance)\",\"\(pedometerPace)\",\"\(temperatureStatus)\",\"\(temperatureValue)\",\"\(temperatureHumidity)\",\"\(microphoneStatus)\",\"\(microphoneSampleRate)\",\"\(microphoneAvgVolume)\",\"\(microphonePeakVolume)\",\"\(audioFileSize)\",\"\(weatherStatus)\",\"\(String(format: "%.2f", dataQualityScore))\"\n"
            } else {
                csvContent += "\"\(timestamp)\",\"\(ipAddress)\",\"\(appName)\",\"\(nfc)\",\"\(locationTag)\",\"\(screenState)\",\"\(screenBrightness)\",\"\(screenStateHistoryCount)\",\"\(imuPointsCount)\",\"\(imuDataDetails)\",\"\(magnetometerStatus)\",\"\(magnetometerX)\",\"\(magnetometerY)\",\"\(magnetometerZ)\",\"\(magnetometerHeading)\",\"\(barometerStatus)\",\"\(barometerPressure)\",\"\(barometerAltitude)\",\"\(ambientLightStatus)\",\"\(ambientLightValue)\",\"\(proximityStatus)\",\"\(proximityDistance)\",\"\(proximityIsClose)\",\"\(pedometerStatus)\",\"\(pedometerSteps)\",\"\(pedometerDistance)\",\"\(pedometerPace)\",\"\(temperatureStatus)\",\"\(temperatureValue)\",\"\(temperatureHumidity)\",\"\(microphoneStatus)\",\"\(microphoneSampleRate)\",\"\(microphoneAvgVolume)\",\"\(microphonePeakVolume)\",\"\(audioFileSize)\",\"\(weatherStatus)\",\"\(String(format: "%.2f", dataQualityScore))\"\n"
            }
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func generateJSON(from sessions: [NFCSessionData], includeLocation: Bool = true) throws -> Data {
        let exportSessions = sessions.map { session -> ExportableSession in
            var decodedIMU: IMUSession?
            if let imuData = session.imuData {
                decodedIMU = try? JSONDecoder().decode(IMUSession.self, from: imuData)
            }
            
            // 解码传感器数据
            var decodedMagnetometer: MagnetometerData?
            var decodedBarometer: BarometerData?
            var decodedAmbientLight: AmbientLightData?
            var decodedProximity: ProximityData?
            var decodedPedometer: PedometerData?
            var decodedTemperature: TemperatureData?
            var decodedMicrophone: MicrophoneData?
            var decodedWeather: WeatherData?
            
            // 解码屏幕状态历史数据
            var decodedScreenStateHistory: [ScreenStateEvent]?
            if let screenStateHistoryData = session.screenStateHistory {
                decodedScreenStateHistory = try? JSONDecoder().decode([ScreenStateEvent].self, from: screenStateHistoryData)
            }
            
            // 解码所有传感器数据
            if let magnetometerData = session.magnetometerData {
                decodedMagnetometer = try? JSONDecoder().decode(MagnetometerData.self, from: magnetometerData)
            }
            if let barometerData = session.barometerData {
                decodedBarometer = try? JSONDecoder().decode(BarometerData.self, from: barometerData)
            }
            if let ambientLightData = session.ambientLightData {
                decodedAmbientLight = try? JSONDecoder().decode(AmbientLightData.self, from: ambientLightData)
            }
            if let proximityData = session.proximityData {
                decodedProximity = try? JSONDecoder().decode(ProximityData.self, from: proximityData)
            }
            if let pedometerData = session.pedometerData {
                decodedPedometer = try? JSONDecoder().decode(PedometerData.self, from: pedometerData)
            }
            if let temperatureData = session.temperatureData {
                decodedTemperature = try? JSONDecoder().decode(TemperatureData.self, from: temperatureData)
            }
            if let microphoneData = session.microphoneData {
                decodedMicrophone = try? JSONDecoder().decode(MicrophoneData.self, from: microphoneData)
            }
            if let weatherData = session.weatherData {
                decodedWeather = try? JSONDecoder().decode(WeatherData.self, from: weatherData)
            }
            
            // 创建传感器数据统计信息
            let sensorDataSummary = SensorDataSummary(
                hasIMUData: decodedIMU != nil,
                imuDataPointsCount: decodedIMU?.dataPoints.count ?? 0,
                hasMagnetometerData: decodedMagnetometer != nil,
                hasBarometerData: decodedBarometer != nil,
                hasAmbientLightData: decodedAmbientLight != nil,
                hasProximityData: decodedProximity != nil,
                hasPedometerData: decodedPedometer != nil,
                hasTemperatureData: decodedTemperature != nil,
                hasMicrophoneData: decodedMicrophone != nil,
                hasWeatherData: decodedWeather != nil,
                hasScreenStateHistory: decodedScreenStateHistory != nil,
                screenStateHistoryCount: decodedScreenStateHistory?.count ?? 0,
                dataQualityScore: calculateDataQualityScore(
                    hasIMU: decodedIMU != nil,
                    hasMagnetometer: decodedMagnetometer != nil,
                    hasBarometer: decodedBarometer != nil,
                    hasAmbientLight: decodedAmbientLight != nil,
                    hasProximity: decodedProximity != nil,
                    hasPedometer: decodedPedometer != nil,
                    hasTemperature: decodedTemperature != nil,
                    hasMicrophone: decodedMicrophone != nil,
                    hasWeather: decodedWeather != nil,
                    hasScreenState: decodedScreenStateHistory != nil
                )
            )
            
            // 创建增强的传感器数据，包含统计信息
            let enhancedMagnetometer = decodedMagnetometer != nil ? EnhancedMagnetometerData(
                data: decodedMagnetometer!,
                magneticFieldMagnitude: sqrt(
                    decodedMagnetometer!.magneticFieldX * decodedMagnetometer!.magneticFieldX +
                    decodedMagnetometer!.magneticFieldY * decodedMagnetometer!.magneticFieldY +
                    decodedMagnetometer!.magneticFieldZ * decodedMagnetometer!.magneticFieldZ
                )
            ) : nil
            
            let enhancedBarometer = decodedBarometer != nil ? EnhancedBarometerData(
                data: decodedBarometer!,
                pressureCategory: getPressureCategory(decodedBarometer!.pressure)
            ) : nil
            
            let enhancedMicrophone = decodedMicrophone != nil ? EnhancedMicrophoneData(
                data: decodedMicrophone!,
                audioDuration: Double(decodedMicrophone!.audioData.count) / decodedMicrophone!.sampleRate,
                volumeCategory: getVolumeCategory(decodedMicrophone!.averageVolume)
            ) : nil
            
            // 创建结构化的位置数据
            let locationData: LocationData? = if includeLocation, let lat = session.latitude, let lon = session.longitude {
                LocationData(latitude: lat, longitude: lon)
            } else {
                nil
            }
            
            // 创建结构化的NFC数据
            let nfcData = NFCData(
                type: session.nfcUsageType,
                source: session.nfcTriggerSource,
                duration: session.nfcSessionDuration,
                tagData: session.nfcTagData
            )
            
            // 创建结构化的屏幕数据
            let screenData: ScreenData? = if session.screenState != nil || session.screenBrightness != nil || decodedScreenStateHistory != nil {
                ScreenData(
                    state: session.screenState,
                    brightness: session.screenBrightness,
                    stateHistory: decodedScreenStateHistory
                )
            } else {
                nil
            }
            
            // 创建结构化的网络数据
            let networkData: ExportNetworkData? = if session.ipAddress != nil || session.wifiSSID != nil {
                ExportNetworkData(
                    ipAddress: session.ipAddress,
                    wifiSSID: session.wifiSSID
                )
            } else {
                nil
            }
            
            return ExportableSession(
                timestamp: session.timestamp,
                address: includeLocation ? buildAddressString(
                    street: session.street,
                    city: session.city,
                    state: session.state,
                    country: session.country,
                    postalCode: session.postalCode,
                    administrativeArea: session.administrativeArea,
                    subLocality: session.subLocality
                ) : nil,
                location: locationData,
                network: networkData,
                currentAppName: session.currentAppName,
                nfc: nfcData,
                locationTag: session.locationTag,
                screen: screenData,
                imuSession: decodedIMU,
                magnetometerData: enhancedMagnetometer,
                barometerData: enhancedBarometer,
                ambientLightData: decodedAmbientLight,
                proximityData: decodedProximity,
                pedometerData: decodedPedometer,
                temperatureData: decodedTemperature,
                microphoneData: enhancedMicrophone,
                weatherData: decodedWeather,
                sensorDataSummary: sensorDataSummary
            )
        }
        
        let exportData = ExportData(
            exportInfo: ExportInfo(
                exportDate: Date(),
                totalSessions: sessions.count,
                includeLocation: includeLocation,
                exportFormat: "JSON",
                dataCompression: false
            ),
            sessions: exportSessions,
            sensorDataReport: generateSensorDataReport(from: sessions)
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    // MARK: - Helper Functions
    
    /// 生成传感器数据统计报告
    func generateSensorDataReport(from sessions: [NFCSessionData]) -> SensorDataReport {
        var report = SensorDataReport()
        
        for session in sessions {
            // 统计IMU数据
            if let imuData = session.imuData {
                if let imuSession = try? JSONDecoder().decode(IMUSession.self, from: imuData) {
                    report.totalIMUDataPoints += imuSession.dataPoints.count
                    report.sessionsWithIMU += 1
                }
            }
            
            // 统计其他传感器数据
            if session.magnetometerData != nil { report.sessionsWithMagnetometer += 1 }
            if session.barometerData != nil { report.sessionsWithBarometer += 1 }
            if session.ambientLightData != nil { report.sessionsWithAmbientLight += 1 }
            if session.proximityData != nil { report.sessionsWithProximity += 1 }
            if session.pedometerData != nil { report.sessionsWithPedometer += 1 }
            if session.temperatureData != nil { report.sessionsWithTemperature += 1 }
            if session.microphoneData != nil { report.sessionsWithMicrophone += 1 }
            if session.weatherData != nil { report.sessionsWithWeather += 1 }
            if session.screenStateHistory != nil { report.sessionsWithScreenStateHistory += 1 }
            
            // 统计位置数据
            if session.latitude != nil && session.longitude != nil {
                report.sessionsWithLocation += 1
            }
            
            // 统计NFC数据
            if session.nfcTagData != nil { report.sessionsWithNFCTag += 1 }
            if session.nfcUsageType != nil { report.sessionsWithNFCUsageType += 1 }
            if session.nfcTriggerSource != nil { report.sessionsWithNFCTriggerSource += 1 }
            if session.nfcSessionDuration != nil { report.sessionsWithNFCDuration += 1 }
            
            // 统计位置标签数据
            if let locationTag = session.locationTag, !locationTag.isEmpty {
                report.sessionsWithLocationTag += 1
                report.totalLocationTags += 1
            }
        }
        
        // 计算唯一标签数量
        var uniqueTags = Set<String>()
        for session in sessions {
            if let locationTag = session.locationTag, !locationTag.isEmpty {
                uniqueTags.insert(locationTag)
            }
        }
        report.uniqueLocationTags = uniqueTags.count
        
        // 计算百分比
        let totalSessions = sessions.count
        if totalSessions > 0 {
            report.imuDataPercentage = Double(report.sessionsWithIMU) / Double(totalSessions)
            report.magnetometerPercentage = Double(report.sessionsWithMagnetometer) / Double(totalSessions)
            report.barometerPercentage = Double(report.sessionsWithBarometer) / Double(totalSessions)
            report.ambientLightPercentage = Double(report.sessionsWithAmbientLight) / Double(totalSessions)
            report.proximityPercentage = Double(report.sessionsWithProximity) / Double(totalSessions)
            report.pedometerPercentage = Double(report.sessionsWithPedometer) / Double(totalSessions)
            report.temperaturePercentage = Double(report.sessionsWithTemperature) / Double(totalSessions)
            report.microphonePercentage = Double(report.sessionsWithMicrophone) / Double(totalSessions)
            report.weatherPercentage = Double(report.sessionsWithWeather) / Double(totalSessions)
            report.screenStateHistoryPercentage = Double(report.sessionsWithScreenStateHistory) / Double(totalSessions)
            report.locationPercentage = Double(report.sessionsWithLocation) / Double(totalSessions)
            report.nfcTagPercentage = Double(report.sessionsWithNFCTag) / Double(totalSessions)
            report.nfcUsageTypePercentage = Double(report.sessionsWithNFCUsageType) / Double(totalSessions)
            report.nfcTriggerSourcePercentage = Double(report.sessionsWithNFCTriggerSource) / Double(totalSessions)
            report.nfcDurationPercentage = Double(report.sessionsWithNFCDuration) / Double(totalSessions)
            report.locationTagPercentage = Double(report.sessionsWithLocationTag) / Double(totalSessions)
        }
        
        // 计算数据收集时间范围
        if sessions.count > 1 {
            let sortedSessions = sessions.sorted { $0.timestamp < $1.timestamp }
            report.dataCollectionStartDate = sortedSessions.first?.timestamp
            report.dataCollectionEndDate = sortedSessions.last?.timestamp
            report.dataCollectionDuration = report.dataCollectionEndDate?.timeIntervalSince(report.dataCollectionStartDate ?? Date()) ?? 0
        }
        
        return report
    }
    
    /// 导出传感器数据统计报告为CSV
    func exportSensorDataReportCSV(from sessions: [NFCSessionData]) -> URL? {
        let report = generateSensorDataReport(from: sessions)
        let fileName = "CardPilot_SensorReport_\(DateFormatter.fileNameFormatter.string(from: Date())).csv"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        var csvContent = "Sensor Data Collection Report\n"
        csvContent += "Generated: \(DateFormatter.csvFormatter.string(from: Date()))\n"
        csvContent += "Total Sessions: \(sessions.count)\n\n"
        
        // 数据收集时间范围
        if let startDate = report.dataCollectionStartDate, let endDate = report.dataCollectionEndDate {
            csvContent += "Data Collection Period\n"
            csvContent += "Start Date,\(DateFormatter.csvFormatter.string(from: startDate))\n"
            csvContent += "End Date,\(DateFormatter.csvFormatter.string(from: endDate))\n"
            csvContent += "Duration (seconds),\(report.dataCollectionDuration)\n"
            csvContent += "Duration (hours),\(report.dataCollectionDuration / 3600)\n\n"
        }
        
        // 传感器数据统计
        csvContent += "Sensor Data Availability\n"
        csvContent += "Sensor,Available Sessions,Percentage\n"
        csvContent += "IMU,\(report.sessionsWithIMU),\(String(format: "%.1f%%", report.imuDataPercentage * 100))\n"
        csvContent += "Magnetometer,\(report.sessionsWithMagnetometer),\(String(format: "%.1f%%", report.magnetometerPercentage * 100))\n"
        csvContent += "Barometer,\(report.sessionsWithBarometer),\(String(format: "%.1f%%", report.barometerPercentage * 100))\n"
        csvContent += "Ambient Light,\(report.sessionsWithAmbientLight),\(String(format: "%.1f%%", report.ambientLightPercentage * 100))\n"
        csvContent += "Proximity,\(report.sessionsWithProximity),\(String(format: "%.1f%%", report.proximityPercentage * 100))\n"
        csvContent += "Pedometer,\(report.sessionsWithPedometer),\(String(format: "%.1f%%", report.pedometerPercentage * 100))\n"
        csvContent += "Temperature,\(report.sessionsWithTemperature),\(String(format: "%.1f%%", report.temperaturePercentage * 100))\n"
        csvContent += "Microphone,\(report.sessionsWithMicrophone),\(String(format: "%.1f%%", report.microphonePercentage * 100))\n"
        csvContent += "Weather,\(report.sessionsWithWeather),\(String(format: "%.1f%%", report.weatherPercentage * 100))\n"
        csvContent += "Screen State History,\(report.sessionsWithScreenStateHistory),\(String(format: "%.1f%%", report.screenStateHistoryPercentage * 100))\n"
        csvContent += "Location,\(report.sessionsWithLocation),\(String(format: "%.1f%%", report.locationPercentage * 100))\n\n"
        
        // NFC数据统计
        csvContent += "NFC Data Availability\n"
        csvContent += "Data Type,Available Sessions,Percentage\n"
        csvContent += "NFC Tag Data,\(report.sessionsWithNFCTag),\(String(format: "%.1f%%", report.nfcTagPercentage * 100))\n"
        csvContent += "NFC Usage Type,\(report.sessionsWithNFCUsageType),\(String(format: "%.1f%%", report.nfcUsageTypePercentage * 100))\n"
        csvContent += "NFC Trigger Source,\(report.sessionsWithNFCTriggerSource),\(String(format: "%.1f%%", report.nfcTriggerSourcePercentage * 100))\n"
        csvContent += "NFC Session Duration,\(report.sessionsWithNFCDuration),\(String(format: "%.1f%%", report.nfcDurationPercentage * 100))\n\n"
        
        // IMU数据统计
        csvContent += "IMU Data Statistics\n"
        csvContent += "Total IMU Data Points,\(report.totalIMUDataPoints)\n"
        csvContent += "Average IMU Points per Session,\(report.totalIMUDataPoints > 0 ? String(format: "%.1f", Double(report.totalIMUDataPoints) / Double(sessions.count)) : "0")\n"
        
        do {
            try csvContent.data(using: .utf8)?.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write sensor report CSV: \(error)")
            return nil
        }
    }
    
    /// 按时间范围导出数据
    func exportDataInTimeRange(_ sessions: [NFCSessionData], 
                              from startDate: Date, 
                              to endDate: Date, 
                              format: ExportFormat) -> URL? {
        let filteredSessions = sessions.filter { session in
            session.timestamp >= startDate && session.timestamp <= endDate
        }
        
        let fileName = "CardPilot_Export_\(DateFormatter.fileNameFormatter.string(from: startDate))_to_\(DateFormatter.fileNameFormatter.string(from: endDate)).\(format.fileExtension)"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            let exportData: Data
            
            switch format {
            case .csv:
                exportData = try generateCSV(from: filteredSessions, includeLocation: true)
            case .json:
                exportData = try generateJSON(from: filteredSessions, includeLocation: true)
            case .csvPrivacy:
                exportData = try generateCSV(from: filteredSessions, includeLocation: false)
            case .jsonPrivacy:
                exportData = try generateJSON(from: filteredSessions, includeLocation: false)
            case .audioSamples:
                exportData = try generateAudioSamplesExport(from: filteredSessions)
            }
            
            try exportData.write(to: fileURL)
            return fileURL
        } catch {
            print("Time range export failed: \(error)")
            return nil
        }
    }
    
    /// 导出最近N天的数据
    func exportRecentData(_ sessions: [NFCSessionData], 
                          days: Int, 
                          format: ExportFormat) -> URL? {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentSessions = sessions.filter { $0.timestamp >= cutoffDate }
        
        let fileName = "CardPilot_Recent\(days)Days_\(DateFormatter.fileNameFormatter.string(from: Date())).\(format.fileExtension)"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            let exportData: Data
            
            switch format {
            case .csv:
                exportData = try generateCSV(from: recentSessions, includeLocation: true)
            case .json:
                exportData = try generateJSON(from: recentSessions, includeLocation: true)
            case .csvPrivacy:
                exportData = try generateCSV(from: recentSessions, includeLocation: false)
            case .jsonPrivacy:
                exportData = try generateJSON(from: recentSessions, includeLocation: false)
            case .audioSamples:
                exportData = try generateAudioSamplesExport(from: recentSessions)
            }
            
            try exportData.write(to: fileURL)
            return fileURL
        } catch {
            print("Recent data export failed: \(error)")
            return nil
        }
    }
    
    /// 按数据类型过滤导出
    func exportDataByType(_ sessions: [NFCSessionData], 
                          dataType: DataTypeFilter, 
                          format: ExportFormat) -> URL? {
        let filteredSessions: [NFCSessionData]
        
        switch dataType {
        case .nfcData:
            filteredSessions = sessions.filter { $0.nfcTagData != nil || $0.nfcUsageType != nil }
        case .locationData:
            filteredSessions = sessions.filter { $0.latitude != nil && $0.longitude != nil }
        case .sensorData:
            filteredSessions = sessions.filter { 
                $0.imuData != nil || $0.magnetometerData != nil || $0.barometerData != nil ||
                $0.ambientLightData != nil || $0.proximityData != nil || $0.pedometerData != nil ||
                $0.temperatureData != nil || $0.microphoneData != nil || $0.weatherData != nil
            }
        case .screenStateData:
            filteredSessions = sessions.filter { $0.screenStateHistory != nil }
        case .allData:
            filteredSessions = sessions
        }
        
        let fileName = "CardPilot_\(dataType.rawValue)_\(DateFormatter.fileNameFormatter.string(from: Date())).\(format.fileExtension)"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            let exportData: Data
            
            switch format {
            case .csv:
                exportData = try generateCSV(from: filteredSessions, includeLocation: true)
            case .json:
                exportData = try generateJSON(from: filteredSessions, includeLocation: true)
            case .csvPrivacy:
                exportData = try generateCSV(from: filteredSessions, includeLocation: false)
            case .jsonPrivacy:
                exportData = try generateJSON(from: filteredSessions, includeLocation: false)
            case .audioSamples:
                exportData = try generateAudioSamplesExport(from: filteredSessions)
            }
            
            try exportData.write(to: fileURL)
            return fileURL
        } catch {
            print("Data type export failed: \(error)")
            return nil
        }
    }
    
    private func calculateDataQualityScore(
        hasIMU: Bool,
        hasMagnetometer: Bool,
        hasBarometer: Bool,
        hasAmbientLight: Bool,
        hasProximity: Bool,
        hasPedometer: Bool,
        hasTemperature: Bool,
        hasMicrophone: Bool,
        hasWeather: Bool,
        hasScreenState: Bool
    ) -> Double {
        let totalSensors = 10.0 // 总传感器数量
        var availableSensors = 0.0
        
        if hasIMU { availableSensors += 1.0 }
        if hasMagnetometer { availableSensors += 1.0 }
        if hasBarometer { availableSensors += 1.0 }
        if hasAmbientLight { availableSensors += 1.0 }
        if hasProximity { availableSensors += 1.0 }
        if hasPedometer { availableSensors += 1.0 }
        if hasTemperature { availableSensors += 1.0 }
        if hasMicrophone { availableSensors += 1.0 }
        if hasWeather { availableSensors += 1.0 }
        if hasScreenState { availableSensors += 1.0 }
        
        return availableSensors / totalSensors
    }
    
    private func calculateTotalDataPoints(sessions: [NFCSessionData]) -> Int {
        return sessions.reduce(0) { total, session in
            var points = 0
            if let imuData = session.imuData {
                if let imuSession = try? JSONDecoder().decode(IMUSession.self, from: imuData) {
                    points += imuSession.dataPoints.count
                }
            }
            return total + points
        }
    }
    
    private func calculateAverageDataQualityScore(sessions: [ExportableSession]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        let totalScore = sessions.reduce(0.0) { $0 + ($1.sensorDataSummary?.dataQualityScore ?? 0.0) }
        return totalScore / Double(sessions.count)
    }
    
    private func calculateDataCollectionPeriod(sessions: [NFCSessionData]) -> TimeInterval {
        guard sessions.count > 1 else { return 0.0 }
        let sortedSessions = sessions.sorted { $0.timestamp < $1.timestamp }
        let firstSession = sortedSessions.first!
        let lastSession = sortedSessions.last!
        return lastSession.timestamp.timeIntervalSince(firstSession.timestamp)
    }
    
    // MARK: - Audio Samples Export
    
    private func generateAudioSamplesExport(from sessions: [NFCSessionData]) throws -> Data {
        // 创建临时目录
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("CardPilot_Audio_Export_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            // 清理临时目录
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // 创建元数据文件
        let metadata = createAudioExportMetadata(from: sessions)
        let metadataURL = tempDir.appendingPathComponent("metadata.json")
        try JSONEncoder().encode(metadata).write(to: metadataURL)
        
        // 提取音频文件
        var audioFileCount = 0
        for (index, session) in sessions.enumerated() {
            if let microphoneData = session.microphoneData,
               let microphone = try? JSONDecoder().decode(MicrophoneData.self, from: microphoneData) {
                
                // 创建音频文件名
                let timestamp = DateFormatter.fileNameFormatter.string(from: session.timestamp)
                let audioFileName = "audio_\(index)_\(timestamp).m4a"
                let audioURL = tempDir.appendingPathComponent(audioFileName)
                
                // 写入音频数据
                try microphone.audioData.write(to: audioURL)
                audioFileCount += 1
                
                // 创建音频元数据文件
                let audioMetadata = AudioFileMetadata(
                    sessionIndex: index,
                    timestamp: session.timestamp,
                    sampleRate: microphone.sampleRate,
                    averageVolume: microphone.averageVolume,
                    peakVolume: microphone.peakVolume,
                    audioDuration: Double(microphone.audioData.count) / microphone.sampleRate,
                    fileName: audioFileName,
                    fileSize: microphone.audioData.count,
                    location: session.latitude != nil ? "\(session.latitude!), \(session.longitude!)" : "N/A",
                    nfcTagData: session.nfcTagData ?? "N/A",
                    nfcUsageType: session.nfcUsageType ?? "N/A"
                )
                
                let audioMetadataURL = tempDir.appendingPathComponent("audio_\(index)_metadata.json")
                try JSONEncoder().encode(audioMetadata).write(to: audioMetadataURL)
            }
        }
        
        // 创建ZIP文件
        let zipURL = tempDir.appendingPathComponent("CardPilot_Audio_Samples.zip")
        try createZipArchive(from: tempDir, to: zipURL, excluding: ["CardPilot_Audio_Samples.zip"])
        
        // 读取ZIP文件数据
        let zipData = try Data(contentsOf: zipURL)
        
        print("✅ Audio samples export completed: \(audioFileCount) audio files")
        return zipData
    }
    
    private func createAudioExportMetadata(from sessions: [NFCSessionData]) -> AudioExportMetadata {
        var metadata = AudioExportMetadata()
        
        // 统计信息
        metadata.totalSessions = sessions.count
        metadata.sessionsWithAudio = sessions.filter { $0.microphoneData != nil }.count
        metadata.totalAudioDuration = 0.0
        metadata.totalAudioSize = 0
        
        // 音频质量统计
        var volumes: [Double] = []
        var sampleRates: [Double] = []
        
        for session in sessions {
            if let microphoneData = session.microphoneData,
               let microphone = try? JSONDecoder().decode(MicrophoneData.self, from: microphoneData) {
                
                let duration = Double(microphone.audioData.count) / microphone.sampleRate
                metadata.totalAudioDuration += duration
                metadata.totalAudioSize += microphone.audioData.count
                
                volumes.append(microphone.averageVolume)
                sampleRates.append(microphone.sampleRate)
            }
        }
        
        // 计算统计值
        if !volumes.isEmpty {
            metadata.averageVolume = volumes.reduce(0, +) / Double(volumes.count)
            metadata.maxVolume = volumes.max() ?? 0
            metadata.minVolume = volumes.min() ?? 0
        }
        
        if !sampleRates.isEmpty {
            metadata.averageSampleRate = sampleRates.reduce(0, +) / Double(sampleRates.count)
        }
        
        // 时间范围
        let sortedSessions = sessions.sorted { $0.timestamp < $1.timestamp }
        metadata.exportStartDate = sortedSessions.first?.timestamp
        metadata.exportEndDate = sortedSessions.last?.timestamp
        
        return metadata
    }
    
    private func createZipArchive(from sourceDir: URL, to destinationURL: URL, excluding filenames: [String]) throws {
        // 在iOS中，我们使用简单的文件复制来模拟ZIP功能
        // 由于iOS不支持Process类，我们创建一个包含所有文件的目录结构
        
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: sourceDir, includingPropertiesForKeys: nil)
        
        // 创建目标目录
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        
        // 复制所有文件（排除指定的文件名）
        for item in contents {
            if !filenames.contains(item.lastPathComponent) {
                let sourcePath = sourceDir.appendingPathComponent(item.lastPathComponent)
                let destPath = destinationURL.appendingPathComponent(item.lastPathComponent)
                
                if fileManager.fileExists(atPath: destPath.path) {
                    try fileManager.removeItem(at: destPath)
                }
                
                try fileManager.copyItem(at: sourcePath, to: destPath)
            }
        }
        
        // 创建一个简单的索引文件来说明内容
        let indexContent = """
        Audio Samples Export
        ===================
        
        This directory contains audio samples from NFC sessions.
        Files are organized by session timestamp.
        
        Exported on: \(DateFormatter.fileNameFormatter.string(from: Date()))
        Total files: \(contents.filter { !filenames.contains($0.lastPathComponent) }.count)
        
        Note: This is a directory export (ZIP functionality not available on iOS).
        You can manually compress these files using your computer's ZIP utility.
        """
        
        let indexURL = destinationURL.appendingPathComponent("README.txt")
        try indexContent.write(to: indexURL, atomically: true, encoding: .utf8)
    }
}

// MARK: - Export Data Structures

struct ExportData: Codable {
    let exportInfo: ExportInfo
    let sessions: [ExportableSession]
    let sensorDataReport: SensorDataReport
}

struct ExportInfo: Codable {
    let exportDate: Date
    let totalSessions: Int
    let includeLocation: Bool
    let exportFormat: String
    let dataCompression: Bool
}

struct ExportableSession: Codable {
    let timestamp: Date
    let address: String?
    let location: LocationData?
    let network: ExportNetworkData?
    let currentAppName: String?
    
    // NFC相关信息（拆分为对象）
    let nfc: NFCData
    
    // 位置标签信息
    let locationTag: String?
    
    // 屏幕状态信息（合并为对象）
    let screen: ScreenData?
    
    // 传感器数据
    let imuSession: IMUSession?
    let magnetometerData: EnhancedMagnetometerData?
    let barometerData: EnhancedBarometerData?
    let ambientLightData: AmbientLightData?
    let proximityData: ProximityData?
    let pedometerData: PedometerData?
    let temperatureData: TemperatureData?
    let microphoneData: EnhancedMicrophoneData?
    let weatherData: WeatherData?
    
    // 传感器数据统计信息
    let sensorDataSummary: SensorDataSummary?
}

// MARK: - 新的结构化数据对象

// 位置数据对象
struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
}

// NFC数据对象
struct NFCData: Codable {
    let type: String?
    let source: String?
    let duration: Double?
    let tagData: String?
}

// 屏幕数据对象
struct ScreenData: Codable {
    let state: String?
    let brightness: Double?
    let stateHistory: [ScreenStateEvent]?
}

// 网络数据对象（用于导出）
struct ExportNetworkData: Codable {
    let ipAddress: String?
    let wifiSSID: String?
}

// 新增传感器数据统计结构
struct SensorDataSummary: Codable {
    let hasIMUData: Bool
    let imuDataPointsCount: Int
    let hasMagnetometerData: Bool
    let hasBarometerData: Bool
    let hasAmbientLightData: Bool
    let hasProximityData: Bool
    let hasPedometerData: Bool
    let hasTemperatureData: Bool
    let hasMicrophoneData: Bool
    let hasWeatherData: Bool
    let hasScreenStateHistory: Bool
    let screenStateHistoryCount: Int
    let dataQualityScore: Double // 0.0 - 1.0，基于可用数据的完整性
}

// MARK: - Date Formatters

extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
    
    static let csvFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

// MARK: - Sensor Data Report Structure

struct SensorDataReport: Codable {
    // 传感器数据统计
    var sessionsWithIMU: Int = 0
    var sessionsWithMagnetometer: Int = 0
    var sessionsWithBarometer: Int = 0
    var sessionsWithAmbientLight: Int = 0
    var sessionsWithProximity: Int = 0
    var sessionsWithPedometer: Int = 0
    var sessionsWithTemperature: Int = 0
    var sessionsWithMicrophone: Int = 0
    var sessionsWithWeather: Int = 0
    var sessionsWithScreenStateHistory: Int = 0
    var sessionsWithLocation: Int = 0
    
    // NFC数据统计
    var sessionsWithNFCTag: Int = 0
    var sessionsWithNFCUsageType: Int = 0
    var sessionsWithNFCTriggerSource: Int = 0
    var sessionsWithNFCDuration: Int = 0
    
    // 位置标签统计
    var sessionsWithLocationTag: Int = 0
    var totalLocationTags: Int = 0
    var uniqueLocationTags: Int = 0
    
    // IMU数据统计
    var totalIMUDataPoints: Int = 0
    
    // 百分比统计
    var imuDataPercentage: Double = 0.0
    var magnetometerPercentage: Double = 0.0
    var barometerPercentage: Double = 0.0
    var ambientLightPercentage: Double = 0.0
    var proximityPercentage: Double = 0.0
    var pedometerPercentage: Double = 0.0
    var temperaturePercentage: Double = 0.0
    var microphonePercentage: Double = 0.0
    var weatherPercentage: Double = 0.0
    var screenStateHistoryPercentage: Double = 0.0
    var locationPercentage: Double = 0.0
    var nfcTagPercentage: Double = 0.0
    var nfcUsageTypePercentage: Double = 0.0
    var nfcTriggerSourcePercentage: Double = 0.0
    var nfcDurationPercentage: Double = 0.0
    var locationTagPercentage: Double = 0.0
    
    // 数据收集时间范围
    var dataCollectionStartDate: Date?
    var dataCollectionEndDate: Date?
    var dataCollectionDuration: TimeInterval = 0.0
}

// MARK: - Enhanced Sensor Data Structures

// 增强的磁力计数据
struct EnhancedMagnetometerData: Codable {
    let data: MagnetometerData
    let magneticFieldMagnitude: Double // 磁场强度大小
    
    var magneticFieldX: Double { data.magneticFieldX }
    var magneticFieldY: Double { data.magneticFieldY }
    var magneticFieldZ: Double { data.magneticFieldZ }
    var heading: Double { data.heading }
    var timestamp: TimeInterval { data.timestamp }
}

// 增强的气压计数据
struct EnhancedBarometerData: Codable {
    let data: BarometerData
    let pressureCategory: String // 气压分类：低、正常、高
    
    var pressure: Double { data.pressure }
    var relativeAltitude: Double? { data.relativeAltitude }
    var timestamp: TimeInterval { data.timestamp }
}

// 增强的麦克风数据
struct EnhancedMicrophoneData: Codable {
    let data: MicrophoneData
    let audioDuration: Double // 音频持续时间（秒）
    let volumeCategory: String // 音量分类：静音、低、中、高
    
    var audioData: Data { data.audioData }
    var sampleRate: Double { data.sampleRate }
    var averageVolume: Double { data.averageVolume }
    var peakVolume: Double { data.peakVolume }
    var timestamp: TimeInterval { data.timestamp }
}

// MARK: - Helper Functions

/// 构建地址字符串，合并所有地址相关字段
private func buildAddressString(
    street: String?,
    city: String?,
    state: String?,
    country: String?,
    postalCode: String?,
    administrativeArea: String?,
    subLocality: String?
) -> String {
    var addressComponents: [String] = []
    
    // 添加街道地址
    if let street = street, !street.isEmpty {
        addressComponents.append("Street: \(street)")
    }
    
    // 添加子区域
    if let subLocality = subLocality, !subLocality.isEmpty {
        addressComponents.append("Sub-locality: \(subLocality)")
    }
    
    // 添加城市
    if let city = city, !city.isEmpty {
        addressComponents.append("City: \(city)")
    }
    
    // 添加州/省
    if let state = state, !state.isEmpty {
        addressComponents.append("State: \(state)")
    }
    
    // 添加行政区
    if let administrativeArea = administrativeArea, !administrativeArea.isEmpty {
        addressComponents.append("Admin Area: \(administrativeArea)")
    }
    
    // 添加邮政编码
    if let postalCode = postalCode, !postalCode.isEmpty {
        addressComponents.append("Postal: \(postalCode)")
    }
    
    // 添加国家
    if let country = country, !country.isEmpty {
        addressComponents.append("Country: \(country)")
    }
    
    // 如果没有地址信息，返回"N/A"
    if addressComponents.isEmpty {
        return "N/A"
    }
    
    // 用分号分隔各个地址组件
    return addressComponents.joined(separator: "; ")
}

/// 构建位置字符串，合并经纬度
private func buildLocationString(latitude: Double?, longitude: Double?) -> String {
    if let lat = latitude, let lon = longitude {
        return "Lat: \(String(format: "%.6f", lat)), Lon: \(String(format: "%.6f", lon))"
    } else if let lat = latitude {
        return "Lat: \(String(format: "%.6f", lat)), Lon: N/A"
    } else if let lon = longitude {
        return "Lat: N/A, Lon: \(String(format: "%.6f", lon))"
    } else {
        return "N/A"
    }
}

/// 构建NFC字符串，合并所有NFC相关字段
private func buildNFCString(
    nfcTagData: String?,
    nfcUsageType: String?,
    nfcTriggerSource: String?,
    nfcSessionDuration: TimeInterval?
) -> String {
    var nfcComponents: [String] = []
    
    // 添加NFC标签数据
    if let nfcTagData = nfcTagData, !nfcTagData.isEmpty {
        nfcComponents.append("Tag: \(nfcTagData)")
    }
    
    // 添加NFC使用类型
    if let nfcUsageType = nfcUsageType, !nfcUsageType.isEmpty {
        nfcComponents.append("Type: \(nfcUsageType)")
    }
    
    // 添加NFC触发源
    if let nfcTriggerSource = nfcTriggerSource, !nfcTriggerSource.isEmpty {
        nfcComponents.append("Source: \(nfcTriggerSource)")
    }
    
    // 添加NFC会话持续时间
    if let nfcSessionDuration = nfcSessionDuration {
        nfcComponents.append("Duration: \(String(format: "%.2f", nfcSessionDuration))s")
    }
    
    // 如果没有NFC信息，返回"N/A"
    if nfcComponents.isEmpty {
        return "N/A"
    }
    
    // 用分号分隔各个NFC组件
    return nfcComponents.joined(separator: "; ")
}

private func getPressureCategory(_ pressure: Double) -> String {
    if pressure < 1000 {
        return "Low"
    } else if pressure > 1020 {
        return "High"
    } else {
        return "Normal"
    }
}

private func getVolumeCategory(_ volume: Double) -> String {
    if volume < 10 {
        return "Silent"
    } else if volume < 50 {
        return "Low"
    } else if volume < 100 {
        return "Medium"
    } else {
        return "High"
    }
}

private func generateSensorDataReport(from sessions: [NFCSessionData]) -> SensorDataReport {
    var report = SensorDataReport()
    
    guard !sessions.isEmpty else { return report }
    
    // 统计传感器数据可用性
    report.sessionsWithIMU = sessions.filter { $0.imuData != nil }.count
    report.sessionsWithMagnetometer = sessions.filter { $0.magnetometerData != nil }.count
    report.sessionsWithBarometer = sessions.filter { $0.barometerData != nil }.count
    report.sessionsWithAmbientLight = sessions.filter { $0.ambientLightData != nil }.count
    report.sessionsWithProximity = sessions.filter { $0.proximityData != nil }.count
    report.sessionsWithPedometer = sessions.filter { $0.pedometerData != nil }.count
    report.sessionsWithTemperature = sessions.filter { $0.temperatureData != nil }.count
    report.sessionsWithMicrophone = sessions.filter { $0.microphoneData != nil }.count
    report.sessionsWithWeather = sessions.filter { $0.weatherData != nil }.count
    report.sessionsWithScreenStateHistory = sessions.filter { $0.screenStateHistory != nil }.count
    report.sessionsWithLocation = sessions.filter { $0.latitude != nil && $0.longitude != nil }.count
    
    // NFC数据统计
    report.sessionsWithNFCTag = sessions.filter { $0.nfcTagData != nil }.count
    report.sessionsWithNFCUsageType = sessions.filter { $0.nfcUsageType != nil }.count
    report.sessionsWithNFCTriggerSource = sessions.filter { $0.nfcTriggerSource != nil }.count
    report.sessionsWithNFCDuration = sessions.filter { $0.nfcSessionDuration != nil }.count
    
    // IMU数据统计
    for session in sessions {
        if let imuData = session.imuData,
           let imuSession = try? JSONDecoder().decode(IMUSession.self, from: imuData) {
            report.totalIMUDataPoints += imuSession.dataPoints.count
        }
    }
    
    // 计算百分比
    let totalSessions = Double(sessions.count)
    report.imuDataPercentage = Double(report.sessionsWithIMU) / totalSessions
    report.magnetometerPercentage = Double(report.sessionsWithMagnetometer) / totalSessions
    report.barometerPercentage = Double(report.sessionsWithBarometer) / totalSessions
    report.ambientLightPercentage = Double(report.sessionsWithAmbientLight) / totalSessions
    report.proximityPercentage = Double(report.sessionsWithProximity) / totalSessions
    report.pedometerPercentage = Double(report.sessionsWithPedometer) / totalSessions
    report.temperaturePercentage = Double(report.sessionsWithTemperature) / totalSessions
    report.microphonePercentage = Double(report.sessionsWithMicrophone) / totalSessions
    report.weatherPercentage = Double(report.sessionsWithWeather) / totalSessions
    report.screenStateHistoryPercentage = Double(report.sessionsWithScreenStateHistory) / totalSessions
    report.locationPercentage = Double(report.sessionsWithLocation) / totalSessions
    report.nfcTagPercentage = Double(report.sessionsWithNFCTag) / totalSessions
    report.nfcUsageTypePercentage = Double(report.sessionsWithNFCUsageType) / totalSessions
    report.nfcTriggerSourcePercentage = Double(report.sessionsWithNFCTriggerSource) / totalSessions
    report.nfcDurationPercentage = Double(report.sessionsWithNFCDuration) / totalSessions
    
    // 数据收集时间范围
    let sortedSessions = sessions.sorted { $0.timestamp < $1.timestamp }
    report.dataCollectionStartDate = sortedSessions.first?.timestamp
    report.dataCollectionEndDate = sortedSessions.last?.timestamp
    if let start = report.dataCollectionStartDate, let end = report.dataCollectionEndDate {
        report.dataCollectionDuration = end.timeIntervalSince(start)
    }
    
    return report
}

// MARK: - Audio Export Data Structures

struct AudioExportMetadata: Codable {
    var totalSessions: Int = 0
    var sessionsWithAudio: Int = 0
    var totalAudioDuration: Double = 0.0
    var totalAudioSize: Int = 0
    var averageVolume: Double = 0.0
    var maxVolume: Double = 0.0
    var minVolume: Double = 0.0
    var averageSampleRate: Double = 0.0
    var exportStartDate: Date?
    var exportEndDate: Date?
    
    var exportDuration: TimeInterval {
        guard let start = exportStartDate, let end = exportEndDate else { return 0 }
        return end.timeIntervalSince(start)
    }
    
    var audioCoveragePercentage: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(sessionsWithAudio) / Double(totalSessions) * 100
    }
}

struct AudioFileMetadata: Codable {
    let sessionIndex: Int
    let timestamp: Date
    let sampleRate: Double
    let averageVolume: Double
    let peakVolume: Double
    let audioDuration: Double
    let fileName: String
    let fileSize: Int
    let location: String
    let nfcTagData: String
    let nfcUsageType: String
    
    var volumeCategory: String {
        if averageVolume < 10 { return "Silent" }
        else if averageVolume < 50 { return "Low" }
        else if averageVolume < 100 { return "Medium" }
        else { return "High" }
    }
    
    var durationCategory: String {
        if audioDuration < 1 { return "Very Short" }
        else if audioDuration < 3 { return "Short" }
        else if audioDuration < 5 { return "Medium" }
        else { return "Long" }
    }
}
