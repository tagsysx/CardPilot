//
//  DataPersistenceManager.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import Foundation
import SwiftData
import SwiftUI

class DataPersistenceManager: ObservableObject {
    static let shared = DataPersistenceManager()
    
    // File目录路径
    private let fileDirectory: URL
    private let dataFileName = "CardPilot_Data.json"
    private let backupDirectoryName = "CardPilot_Backups"
    
    private init() {
        // 获取Documents目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileDirectory = documentsPath
        
        // 创建备份目录
        createBackupDirectoryIfNeeded()
    }
    
    // MARK: - 备份目录管理
    
    private func createBackupDirectoryIfNeeded() {
        let backupPath = fileDirectory.appendingPathComponent(backupDirectoryName)
        
        do {
            if !FileManager.default.fileExists(atPath: backupPath.path) {
                try FileManager.default.createDirectory(at: backupPath, withIntermediateDirectories: true, attributes: nil)
                print("✅ Created backup directory: \(backupPath.path)")
            }
        } catch {
            print("❌ Failed to create backup directory: \(error)")
        }
    }
    
    // MARK: - 数据备份到File目录
    
    func backupDataToFile(_ sessions: [NFCSessionData], progressCallback: ((String) -> Void)? = nil) async -> Bool {
        print("🔄 Starting data backup process...")
        print("📊 Total sessions to backup: \(sessions.count)")
        
        progressCallback?("🔄 Starting backup process...")
        
        // 检查输入数据
        guard !sessions.isEmpty else {
            print("❌ No sessions to backup")
            progressCallback?("❌ No sessions to backup")
            return false
        }
        
        // 检查文件访问权限
        guard checkFileAccessPermissions() else {
            print("❌ File access permissions not available")
            progressCallback?("❌ File access permissions not available")
            return false
        }
        
        progressCallback?("✅ File permissions verified")
        
        do {
            progressCallback?("📊 Creating backup data structure...")
            
            // 创建备份数据结构
            let backupData = BackupData(
                timestamp: Date(),
                version: "1.4",
                totalSessions: sessions.count,
                sessions: sessions.map { session in
                    BackupSession(
                        timestamp: session.timestamp,
                        latitude: session.latitude,
                        longitude: session.longitude,
                        ipAddress: session.ipAddress,
                        wifiSSID: session.wifiSSID,
                        currentAppName: session.currentAppName,
                        nfcTagData: session.nfcTagData,
                        nfcUsageType: session.nfcUsageType,
                        nfcTriggerSource: session.nfcTriggerSource,
                        nfcSessionDuration: session.nfcSessionDuration,
                        screenState: session.screenState,
                        screenBrightness: session.screenBrightness,
                        street: session.street,
                        city: session.city,
                        state: session.state,
                        country: session.country,
                        postalCode: session.postalCode,
                        administrativeArea: session.administrativeArea,
                        subLocality: session.subLocality,
                        locationTag: session.locationTag,
                        imuData: session.imuData,
                        magnetometerData: session.magnetometerData,
                        barometerData: session.barometerData,
                        ambientLightData: session.ambientLightData,
                        proximityData: session.proximityData,
                        pedometerData: session.pedometerData,
                        temperatureData: session.temperatureData,
                        microphoneData: session.microphoneData,
                        weatherData: session.weatherData,
                        screenStateHistory: session.screenStateHistory
                    )
                }
            )
            
            print("✅ Backup data structure created successfully")
            progressCallback?("✅ Backup data structure created")
            
            // 编码为JSON
            progressCallback?("🔄 Encoding data to JSON...")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let jsonData = try encoder.encode(backupData)
            print("✅ JSON encoding completed, data size: \(ByteCountFormatter.string(fromByteCount: Int64(jsonData.count), countStyle: .file))")
            progressCallback?("✅ JSON encoding completed (\(ByteCountFormatter.string(fromByteCount: Int64(jsonData.count), countStyle: .file)))")
            
            // 保存到File目录
            progressCallback?("💾 Saving main backup file...")
            let fileURL = fileDirectory.appendingPathComponent(dataFileName)
            try jsonData.write(to: fileURL)
            print("✅ Main backup file saved to: \(fileURL.path)")
            progressCallback?("✅ Main backup file saved")
            
            // 创建带时间戳的备份文件
            progressCallback?("📁 Creating timestamped backup...")
            let timestamp = DateFormatter.fileNameFormatter.string(from: Date())
            let backupFileName = "CardPilot_Backup_\(timestamp).json"
            let backupURL = fileDirectory.appendingPathComponent(backupDirectoryName).appendingPathComponent(backupFileName)
            try jsonData.write(to: backupURL)
            print("✅ Timestamped backup file saved to: \(backupURL.path)")
            progressCallback?("✅ Timestamped backup created")
            
            // 验证文件是否真的被创建
            progressCallback?("🔍 Verifying files...")
            let mainFileExists = FileManager.default.fileExists(atPath: fileURL.path)
            let backupFileExists = FileManager.default.fileExists(atPath: backupURL.path)
            
            if mainFileExists && backupFileExists {
                print("✅ File verification successful")
                print("📁 Main file: \(fileURL.path)")
                print("📁 Backup file: \(backupURL.path)")
                print("📊 Total backup size: \(ByteCountFormatter.string(fromByteCount: Int64(jsonData.count), countStyle: .file))")
                progressCallback?("✅ Backup completed successfully!")
                return true
            } else {
                print("❌ File verification failed")
                print("Main file exists: \(mainFileExists)")
                print("Backup file exists: \(backupFileExists)")
                progressCallback?("❌ File verification failed")
                return false
            }
            
        } catch {
            print("❌ Failed to backup data to File directory: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
            progressCallback?("❌ Backup failed: \(error.localizedDescription)")
            
            // 提供更详细的错误信息
            if let encodingError = error as? EncodingError {
                print("🔍 Encoding error: \(encodingError)")
                progressCallback?("❌ Data encoding error")
            } else if let fileError = error as? CocoaError {
                print("🔍 File system error: \(fileError)")
                print("🔍 Error code: \(fileError.code.rawValue)")
                progressCallback?("❌ File system error (code: \(fileError.code.rawValue))")
            }
            
            return false
        }
    }
    
    // MARK: - 文件权限检查
    
    private func checkFileAccessPermissions() -> Bool {
        print("🔍 Checking file access permissions...")
        
        // 检查Documents目录是否可写
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let testFileURL = documentsPath.appendingPathComponent("test_permissions.tmp")
        
        do {
            // 尝试创建测试文件
            try "test".write(to: testFileURL, atomically: true, encoding: .utf8)
            
            // 尝试删除测试文件
            try FileManager.default.removeItem(at: testFileURL)
            
            print("✅ File access permissions verified")
            return true
            
        } catch {
            print("❌ File access permission check failed: \(error)")
            return false
        }
    }
    
    // MARK: - 从File目录恢复数据
    
    func restoreDataFromFile(fileURL: URL? = nil, progressCallback: ((String) -> Void)? = nil) async -> Bool {
        print("🔄 Starting data restoration process...")
        progressCallback?("🔄 Starting data restoration...")
        
        do {
            progressCallback?("📁 Checking backup file...")
            
            // 使用提供的fileURL或默认的备份文件
            let targetURL: URL
            if let fileURL = fileURL {
                targetURL = fileURL
                print("📁 Using user-selected file: \(fileURL.path)")
            } else {
                targetURL = fileDirectory.appendingPathComponent(dataFileName)
                print("📁 Using default backup file: \(targetURL.path)")
            }
            
            guard FileManager.default.fileExists(atPath: targetURL.path) else {
                print("⚠️ No backup file found at: \(targetURL.path)")
                progressCallback?("❌ No backup file found")
                return false
            }
            
            progressCallback?("📖 Reading backup file...")
            let jsonData = try Data(contentsOf: targetURL)
            print("✅ Backup file read successfully, size: \(ByteCountFormatter.string(fromByteCount: Int64(jsonData.count), countStyle: .file))")
            progressCallback?("✅ Backup file read (\(ByteCountFormatter.string(fromByteCount: Int64(jsonData.count), countStyle: .file)))")
            
            progressCallback?("🔄 Decoding backup data...")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let backupData = try decoder.decode(BackupData.self, from: jsonData)
            print("✅ Successfully decoded backup data with \(backupData.sessions.count) sessions")
            progressCallback?("✅ Data decoded (\(backupData.sessions.count) sessions)")
            
            progressCallback?("💾 Restoring sessions to database...")
            
            // 转换为NFCSessionData对象
            let restoredSessions = backupData.sessions.map { backupSession in
                let session = NFCSessionData()
                session.timestamp = backupSession.timestamp
                session.latitude = backupSession.latitude
                session.longitude = backupSession.longitude
                session.ipAddress = backupSession.ipAddress
                session.wifiSSID = backupSession.wifiSSID
                session.currentAppName = backupSession.currentAppName
                session.nfcTagData = backupSession.nfcTagData
                session.nfcUsageType = backupSession.nfcUsageType
                session.nfcTriggerSource = backupSession.nfcTriggerSource
                session.nfcSessionDuration = backupSession.nfcSessionDuration
                session.screenState = backupSession.screenState
                session.screenBrightness = backupSession.screenBrightness
                session.street = backupSession.street
                session.city = backupSession.city
                session.state = backupSession.state
                session.country = backupSession.country
                session.postalCode = backupSession.postalCode
                session.administrativeArea = backupSession.administrativeArea
                session.subLocality = backupSession.subLocality
                session.locationTag = backupSession.locationTag
                session.imuData = backupSession.imuData
                session.magnetometerData = backupSession.magnetometerData
                session.barometerData = backupSession.barometerData
                session.ambientLightData = backupSession.ambientLightData
                session.proximityData = backupSession.proximityData
                session.pedometerData = backupSession.pedometerData
                session.temperatureData = backupSession.temperatureData
                session.microphoneData = backupSession.microphoneData
                session.weatherData = backupSession.weatherData
                session.screenStateHistory = backupSession.screenStateHistory
                
                return session
            }
            
            progressCallback?("✅ Data restoration completed successfully!")
            print("✅ Successfully restored \(restoredSessions.count) sessions")
            
            return true
            
        } catch {
            print("❌ Failed to restore data from File directory: \(error)")
            progressCallback?("❌ Restoration failed: \(error.localizedDescription)")
            
            // 提供更详细的错误信息
            if let decodingError = error as? DecodingError {
                print("🔍 Decoding error: \(decodingError)")
                progressCallback?("❌ Data decoding error")
            } else if let fileError = error as? CocoaError {
                print("🔍 File system error: \(fileError)")
                progressCallback?("❌ File system error (code: \(fileError.code.rawValue))")
            }
            
            return false
        }
    }
    
    // MARK: - 检查备份文件状态
    
    func getBackupStatus() -> BackupStatus {
        let mainFileURL = fileDirectory.appendingPathComponent(dataFileName)
        let backupDirURL = fileDirectory.appendingPathComponent(backupDirectoryName)
        
        let mainFileExists = FileManager.default.fileExists(atPath: mainFileURL.path)
        let backupDirExists = FileManager.default.fileExists(atPath: backupDirURL.path)
        
        var backupFiles: [BackupFileInfo] = []
        
        if backupDirExists {
            do {
                let backupContents = try FileManager.default.contentsOfDirectory(at: backupDirURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
                
                backupFiles = backupContents.compactMap { url in
                    guard url.pathExtension == "json" else { return nil }
                    
                    do {
                        let attributes = try url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                        let creationDate = attributes.creationDate ?? Date()
                        let fileSize = attributes.fileSize ?? 0
                        
                        return BackupFileInfo(
                            name: url.lastPathComponent,
                            creationDate: creationDate,
                            fileSize: fileSize,
                            url: url
                        )
                    } catch {
                        return nil
                    }
                }.sorted { $0.creationDate > $1.creationDate }
            } catch {
                print("⚠️ Failed to read backup directory: \(error)")
            }
        }
        
        return BackupStatus(
            mainFileExists: mainFileExists,
            backupDirectoryExists: backupDirExists,
            backupFiles: backupFiles,
            mainFileURL: mainFileURL,
            backupDirectoryURL: backupDirURL
        )
    }
    
    // MARK: - 清理旧备份文件
    
    func cleanupOldBackups(keepLast: Int = 10) {
        let backupDirURL = fileDirectory.appendingPathComponent(backupDirectoryName)
        
        guard FileManager.default.fileExists(atPath: backupDirURL.path) else { return }
        
        do {
            let backupContents = try FileManager.default.contentsOfDirectory(at: backupDirURL, includingPropertiesForKeys: [.creationDateKey])
            
            let sortedFiles = backupContents.compactMap { url -> (URL, Date)? in
                guard url.pathExtension == "json" else { return nil }
                
                do {
                    let attributes = try url.resourceValues(forKeys: [.creationDateKey])
                    let creationDate = attributes.creationDate ?? Date()
                    return (url, creationDate)
                } catch {
                    return nil
                }
            }.sorted { $0.1 > $1.1 }
            
            // 删除多余的备份文件
            if sortedFiles.count > keepLast {
                let filesToDelete = sortedFiles[keepLast...]
                
                for (url, _) in filesToDelete {
                    try FileManager.default.removeItem(at: url)
                    print("🗑️ Deleted old backup: \(url.lastPathComponent)")
                }
                
                print("✅ Cleaned up \(filesToDelete.count) old backup files")
            }
            
        } catch {
            print("❌ Failed to cleanup old backups: \(error)")
        }
    }
    
    // MARK: - 导出备份文件到其他应用
    
    func exportBackupFile() -> URL? {
        let fileURL = fileDirectory.appendingPathComponent(dataFileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("⚠️ No backup file to export")
            return nil
        }
        
        return fileURL
    }
}

// MARK: - 备份数据结构

struct BackupData: Codable {
    let timestamp: Date
    let version: String
    let totalSessions: Int
    let sessions: [BackupSession]
}

struct BackupSession: Codable {
    let timestamp: Date
    let latitude: Double?
    let longitude: Double?
    let ipAddress: String?
    let wifiSSID: String?
    let currentAppName: String?
    let nfcTagData: String?
    let nfcUsageType: String?
    let nfcTriggerSource: String?
    let nfcSessionDuration: TimeInterval?
    let screenState: String?
    let screenBrightness: Double?
    let street: String?
    let city: String?
    let state: String?
    let country: String?
    let postalCode: String?
    let administrativeArea: String?
    let subLocality: String?
    let locationTag: String?
    let imuData: Data?
    let magnetometerData: Data?
    let barometerData: Data?
    let ambientLightData: Data?
    let proximityData: Data?
    let pedometerData: Data?
    let temperatureData: Data?
    let microphoneData: Data?
    let weatherData: Data?
    let screenStateHistory: Data?
}

// MARK: - 备份状态信息

struct BackupStatus {
    let mainFileExists: Bool
    let backupDirectoryExists: Bool
    let backupFiles: [BackupFileInfo]
    let mainFileURL: URL
    let backupDirectoryURL: URL
    
    var totalBackupFiles: Int {
        return backupFiles.count
    }
    
    var latestBackupDate: Date? {
        return backupFiles.first?.creationDate
    }
    
    var totalBackupSize: Int64 {
        return backupFiles.reduce(0) { $0 + Int64($1.fileSize) }
    }
}

struct BackupFileInfo {
    let name: String
    let creationDate: Date
    let fileSize: Int
    let url: URL
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}


