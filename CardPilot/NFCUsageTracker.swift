//
//  NFCUsageTracker.swift
//  CardPilot
//
//  Track NFC card usage time and frequency
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class NFCUsageRecord {
    var timestamp: Date
    var latitude: Double?
    var longitude: Double?
    var ipAddress: String?
    var triggerSource: String // "shortcuts", "manual", "nfc_detected"
    var usageType: NFCUsageType
    var deviceMotionData: Data? // Quick motion snapshot
    var sessionDuration: TimeInterval? // How long the NFC interaction lasted
    var nfcUID: String? // NFC card UID for real NFC triggers
    
    init(timestamp: Date = Date(),
         latitude: Double? = nil,
         longitude: Double? = nil,
         ipAddress: String? = nil,
         triggerSource: String = "unknown",
         usageType: NFCUsageType = .unknown,
         deviceMotionData: Data? = nil,
         sessionDuration: TimeInterval? = nil,
         nfcUID: String? = nil) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.ipAddress = ipAddress
        self.triggerSource = triggerSource
        self.usageType = usageType
        self.deviceMotionData = deviceMotionData
        self.sessionDuration = sessionDuration
        self.nfcUID = nfcUID
    }
    
    var locationString: String {
        if let lat = latitude, let lon = longitude {
            return "\(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))"
        }
        return "位置未知"
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

enum NFCUsageType: String, CaseIterable, Codable {
    case payment = "支付"
    case transport = "交通卡"
    case access = "门禁卡"
    case identification = "身份识别"
    case unknown = "未知类型"
    
    var icon: String {
        switch self {
        case .payment: return "creditcard"
        case .transport: return "bus"
        case .access: return "key"
        case .identification: return "person.badge.key"
        case .unknown: return "questionmark.circle"
        }
    }
}

@MainActor
class NFCUsageTracker: ObservableObject {
    @Published var isTracking = false
    @Published var lastUsageRecord: NFCUsageRecord?
    @Published var recentUsages: [NFCUsageRecord] = []
    @Published var dailyUsageCount: Int = 0
    
    private let locationManager = LocationManager()
    private let networkManager = NetworkManager()
    private let motionManager = MotionManager()
    
    // MARK: - Usage Tracking
    
    func recordNFCUsage(
        usageType: NFCUsageType = .unknown,
        triggerSource: String = "manual",
        nfcUID: String? = nil,
        modelContext: ModelContext
    ) async {
        isTracking = true
        
        let startTime = Date()
        
        // 并发收集数据
        async let locationTask = locationManager.getCurrentLocation()
        async let ipTask = networkManager.getCurrentIPAddress()
        async let motionTask = captureQuickMotionSnapshot()
        
        let (location, ipAddress, motionData) = await (locationTask, ipTask, motionTask)
        
        let endTime = Date()
        let sessionDuration = endTime.timeIntervalSince(startTime)
        
        let usageRecord = NFCUsageRecord(
            timestamp: startTime,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            ipAddress: ipAddress,
            triggerSource: triggerSource,
            usageType: usageType,
            deviceMotionData: motionData,
            sessionDuration: sessionDuration,
            nfcUID: nfcUID
        )
        
        // 保存记录
        modelContext.insert(usageRecord)
        
        do {
            try modelContext.save()
            lastUsageRecord = usageRecord
            await updateUsageStatistics(modelContext: modelContext)
            print("✅ NFC使用记录已保存: \(usageType.rawValue)")
        } catch {
            print("❌ 保存NFC使用记录失败: \(error)")
        }
        
        isTracking = false
    }
    
    // MARK: - Quick Motion Snapshot
    
    private func captureQuickMotionSnapshot() async -> Data? {
        // 捕获1秒的运动数据快照
        return await withCheckedContinuation { continuation in
            var hasResumed = false // 防止多次恢复continuation
            
            motionManager.captureQuickSnapshot(duration: 1.0) { data in
                // 防止多次恢复continuation
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: data)
            }
        }
    }
    
    // MARK: - Usage Statistics
    
    func updateUsageStatistics(modelContext: ModelContext) async {
        // 获取今日使用次数
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<NFCUsageRecord>(
            predicate: #Predicate<NFCUsageRecord> { record in
                record.timestamp >= today && record.timestamp < tomorrow
            }
        )
        
        do {
            let todayRecords = try modelContext.fetch(descriptor)
            dailyUsageCount = todayRecords.count
            
            // 获取最近的使用记录
            var recentDescriptor = FetchDescriptor<NFCUsageRecord>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            recentDescriptor.fetchLimit = 10
            
            recentUsages = try modelContext.fetch(recentDescriptor)
        } catch {
            print("获取使用统计失败: \(error)")
        }
    }
    
    // MARK: - Usage Analytics
    
    func getUsageAnalytics(modelContext: ModelContext, days: Int = 7) -> NFCUsageAnalytics {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        let descriptor = FetchDescriptor<NFCUsageRecord>(
            predicate: #Predicate<NFCUsageRecord> { record in
                record.timestamp >= startDate
            }
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            return NFCUsageAnalytics(records: records, days: days)
        } catch {
            print("获取使用分析失败: \(error)")
            return NFCUsageAnalytics(records: [], days: days)
        }
    }
}

