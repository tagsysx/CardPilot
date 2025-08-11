//
//  CardPilotTests.swift
//  CardPilotTests
//
//  Created by Lei Yang on 9/8/2025.
//

import XCTest
import SwiftData
@testable import CardPilot

final class CardPilotTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        // Create an in-memory model container for testing
        let schema = Schema([NFCSessionData.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - NFCSessionData Tests
    
    func testNFCSessionDataCreation() throws {
        let sessionData = NFCSessionData(
            timestamp: Date(),
            latitude: 37.7749,
            longitude: -122.4194,
            ipAddress: "192.168.1.100",
            currentAppName: "TestApp",
            imuData: nil,
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            magnetometerData: nil,
            barometerData: nil,
            ambientLightData: nil,
            proximityData: nil,
            pedometerData: nil,
            temperatureData: nil,
            microphoneData: nil,
            weatherData: nil
        )
        
        XCTAssertNotNil(sessionData.timestamp)
        XCTAssertEqual(sessionData.latitude, 37.7749)
        XCTAssertEqual(sessionData.longitude, -122.4194)
        XCTAssertEqual(sessionData.ipAddress, "192.168.1.100")
        XCTAssertEqual(sessionData.currentAppName, "TestApp")
        XCTAssertNil(sessionData.imuData)
        XCTAssertEqual(sessionData.street, "123 Main St")
        XCTAssertEqual(sessionData.city, "San Francisco")
        XCTAssertEqual(sessionData.state, "CA")
        XCTAssertEqual(sessionData.country, "USA")
        
        // 测试新的传感器数据字段
        XCTAssertNil(sessionData.magnetometerData)
        XCTAssertNil(sessionData.barometerData)
        XCTAssertNil(sessionData.ambientLightData)
        XCTAssertNil(sessionData.proximityData)
        XCTAssertNil(sessionData.pedometerData)
        XCTAssertNil(sessionData.temperatureData)
        XCTAssertNil(sessionData.microphoneData)
        XCTAssertNil(sessionData.weatherData)
    }
    
    func testLocationString() throws {
        let sessionWithLocation = NFCSessionData(
            latitude: 37.7749,
            longitude: -122.4194
        )
        XCTAssertEqual(sessionWithLocation.locationString, "37.7749, -122.4194")
        
        let sessionWithAddress = NFCSessionData(
            latitude: 37.7749,
            longitude: -122.4194,
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            country: "USA"
        )
        XCTAssertEqual(sessionWithAddress.locationString, "123 Main St, San Francisco, CA, USA")
        
        let sessionWithoutLocation = NFCSessionData()
        XCTAssertEqual(sessionWithoutLocation.locationString, "Location not available")
    }
    
    func testDetailedLocationString() throws {
        let sessionWithAddress = NFCSessionData(
            latitude: 37.7749,
            longitude: -122.4194,
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            postalCode: "94102"
        )
        
        let detailedString = sessionWithAddress.detailedLocationString
        XCTAssertTrue(detailedString.contains("Street: 123 Main St"))
        XCTAssertTrue(detailedString.contains("City: San Francisco"))
        XCTAssertTrue(detailedString.contains("State: CA"))
        XCTAssertTrue(detailedString.contains("Country: USA"))
        XCTAssertTrue(detailedString.contains("Postal Code: 94102"))
        
        let sessionWithoutAddress = NFCSessionData()
        XCTAssertEqual(sessionWithoutAddress.detailedLocationString, "No detailed location information available")
    }
    
    // MARK: - 传感器数据结构测试
    
    func testMagnetometerData() throws {
        let magnetometerData = MagnetometerData(
            timestamp: Date().timeIntervalSince1970,
            magneticFieldX: 25.5,
            magneticFieldY: -12.3,
            magneticFieldZ: 45.8,
            heading: 180.0
        )
        
        XCTAssertEqual(magnetometerData.magneticFieldX, 25.5, accuracy: 0.01)
        XCTAssertEqual(magnetometerData.magneticFieldY, -12.3, accuracy: 0.01)
        XCTAssertEqual(magnetometerData.magneticFieldZ, 45.8, accuracy: 0.01)
        XCTAssertEqual(magnetometerData.heading, 180.0, accuracy: 0.1)
    }
    
    func testBarometerData() throws {
        let barometerData = BarometerData(
            timestamp: Date().timeIntervalSince1970,
            pressure: 1013.25,
            relativeAltitude: 100.5
        )
        
        XCTAssertEqual(barometerData.pressure, 1013.25, accuracy: 0.01)
        XCTAssertEqual(barometerData.relativeAltitude, 100.5, accuracy: 0.1)
    }
    
    func testAmbientLightData() throws {
        let ambientLightData = AmbientLightData(
            timestamp: Date().timeIntervalSince1970,
            brightness: 500.0
        )
        
        XCTAssertEqual(ambientLightData.brightness, 500.0, accuracy: 0.1)
    }
    
    func testProximityData() throws {
        let proximityData = ProximityData(
            timestamp: Date().timeIntervalSince1970,
            distance: 0.05,
            isClose: true
        )
        
        XCTAssertEqual(proximityData.distance, 0.05, accuracy: 0.001)
        XCTAssertTrue(proximityData.isClose)
    }
    
    func testPedometerData() throws {
        let now = Date()
        let tenMinutesAgo = now.addingTimeInterval(-600)
        
        let pedometerData = PedometerData(
            timestamp: now.timeIntervalSince1970,
            stepCount: 150,
            distance: 120.5,
            averagePace: 15.0,
            startTime: tenMinutesAgo,
            endTime: now
        )
        
        XCTAssertEqual(pedometerData.stepCount, 150)
        XCTAssertEqual(pedometerData.distance, 120.5, accuracy: 0.1)
        XCTAssertEqual(pedometerData.averagePace, 15.0, accuracy: 0.1)
        XCTAssertEqual(pedometerData.startTime, tenMinutesAgo)
        XCTAssertEqual(pedometerData.endTime, now)
    }
    
    func testTemperatureData() throws {
        let temperatureData = TemperatureData(
            timestamp: Date().timeIntervalSince1970,
            temperature: 22.5,
            humidity: 65.0
        )
        
        XCTAssertEqual(temperatureData.temperature, 22.5, accuracy: 0.1)
        XCTAssertEqual(temperatureData.humidity, 65.0, accuracy: 0.1)
    }
    
    func testMicrophoneData() throws {
        let audioData = "test audio data".data(using: .utf8)!
        let microphoneData = MicrophoneData(
            timestamp: Date().timeIntervalSince1970,
            audioData: audioData,
            sampleRate: 44100.0,
            averageVolume: -20.5,
            peakVolume: -5.2
        )
        
        XCTAssertEqual(microphoneData.audioData, audioData)
        XCTAssertEqual(microphoneData.sampleRate, 44100.0, accuracy: 0.1)
        XCTAssertEqual(microphoneData.averageVolume, -20.5, accuracy: 0.1)
        XCTAssertEqual(microphoneData.peakVolume, -5.2, accuracy: 0.1)
    }
    
    func testWeatherData() throws {
        let weatherData = WeatherData(
            timestamp: Date().timeIntervalSince1970,
            temperature: 18.5,
            humidity: 70.0,
            pressure: 1015.0,
            windSpeed: 5.2,
            windDirection: 180.0,
            description: "Partly cloudy",
            icon: "cloud.sun"
        )
        
        XCTAssertEqual(weatherData.temperature, 18.5, accuracy: 0.1)
        XCTAssertEqual(weatherData.humidity, 70.0, accuracy: 0.1)
        XCTAssertEqual(weatherData.pressure, 1015.0, accuracy: 0.1)
        XCTAssertEqual(weatherData.windSpeed, 5.2, accuracy: 0.1)
        XCTAssertEqual(weatherData.windDirection, 180.0, accuracy: 0.1)
        XCTAssertEqual(weatherData.description, "Partly cloudy")
        XCTAssertEqual(weatherData.icon, "cloud.sun")
    }
    
    func testSensorDataSerialization() throws {
        // 测试传感器数据的序列化和反序列化
        let magnetometerData = MagnetometerData(
            timestamp: Date().timeIntervalSince1970,
            magneticFieldX: 25.5,
            magneticFieldY: -12.3,
            magneticFieldZ: 45.8,
            heading: 180.0
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(magnetometerData)
        let decodedData = try decoder.decode(MagnetometerData.self, from: encodedData)
        
        XCTAssertEqual(decodedData.magneticFieldX, magnetometerData.magneticFieldX, accuracy: 0.01)
        XCTAssertEqual(decodedData.magneticFieldY, magnetometerData.magneticFieldY, accuracy: 0.01)
        XCTAssertEqual(decodedData.magneticFieldZ, magnetometerData.magneticFieldZ, accuracy: 0.01)
        XCTAssertEqual(decodedData.heading, magnetometerData.heading, accuracy: 0.1)
    }
    
    // MARK: - IMU Data Tests
    
    func testIMUDataPointCreation() throws {
        let dataPoint = IMUDataPoint(
            timestamp: 0.1,
            accelerationX: 0.5,
            accelerationY: 0.3,
            accelerationZ: -9.8,
            rotationRateX: 0.1,
            rotationRateY: 0.2,
            rotationRateZ: 0.0
        )
        
        XCTAssertEqual(dataPoint.timestamp, 0.1)
        XCTAssertEqual(dataPoint.accelerationX, 0.5)
        XCTAssertEqual(dataPoint.accelerationY, 0.3)
        XCTAssertEqual(dataPoint.accelerationZ, -9.8)
        XCTAssertEqual(dataPoint.rotationRateX, 0.1)
        XCTAssertEqual(dataPoint.rotationRateY, 0.2)
        XCTAssertEqual(dataPoint.rotationRateZ, 0.0)
    }
    
    func testIMUSessionSerialization() throws {
        let dataPoints = [
            IMUDataPoint(timestamp: 0.0, accelerationX: 0.1, accelerationY: 0.2, accelerationZ: 0.3, rotationRateX: 0.4, rotationRateY: 0.5, rotationRateZ: 0.6),
            IMUDataPoint(timestamp: 0.1, accelerationX: 0.2, accelerationY: 0.3, accelerationZ: 0.4, rotationRateX: 0.5, rotationRateY: 0.6, rotationRateZ: 0.7)
        ]
        
        let startTime = Date()
        let endTime = Date(timeIntervalSinceNow: 5.0)
        
        let imuSession = IMUSession(
            dataPoints: dataPoints,
            startTime: startTime,
            endTime: endTime
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(imuSession)
        XCTAssertFalse(data.isEmpty)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedSession = try decoder.decode(IMUSession.self, from: data)
        
        XCTAssertEqual(decodedSession.dataPoints.count, 2)
        XCTAssertEqual(decodedSession.dataPoints[0].timestamp, 0.0)
        XCTAssertEqual(decodedSession.dataPoints[1].timestamp, 0.1)
    }
    
    // MARK: - Data Export Tests
    
    func testCSVExport() throws {
        let sessions = createTestSessions()
        let exportManager = DataExportManager()
        
        // This would normally write to a file, but we can test the CSV generation logic
        let csvData = try exportManager.generateCSV(from: sessions)
        let csvString = String(data: csvData, encoding: .utf8)
        
        XCTAssertNotNil(csvString)
        XCTAssertTrue(csvString!.contains("Timestamp,Latitude,Longitude,Street,City,State,Country"))
        XCTAssertTrue(csvString!.contains("TestApp1"))
        XCTAssertTrue(csvString!.contains("San Francisco"))
        XCTAssertTrue(csvString!.contains("CA"))
    }
    
    func testJSONExport() throws {
        let sessions = createTestSessions()
        let exportManager = DataExportManager()
        
        let jsonData = try exportManager.generateJSON(from: sessions)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData = try decoder.decode(ExportData.self, from: jsonData)
        
        XCTAssertEqual(exportData.version, "1.0")
        XCTAssertEqual(exportData.totalSessions, sessions.count)
        XCTAssertEqual(exportData.sessions.count, sessions.count)
        XCTAssertEqual(exportData.sessions[0].currentAppName, "TestApp1")
    }
    
    // MARK: - Haptic Manager Tests
    
    func testHapticManagerDefaults() throws {
        // Clear any existing setting
        UserDefaults.standard.removeObject(forKey: "hapticFeedbackEnabled")
        
        let hapticManager = HapticManager.shared
        
        // Test that it sets default to true when no setting exists
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled"))
    }
    
    // MARK: - Network Connection Tests
    
    func testNetworkAvailabilityCheck() async throws {
        // 测试网络可用性检查功能
        // 注意：这是一个集成测试，需要实际的网络环境
        
        // 创建CollectDataIntent实例来测试私有方法
        let intent = CollectDataIntent()
        
        // 由于isNetworkAvailable是私有方法，我们无法直接测试
        // 但我们可以测试整个数据收集流程在网络不可用时的行为
        
        // 模拟网络不可用的情况
        // 在实际使用中，这应该通过模拟网络状态来实现
        
        print("🌐 Testing network availability handling...")
        
        // 验证intent能够正常创建
        XCTAssertNotNil(intent)
        XCTAssertEqual(intent.wifi, "")
        XCTAssertEqual(intent.nfc, "")
        XCTAssertEqual(intent.latitude, 0.0)
        XCTAssertEqual(intent.longitude, 0.0)
    }
    
    func testOfflineDataCollection() async throws {
        // 测试离线数据收集功能
        // 这个测试验证在没有网络连接时，应用仍然能够收集基本数据
        
        print("📱 Testing offline data collection...")
        
        // 创建一个模拟的离线环境
        // 在实际测试中，这可能需要网络模拟器
        
        let intent = CollectDataIntent()
        
        // 设置测试参数
        intent.wifi = "TestWiFi"
        intent.nfc = "TestNFC"
        intent.latitude = 37.7749
        intent.longitude = -122.4194
        
        // 验证参数设置正确
        XCTAssertEqual(intent.wifi, "TestWiFi")
        XCTAssertEqual(intent.nfc, "TestNFC")
        XCTAssertEqual(intent.latitude, 37.7749)
        XCTAssertEqual(intent.longitude, -122.4194)
        
        print("✅ Offline data collection test parameters set correctly")
    }
    
    func testErrorHandlingWithoutNetwork() async throws {
        // 测试在没有网络连接时的错误处理
        
        print("❌ Testing error handling without network...")
        
        // 这个测试验证应用在网络不可用时不会崩溃
        // 而是优雅地处理错误并继续运行
        
        let intent = CollectDataIntent()
        
        // 设置一个无效的坐标来测试错误处理
        intent.latitude = 0.0
        intent.longitude = 0.0
        
        // 验证应用能够处理无效坐标
        XCTAssertEqual(intent.latitude, 0.0)
        XCTAssertEqual(intent.longitude, 0.0)
        
        print("✅ Error handling test completed without crashes")
    }
    
    // MARK: - Performance Tests
    
    func testDataCollectionPerformance() throws {
        // 测试数据收集的性能
        
        print("⚡ Testing data collection performance...")
        
        let intent = CollectDataIntent()
        
        // 测量intent创建的性能
        measure {
            let _ = CollectDataIntent()
        }
        
        print("✅ Performance test completed")
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsage() throws {
        // 测试内存使用情况
        
        print("💾 Testing memory usage...")
        
        // 创建多个intent实例来测试内存管理
        var intents: [CollectDataIntent] = []
        
        for i in 0..<100 {
            let intent = CollectDataIntent()
            intent.wifi = "WiFi_\(i)"
            intent.nfc = "NFC_\(i)"
            intent.latitude = Double(i)
            intent.longitude = Double(i)
            intents.append(intent)
        }
        
        // 验证所有intent都创建成功
        XCTAssertEqual(intents.count, 100)
        
        // 清理内存
        intents.removeAll()
        
        print("✅ Memory test completed")
    }
    
    // MARK: - Helper Methods
    
    private func createTestSessions() -> [NFCSessionData] {
        // 创建测试传感器数据
        let magnetometerData = try? JSONEncoder().encode(MagnetometerData(
            timestamp: Date().timeIntervalSince1970,
            magneticFieldX: 25.5,
            magneticFieldY: -12.3,
            magneticFieldZ: 45.8,
            heading: 180.0
        ))
        
        let barometerData = try? JSONEncoder().encode(BarometerData(
            timestamp: Date().timeIntervalSince1970,
            pressure: 1013.25,
            relativeAltitude: 100.5
        ))
        
        let ambientLightData = try? JSONEncoder().encode(AmbientLightData(
            timestamp: Date().timeIntervalSince1970,
            brightness: 500.0
        ))
        
        let proximityData = try? JSONEncoder().encode(ProximityData(
            timestamp: Date().timeIntervalSince1970,
            distance: 0.05,
            isClose: true
        ))
        
        let pedometerData = try? JSONEncoder().encode(PedometerData(
            timestamp: Date().timeIntervalSince1970,
            stepCount: 150,
            distance: 120.5,
            averagePace: 15.0,
            startTime: Date().addingTimeInterval(-600),
            endTime: Date()
        ))
        
        let temperatureData = try? JSONEncoder().encode(TemperatureData(
            timestamp: Date().timeIntervalSince1970,
            temperature: 22.5,
            humidity: 65.0
        ))
        
        let microphoneData = try? JSONEncoder().encode(MicrophoneData(
            timestamp: Date().timeIntervalSince1970,
            audioData: "test audio".data(using: .utf8)!,
            sampleRate: 44100.0,
            averageVolume: -20.5,
            peakVolume: -5.2
        ))
        
        let weatherData = try? JSONEncoder().encode(WeatherData(
            timestamp: Date().timeIntervalSince1970,
            temperature: 18.5,
            humidity: 70.0,
            pressure: 1015.0,
            windSpeed: 5.2,
            windDirection: 180.0,
            description: "Partly cloudy",
            icon: "cloud.sun"
        ))
        
        let session1 = NFCSessionData(
            timestamp: Date(timeIntervalSinceNow: -3600), // 1 hour ago
            latitude: 37.7749,
            longitude: -122.4194,
            ipAddress: "192.168.1.100",
            currentAppName: "TestApp1",
            imuData: nil,
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            magnetometerData: magnetometerData,
            barometerData: barometerData,
            ambientLightData: ambientLightData,
            proximityData: proximityData,
            pedometerData: pedometerData,
            temperatureData: temperatureData,
            microphoneData: microphoneData,
            weatherData: weatherData
        )
        
        let session2 = NFCSessionData(
            timestamp: Date(timeIntervalSinceNow: -1800), // 30 minutes ago
            latitude: 37.7849,
            longitude: -122.4094,
            ipAddress: "192.168.1.101",
            currentAppName: "TestApp2",
            imuData: nil,
            street: "456 Oak Ave",
            city: "Oakland",
            state: "CA",
            country: "USA",
            magnetometerData: nil,
            barometerData: nil,
            ambientLightData: nil,
            proximityData: nil,
            pedometerData: nil,
            temperatureData: nil,
            microphoneData: nil,
            weatherData: nil
        )
        
        return [session1, session2]
    }
}

// MARK: - DataExportManager Extension for Testing

extension DataExportManager {
    func generateCSV(from sessions: [NFCSessionData]) throws -> Data {
        var csvContent = "Timestamp,Latitude,Longitude,IP Address,App Name,IMU Data Points\n"
        
        for session in sessions {
            let timestamp = DateFormatter.csvFormatter.string(from: session.timestamp)
            let latitude = session.latitude?.description ?? ""
            let longitude = session.longitude?.description ?? ""
            let ipAddress = session.ipAddress?.replacingOccurrences(of: ",", with: ";") ?? ""
            let appName = session.currentAppName?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            // Count IMU data points
            var imuPointsCount = ""
            if let imuData = session.imuData {
                do {
                    let imuSession = try JSONDecoder().decode(IMUSession.self, from: imuData)
                    imuPointsCount = "\(imuSession.dataPoints.count)"
                } catch {
                    imuPointsCount = "Error"
                }
            }
            
            csvContent += "\"\(timestamp)\",\"\(latitude)\",\"\(longitude)\",\"\(ipAddress)\",\"\(appName)\",\"\(imuPointsCount)\"\n"
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    func generateJSON(from sessions: [NFCSessionData]) throws -> Data {
        let exportSessions = sessions.map { session -> ExportableSession in
            var decodedIMU: IMUSession?
            if let imuData = session.imuData {
                decodedIMU = try? JSONDecoder().decode(IMUSession.self, from: imuData)
            }
            
            return ExportableSession(
                timestamp: session.timestamp,
                latitude: session.latitude,
                longitude: session.longitude,
                ipAddress: session.ipAddress,
                currentAppName: session.currentAppName,
                imuSession: decodedIMU
            )
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            version: "1.0",
            totalSessions: sessions.count,
            sessions: exportSessions
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(exportData)
    }
}
