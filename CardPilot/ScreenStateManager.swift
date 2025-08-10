import Foundation
import UIKit
import Combine

@MainActor
class ScreenStateManager: ObservableObject {
    @Published var isScreenOn: Bool = true
    @Published var lastScreenStateChange: Date = Date()
    @Published var screenStateHistory: [ScreenStateEvent] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let maxHistorySize = 1000 // 最多保存1000条记录
    
    init() {
        setupScreenStateMonitoring()
        // 初始化时获取当前屏幕状态
        updateCurrentScreenState()
    }
    
    // MARK: - Screen State Monitoring
    
    private func setupScreenStateMonitoring() {
        // 监听屏幕状态变化通知
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleScreenStateChange(isOn: true, reason: "app_became_active")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleScreenStateChange(isOn: false, reason: "app_will_resign_active")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleScreenStateChange(isOn: false, reason: "app_entered_background")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleScreenStateChange(isOn: true, reason: "app_will_enter_foreground")
            }
            .store(in: &cancellables)
        
        // 监听系统屏幕状态变化
        NotificationCenter.default.publisher(for: UIScreen.brightnessDidChangeNotification)
            .sink { [weak self] _ in
                self?.handleBrightnessChange()
            }
            .store(in: &cancellables)
    }
    
    private func handleScreenStateChange(isOn: Bool, reason: String) {
        let now = Date()
        
        // 更新当前状态
        isScreenOn = isOn
        lastScreenStateChange = now
        
        // 记录状态变化事件
        let event = ScreenStateEvent(
            timestamp: now,
            isScreenOn: isOn,
            reason: reason,
            brightness: UIScreen.main.brightness
        )
        
        addToHistory(event)
        
        // 发送通知给其他组件
        NotificationCenter.default.post(
            name: NSNotification.Name("ScreenStateChanged"),
            object: nil,
            userInfo: [
                "isScreenOn": isOn,
                "reason": reason,
                "timestamp": now
            ]
        )
    }
    
    private func handleBrightnessChange() {
        let brightness = UIScreen.main.brightness
        
        // 如果亮度为0，可能是屏幕关闭
        if brightness == 0 && isScreenOn {
            handleScreenStateChange(isOn: false, reason: "brightness_zero")
        } else if brightness > 0 && !isScreenOn {
            // 亮度恢复，屏幕可能重新开启
            handleScreenStateChange(isOn: true, reason: "brightness_restored")
        }
    }
    
    private func updateCurrentScreenState() {
        // 获取当前屏幕状态
        let brightness = UIScreen.main.brightness
        let appState = UIApplication.shared.applicationState
        
        let currentIsOn = brightness > 0 && appState == .active
        isScreenOn = currentIsOn
        
        // 记录初始状态
        let event = ScreenStateEvent(
            timestamp: Date(),
            isScreenOn: currentIsOn,
            reason: "initial_state",
            brightness: brightness
        )
        addToHistory(event)
    }
    
    // MARK: - History Management
    
    private func addToHistory(_ event: ScreenStateEvent) {
        screenStateHistory.append(event)
        
        // 限制历史记录数量
        if screenStateHistory.count > maxHistorySize {
            screenStateHistory.removeFirst(screenStateHistory.count - maxHistorySize)
        }
    }
    
    // MARK: - Public Methods
    
    /// 获取屏幕状态二进制指示器
    func getScreenStateIndicator() -> ScreenStateIndicator {
        let now = Date()
        let calendar = Calendar.current
        
        // 获取最近24小时的屏幕状态变化
        let last24Hours = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let recentEvents = screenStateHistory.filter { $0.timestamp >= last24Hours }
        
        // 计算屏幕开启和关闭的时间
        var totalOnTime: TimeInterval = 0
        var totalOffTime: TimeInterval = 0
        
        for i in 0..<recentEvents.count {
            let currentEvent = recentEvents[i]
            let nextEvent = i < recentEvents.count - 1 ? recentEvents[i + 1] : nil
            
            let duration: TimeInterval
            if let next = nextEvent {
                duration = next.timestamp.timeIntervalSince(currentEvent.timestamp)
            } else {
                duration = now.timeIntervalSince(currentEvent.timestamp)
            }
            
            if currentEvent.isScreenOn {
                totalOnTime += duration
            } else {
                totalOffTime += duration
            }
        }
        
        // 计算使用率
        let totalTime = totalOnTime + totalOffTime
        let usageRate = totalTime > 0 ? totalOnTime / totalTime : 0
        
        return ScreenStateIndicator(
            isCurrentlyOn: isScreenOn,
            lastChangeTime: lastScreenStateChange,
            totalOnTime24h: totalOnTime,
            totalOffTime24h: totalOffTime,
            usageRate24h: usageRate,
            stateChanges24h: recentEvents.count,
            currentBrightness: UIScreen.main.brightness
        )
    }
    
    /// 清除历史记录
    func clearHistory() {
        screenStateHistory.removeAll()
    }
    
    /// 导出屏幕状态数据
    func exportScreenStateData() -> String {
        var csv = "Timestamp,IsScreenOn,Reason,Brightness\n"
        
        for event in screenStateHistory {
            let timestamp = ISO8601DateFormatter().string(from: event.timestamp)
            let isOn = event.isScreenOn ? "1" : "0"
            let reason = event.reason
            let brightness = String(format: "%.2f", event.brightness)
            
            csv += "\(timestamp),\(isOn),\(reason),\(brightness)\n"
        }
        
        return csv
    }
}

// MARK: - Data Models

struct ScreenStateEvent: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let isScreenOn: Bool
    let reason: String
    let brightness: CGFloat
    
    enum CodingKeys: String, CodingKey {
        case timestamp, isScreenOn, reason, brightness
    }
    
    init(timestamp: Date, isScreenOn: Bool, reason: String, brightness: CGFloat) {
        self.timestamp = timestamp
        self.isScreenOn = isScreenOn
        self.reason = reason
        self.brightness = brightness
    }
}

struct ScreenStateIndicator: Codable {
    let isCurrentlyOn: Bool
    let lastChangeTime: Date
    let totalOnTime24h: TimeInterval
    let totalOffTime24h: TimeInterval
    let usageRate24h: Double
    let stateChanges24h: Int
    let currentBrightness: CGFloat
    
    // 二进制指示器：1表示屏幕开启，0表示屏幕关闭
    var binaryIndicator: String {
        return isCurrentlyOn ? "1" : "0"
    }
    
    // 24小时使用模式（每小时的二进制状态）
    var hourlyPattern24h: [String] {
        // 这里可以实现更复杂的24小时模式分析
        // 暂时返回简单的当前状态
        return Array(repeating: binaryIndicator, count: 24)
    }
    
    // 格式化时间显示
    var formattedOnTime24h: String {
        let hours = Int(totalOnTime24h) / 3600
        let minutes = Int(totalOnTime24h) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    var formattedOffTime24h: String {
        let hours = Int(totalOffTime24h) / 3600
        let minutes = Int(totalOffTime24h) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    var formattedUsageRate: String {
        return String(format: "%.1f%%", usageRate24h * 100)
    }
}