// MARK: - Analytics Data Structure

struct NFCUsageAnalytics {
    let totalUsages: Int
    let averageUsagesPerDay: Double
    let mostUsedType: NFCUsageType
    let mostActiveHour: Int
    let usagesByType: [NFCUsageType: Int]
    let dailyUsages: [Date: Int]
    
    init(records: [NFCUsageRecord], days: Int) {
        totalUsages = records.count
        averageUsagesPerDay = days > 0 ? Double(totalUsages) / Double(days) : 0
        
        // 按类型统计
        usagesByType = Dictionary(grouping: records, by: \.usageType)
            .mapValues { $0.count }
        
        mostUsedType = usagesByType.max(by: { $0.value < $1.value })?.key ?? .unknown
        
        // 按小时统计
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "HH"
        let hourUsages = Dictionary(grouping: records) { record in
            Int(hourFormatter.string(from: record.timestamp)) ?? 0
        }.mapValues { $0.count }
        
        mostActiveHour = hourUsages.max(by: { $0.value < $1.value })?.key ?? 12
        
        // 按日期统计
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dailyUsages = Dictionary(grouping: records) { record in
            dayFormatter.date(from: dayFormatter.string(from: record.timestamp)) ?? Date()
        }.mapValues { $0.count }
    }
}

// MARK: - Motion Manager Extension

extension MotionManager {
    func captureQuickSnapshot(duration: TimeInterval, completion: @escaping (Data?) -> Void) {
        // 快速捕获运动数据快照
        guard isMotionAvailable() else {
            completion(nil)
            return
        }
        
        var dataPoints: [IMUDataPoint] = []
        let startTime = Date()
        var hasCompleted = false // 防止多次调用completion
        
        startMotionUpdates { [weak self] data in
            guard let self = self, let motionData = data else { return }
            
            let dataPoint = IMUDataPoint(
                timestamp: Date().timeIntervalSince(startTime),
                accelerationX: motionData.userAcceleration.x,
                accelerationY: motionData.userAcceleration.y,
                accelerationZ: motionData.userAcceleration.z,
                rotationRateX: motionData.rotationRate.x,
                rotationRateY: motionData.rotationRate.y,
                rotationRateZ: motionData.rotationRate.z
            )
            
            dataPoints.append(dataPoint)
            
            if Date().timeIntervalSince(startTime) >= duration {
                self.stopMotionUpdates()
                
                // 防止多次调用completion
                guard !hasCompleted else { return }
                hasCompleted = true
                
                let snapshot = IMUSession(
                    dataPoints: dataPoints,
                    startTime: startTime,
                    endTime: Date()
                )
                
                do {
                    let data = try JSONEncoder().encode(snapshot)
                    completion(data)
                } catch {
                    completion(nil)
                }
            }
        }
        
        // 超时保护
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1.0) { [weak self] in
            self?.stopMotionUpdates()
            
            // 防止多次调用completion
            guard !hasCompleted else { return }
            hasCompleted = true
            
            if !dataPoints.isEmpty {
                let snapshot = IMUSession(
                    dataPoints: dataPoints,
                    startTime: startTime,
                    endTime: Date()
                )
                do {
                    let data = try JSONEncoder().encode(snapshot)
                    completion(data)
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
}
