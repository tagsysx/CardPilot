//
//  NFCSessionViews.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI
import Foundation

struct NFCSessionRowView: View {
    let session: NFCSessionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                    .font(.headline)
                Spacer()
                if let appName = session.currentAppName {
                    Text(appName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            HStack(spacing: 16) {
                // Location
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.locationString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 如果有宏观地点信息，显示简要信息
                        if let city = session.city, !city.isEmpty {
                            Text(city)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // IP Address
                if let ip = session.ipAddress {
                    HStack(spacing: 4) {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                        Text(ip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // IMU Data indicator
            if session.imuData != nil {
                HStack(spacing: 4) {
                    Image(systemName: "gyroscope")
                        .foregroundColor(.orange)
                    Text("IMU data collected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct NFCSessionDetailView: View {
    let session: NFCSessionData
    @State private var decodedIMUData: IMUSession?
    @State private var showingDeleteAlert = false
    @State private var showingTagSelector = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with Delete Button
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NFC Session Details")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(session.timestamp, format: Date.FormatStyle(date: .complete, time: .complete))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Delete Button
                    Button(action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
                
                // Location Section
                SectionView(title: "Location", icon: "location") {
                    if let lat = session.latitude, let lon = session.longitude {
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "Latitude", value: String(format: "%.6f", lat))
                            DetailRow(label: "Longitude", value: String(format: "%.6f", lon))
                            DetailRow(label: "Coordinates", value: "\(lat), \(lon)")
                            
                            // GPS地图组件
                            VStack(alignment: .leading, spacing: 8) {
                                Text("GPS Location Map")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .padding(.top, 8)
                                
                                LocationMapView(sessions: [session])
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // 显示宏观地点信息
                            if session.street != nil || session.city != nil || session.state != nil || session.country != nil {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                Text("Address Information")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .padding(.top, 8)
                                
                                if let street = session.street, !street.isEmpty {
                                    DetailRow(label: "Street", value: street)
                                }
                                if let city = session.city, !city.isEmpty {
                                    DetailRow(label: "City", value: city)
                                }
                                if let state = session.state, !state.isEmpty {
                                    DetailRow(label: "State/Province", value: state)
                                }
                                if let country = session.country, !country.isEmpty {
                                    DetailRow(label: "Country", value: country)
                                }
                                if let postalCode = session.postalCode, !postalCode.isEmpty {
                                    DetailRow(label: "Postal Code", value: postalCode)
                                }
                                if let administrativeArea = session.administrativeArea, !administrativeArea.isEmpty {
                                    DetailRow(label: "Administrative Area", value: administrativeArea)
                                }
                                if let subLocality = session.subLocality, !subLocality.isEmpty {
                                    DetailRow(label: "Sub-locality", value: subLocality)
                                }
                            }
                        }
                    } else {
                        Text("Location not available")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Network Section
                SectionView(title: "Network", icon: "network") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let ip = session.ipAddress {
                            DetailRow(label: "IP Address", value: ip)
                        } else {
                            Text("IP address not available")
                                .foregroundColor(.secondary)
                        }
                        
                        if let wifiSSID = session.wifiSSID {
                            DetailRow(label: "WiFi SSID", value: wifiSSID)
                        } else {
                            Text("WiFi SSID not available")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // App Section
                SectionView(title: "Application", icon: "app") {
                    if let appName = session.currentAppName {
                        DetailRow(label: "App Name", value: appName)
                    } else {
                        Text("App information not available")
                            .foregroundColor(.secondary)
                    }
                }
                
                // NFC Section
                SectionView(title: "NFC", icon: "contactlessreader.radio.waves") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let nfcTagData = session.nfcTagData, !nfcTagData.isEmpty {
                            DetailRow(label: "NFC UID", value: nfcTagData)
                        } else {
                            Text("NFC UID not available")
                                .foregroundColor(.secondary)
                        }
                        
                        if let nfcUsageType = session.nfcUsageType {
                            DetailRow(label: "Usage Type", value: nfcUsageType)
                        }
                        
                        if let nfcTriggerSource = session.nfcTriggerSource {
                            DetailRow(label: "Trigger Source", value: nfcTriggerSource)
                        }
                        
                        if let nfcSessionDuration = session.nfcSessionDuration {
                            DetailRow(label: "Session Duration", value: String(format: "%.2f seconds", nfcSessionDuration))
                        }
                    }
                }
                
                // Location Tags Section
                SectionView(title: "Location Tags", icon: "tag") {
                    VStack(alignment: .leading, spacing: 12) {
                        // 当前选中的标签
                        if let locationTag = session.locationTag {
                            HStack {
                                Text("Current Tag:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(locationTag)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                Button("Change") {
                                    // 清除标签并保存到数据模型
                                    session.locationTag = nil
                                    saveChanges()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        } else {
                            Text("No tag selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        
                        // 标签选择器 - 绑定到数据模型
                        LocationTagSelector(selectedTag: Binding(
                            get: { session.locationTag },
                            set: { newTag in
                                session.locationTag = newTag
                                saveChanges()
                            }
                        ))
                    }
                }
                
                // IMU Data Section
                SectionView(title: "Motion Data", icon: "gyroscope") {
                    if let imuData = decodedIMUData {
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "Collection Duration", 
                                     value: String(format: "%.2f seconds", 
                                                 imuData.endTime.timeIntervalSince(imuData.startTime)))
                            DetailRow(label: "Data Points", value: "\(imuData.dataPoints.count)")
                            DetailRow(label: "Sample Rate", 
                                     value: String(format: "%.1f Hz", 
                                                 Double(imuData.dataPoints.count) / imuData.endTime.timeIntervalSince(imuData.startTime)))
                            
                            if !imuData.dataPoints.isEmpty {
                                Text("Sample Data Point:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                
                                let firstPoint = imuData.dataPoints[0]
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Acceleration: (\(String(format: "%.3f", firstPoint.accelerationX)), \(String(format: "%.3f", firstPoint.accelerationY)), \(String(format: "%.3f", firstPoint.accelerationZ)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Rotation: (\(String(format: "%.3f", firstPoint.rotationRateX)), \(String(format: "%.3f", firstPoint.rotationRateY)), \(String(format: "%.3f", firstPoint.rotationRateZ)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 16)
                            }
                        }
                    } else if session.imuData != nil {
                        Text("Processing IMU data...")
                            .foregroundColor(.secondary)
                    } else {
                        Text("IMU data not available")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 新增传感器数据部分
                SectionView(title: "Sensor Data", icon: "sensor.tag.radiowaves.forward") {
                    VStack(alignment: .leading, spacing: 12) {
                        // 磁力计数据
                        if let magnetometerData = session.magnetometerData,
                           let decodedMagnetometer = try? JSONDecoder().decode(MagnetometerData.self, from: magnetometerData) {
                            SensorDataView(title: "Magnetometer", icon: "location.north") {
                                DetailRow(label: "Magnetic Field X", value: String(format: "%.2f μT", decodedMagnetometer.magneticFieldX))
                                DetailRow(label: "Magnetic Field Y", value: String(format: "%.2f μT", decodedMagnetometer.magneticFieldY))
                                DetailRow(label: "Magnetic Field Z", value: String(format: "%.2f μT", decodedMagnetometer.magneticFieldZ))
                                DetailRow(label: "Heading", value: String(format: "%.1f°", decodedMagnetometer.heading))
                            }
                        }
                        
                        // 气压计数据
                        if let barometerData = session.barometerData,
                           let decodedBarometer = try? JSONDecoder().decode(BarometerData.self, from: barometerData) {
                            SensorDataView(title: "Barometer", icon: "gauge") {
                                DetailRow(label: "Pressure", value: String(format: "%.1f hPa", decodedBarometer.pressure))
                                if let altitude = decodedBarometer.relativeAltitude {
                                    DetailRow(label: "Relative Altitude", value: String(format: "%.1f m", altitude))
                                }
                            }
                        }
                        
                        // 环境光数据
                        if let ambientLightData = session.ambientLightData,
                           let decodedAmbientLight = try? JSONDecoder().decode(AmbientLightData.self, from: ambientLightData) {
                            SensorDataView(title: "Ambient Light", icon: "sun.max") {
                                DetailRow(label: "Brightness", value: String(format: "%.1f lux", decodedAmbientLight.brightness))
                            }
                        }
                        
                        // 距离传感器数据
                        if let proximityData = session.proximityData,
                           let decodedProximity = try? JSONDecoder().decode(ProximityData.self, from: proximityData) {
                            SensorDataView(title: "Proximity Sensor", icon: "ruler") {
                                DetailRow(label: "Is Close", value: decodedProximity.isClose ? "Yes" : "No")
                                if let distance = decodedProximity.distance {
                                    DetailRow(label: "Distance", value: String(format: "%.3f m", distance))
                                }
                            }
                        }
                        
                        // 计步器数据
                        if let pedometerData = session.pedometerData,
                           let decodedPedometer = try? JSONDecoder().decode(PedometerData.self, from: pedometerData) {
                            SensorDataView(title: "Pedometer (Last 10 min)", icon: "figure.walk") {
                                DetailRow(label: "Step Count", value: "\(decodedPedometer.stepCount)")
                                if let distance = decodedPedometer.distance {
                                    DetailRow(label: "Distance", value: String(format: "%.1f m", distance))
                                }
                                if let pace = decodedPedometer.averagePace {
                                    DetailRow(label: "Average Pace", value: String(format: "%.1f steps/min", pace))
                                }
                            }
                        }
                        
                        // 温度传感器数据
                        if let temperatureData = session.temperatureData,
                           let decodedTemperature = try? JSONDecoder().decode(TemperatureData.self, from: temperatureData) {
                            SensorDataView(title: "Temperature", icon: "thermometer") {
                                DetailRow(label: "Temperature", value: String(format: "%.1f°C", decodedTemperature.temperature))
                                if let humidity = decodedTemperature.humidity {
                                    DetailRow(label: "Humidity", value: String(format: "%.1f%%", humidity))
                                }
                            }
                        }
                        
                        // 麦克风数据
                        if let microphoneData = session.microphoneData,
                           let decodedMicrophone = try? JSONDecoder().decode(MicrophoneData.self, from: microphoneData) {
                            SensorDataView(title: "Microphone (3s Audio)", icon: "mic") {
                                DetailRow(label: "Sample Rate", value: String(format: "%.0f Hz", decodedMicrophone.sampleRate))
                                DetailRow(label: "Average Volume", value: String(format: "%.1f dB", decodedMicrophone.averageVolume))
                                DetailRow(label: "Peak Volume", value: String(format: "%.1f dB", decodedMicrophone.peakVolume))
                                DetailRow(label: "Audio Duration", value: "3.0 seconds")
                            }
                        }
                        
                        // 天气数据
                        if let weatherData = session.weatherData,
                           let decodedWeather = try? JSONDecoder().decode(WeatherData.self, from: weatherData) {
                            SensorDataView(title: "Weather", icon: "cloud.sun") {
                                DetailRow(label: "Temperature", value: String(format: "%.1f°C", decodedWeather.temperature))
                                DetailRow(label: "Humidity", value: String(format: "%.1f%%", decodedWeather.humidity))
                                DetailRow(label: "Pressure", value: String(format: "%.1f hPa", decodedWeather.pressure))
                                DetailRow(label: "Description", value: decodedWeather.description)
                                if let windSpeed = decodedWeather.windSpeed {
                                    DetailRow(label: "Wind Speed", value: String(format: "%.1f m/s", windSpeed))
                                }
                                if let windDirection = decodedWeather.windDirection {
                                    DetailRow(label: "Wind Direction", value: String(format: "%.1f°", windDirection))
                                }
                            }
                        }
                        
                        // 如果没有传感器数据
                        if session.magnetometerData == nil && session.barometerData == nil && 
                           session.ambientLightData == nil && session.proximityData == nil &&
                           session.pedometerData == nil && session.temperatureData == nil &&
                           session.microphoneData == nil && session.weatherData == nil {
                            Text("No sensor data available")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Session", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSession()
            }
        } message: {
            Text("Are you sure you want to delete this NFC session? This action cannot be undone.")
        }
        .onAppear {
            decodeIMUData()
        }
    }
    
    private func deleteSession() {
        // 从数据模型中删除session
        modelContext.delete(session)
        
        // 尝试保存更改
        do {
            try modelContext.save()
            // 关闭详情视图
            dismiss()
        } catch {
            print("Failed to delete session: \(error)")
            // 这里可以添加错误处理，比如显示错误提示
        }
    }
    
    private func decodeIMUData() {
        guard let imuData = session.imuData else { return }
        
        do {
            let decoded = try JSONDecoder().decode(IMUSession.self, from: imuData)
            self.decodedIMUData = decoded
        } catch {
            print("Failed to decode IMU data: \(error)")
        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
                .padding(.leading, 24)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
    }
}

// MARK: - Sensor Data View Component
struct SensorDataView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            content
                .padding(.leading, 24)
        }
        .padding(.vertical, 4)
    }
}
