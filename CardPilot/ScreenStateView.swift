import SwiftUI
import Charts

struct ScreenStateView: View {
    @StateObject private var screenStateManager = ScreenStateManager()
    @State private var showingExportSheet = false
    @State private var exportData = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 当前状态卡片
                    currentStatusCard
                    
                    // 24小时统计卡片
                    statisticsCard
                    
                    // 状态变化历史
                    historySection
                    
                    // 二进制指示器
                    binaryIndicatorSection
                }
                .padding()
            }
            .navigationTitle("Screen State")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Data", systemImage: "square.and.arrow.up") {
                            exportScreenStateData()
                        }
                        
                        Button("Clear History", systemImage: "trash", role: .destructive) {
                            screenStateManager.clearHistory()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportSheet(data: exportData, filename: "screen_state_data.csv")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScreenStateChanged"))) { _ in
                // 屏幕状态变化时刷新视图
            }
        }
    }
    
    // MARK: - Current Status Card
    
    private var currentStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: screenStateManager.isScreenOn ? "display" : "display.slash")
                    .font(.title)
                    .foregroundColor(screenStateManager.isScreenOn ? .green : .red)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(screenStateManager.isScreenOn ? "Screen On" : "Screen Off")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(screenStateManager.isScreenOn ? .green : .red)
                    
                    Text("State Change Time: \(screenStateManager.lastScreenStateChange.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 二进制指示器
                Text(screenStateManager.isScreenOn ? "1" : "0")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(screenStateManager.isScreenOn ? .green : .red)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(screenStateManager.isScreenOn ? .green.opacity(0.2) : .red.opacity(0.2))
                    )
            }
            
            // 当前亮度
            HStack {
                Image(systemName: "sun.max")
                    .foregroundColor(.orange)
                
                Text("Current Brightness: \(Int(UIScreen.main.brightness * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ProgressView(value: UIScreen.main.brightness)
                    .frame(width: 100)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Statistics Card
    
    private var statisticsCard: some View {
        let indicator = screenStateManager.getScreenStateIndicator()
        
        return VStack(spacing: 16) {
            Text("24-Hour Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatItem(
                    title: "开启时间",
                    value: indicator.formattedOnTime24h,
                    icon: "display",
                    color: .green
                )
                
                StatItem(
                    title: "关闭时间",
                    value: indicator.formattedOffTime24h,
                    icon: "display.slash",
                    color: .red
                )
                
                StatItem(
                    title: "使用率",
                    value: indicator.formattedUsageRate,
                    icon: "percent",
                    color: .blue
                )
            }
            
            HStack {
                StatItem(
                    title: "状态变化",
                    value: "\(indicator.stateChanges24h)次",
                    icon: "arrow.triangle.2.circlepath",
                    color: .purple
                )
                
                Spacer()
                
                StatItem(
                    title: "最后变化",
                    value: indicator.lastChangeTime.formatted(date: .omitted, time: .shortened),
                    icon: "clock",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("State Change History")
                .font(.headline)
            
            if screenStateManager.screenStateHistory.isEmpty {
                Text("No state change records")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(screenStateManager.screenStateHistory.prefix(10)) { event in
                        ScreenStateEventRow(event: event)
                    }
                }
            }
        }
    }
    
    // MARK: - Binary Indicator Section
    
    private var binaryIndicatorSection: some View {
        let indicator = screenStateManager.getScreenStateIndicator()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Binary Indicator")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Current State:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(indicator.binaryIndicator)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(indicator.isCurrentlyOn ? .green : .red)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(indicator.isCurrentlyOn ? .green.opacity(0.2) : .red.opacity(0.2))
                        )
                }
                
                HStack {
                    Text("24-Hour Mode:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(indicator.hourlyPattern24h.joined(separator: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Actions
    
    private func exportScreenStateData() {
        exportData = screenStateManager.exportScreenStateData()
        showingExportSheet = true
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct ScreenStateEventRow: View {
    let event: ScreenStateEvent
    
    var body: some View {
        HStack {
            Image(systemName: event.isScreenOn ? "display" : "display.slash")
                .foregroundColor(event.isScreenOn ? .green : .red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.reason.localizedDescription)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(event.isScreenOn ? "1" : "0")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(event.isScreenOn ? .green : .red)
                .frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(event.isScreenOn ? .green.opacity(0.2) : .red.opacity(0.2))
                )
            
            Text("\(Int(event.brightness * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ExportSheet: View {
    let data: String
    let filename: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Screen State Data Export")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding()
                
                Text("Data is ready, click the share button to export CSV file")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                ShareLink(
                    item: data,
                    preview: SharePreview(
                        filename,
                        image: "doc.text"
                    )
                ) {
                    Label("Share Data", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button("Close") {
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions

extension String {
    var localizedDescription: String {
        switch self {
        case "app_became_active":
            return "应用激活"
        case "app_will_resign_active":
            return "应用即将失活"
        case "app_entered_background":
            return "应用进入后台"
        case "app_will_enter_foreground":
            return "应用即将进入前台"
        case "brightness_zero":
            return "亮度为零"
        case "brightness_restored":
            return "亮度恢复"
        case "initial_state":
            return "初始状态"
        default:
            return self
        }
    }
}

#Preview {
    ScreenStateView()
}
