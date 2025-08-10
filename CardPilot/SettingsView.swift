//
//  SettingsView.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var nfcSessions: [NFCSessionData]
    @StateObject private var exportManager = DataExportManager()
    @AppStorage("imuCollectionDuration") private var imuCollectionDuration: Double = 5.0
    @AppStorage("locationAccuracy") private var locationAccuracy: Int = 0 // 0 = best, 1 = 10m, 2 = 100m
    @AppStorage("microphoneRecordingDuration") private var microphoneRecordingDuration: Double = 3.0
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @State private var showingExportDialog = false
    @State private var selectedExportFormat: ExportFormat = .json
    @State private var showingDeleteAllAlert = false
    @State private var isExporting = false
    @State private var exportResult: String?
    
    var body: some View {
        NavigationView {
            Form {
                // Data Collection Settings
                Section("Data Collection") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("IMU Collection Duration")
                            .font(.subheadline)
                        HStack {
                            Text("\(Int(imuCollectionDuration))s")
                                .frame(width: 30, alignment: .leading)
                            Slider(value: $imuCollectionDuration, in: 1...10, step: 1)
                        }
                        Text("Duration for collecting motion sensor data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Location Accuracy", selection: $locationAccuracy) {
                        Text("Best").tag(0)
                        Text("10 meters").tag(1)
                        Text("100 meters").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Microphone Recording Duration")
                            .font(.subheadline)
                        HStack {
                            Text("\(Int(microphoneRecordingDuration))s")
                                .frame(width: 30, alignment: .leading)
                            Slider(value: $microphoneRecordingDuration, in: 1...10, step: 1)
                        }
                        Text("Duration for recording ambient audio data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // User Experience
                Section("User Experience") {
                    Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                }
                
                // Data Management
                Section("Data Management") {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Total Sessions")
                        Spacer()
                        Text("\(nfcSessions.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if !nfcSessions.isEmpty {
                        Button(action: { showingExportDialog = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export All Data")
                            }
                        }
                        .disabled(isExporting)
                        
                        Button(action: exportSensorDataReport) {
                            HStack {
                                Image(systemName: "chart.bar.doc.horizontal")
                                Text("Export Sensor Report")
                            }
                        }
                        .disabled(isExporting)
                        
                        // 快速导出选项
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Export Options:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 12) {
                                Button("Last 7 Days") {
                                    exportRecentData(days: 7)
                                }
                                .buttonStyle(.bordered)
                                .disabled(isExporting)
                                
                                Button("Last 30 Days") {
                                    exportRecentData(days: 30)
                                }
                                .buttonStyle(.bordered)
                                .disabled(isExporting)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // 按数据类型导出
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Export by Data Type:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(DataTypeFilter.allCases, id: \.self) { dataType in
                                    Button(dataType.rawValue) {
                                        exportDataByType(dataType: dataType)
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isExporting)
                                    .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Button(action: { showingDeleteAllAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete All Data")
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // App Information
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "iphone")
                        Text("Minimum iOS")
                        Spacer()
                        Text("17.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/cardpilot/cardpilot")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("Project Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if let result = exportResult {
                    Section("Export Status") {
                        Text(result)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportDialog) {
                ExportDialogView(
                    selectedFormat: $selectedExportFormat,
                    isExporting: $isExporting,
                    exportResult: $exportResult,
                    sessions: nfcSessions,
                    exportManager: exportManager
                )
            }
            .alert("Delete All Data", isPresented: $showingDeleteAllAlert) {
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(nfcSessions.count) NFC sessions. This action cannot be undone.")
            }
        }
    }
    
    private func deleteAllData() {
        for session in nfcSessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
    
    private func exportSensorDataReport() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = exportManager.exportSensorDataReportCSV(from: nfcSessions) {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "Sensor report exported successfully to Files app"
                    
                    // Share the exported file
                    let activityController = UIActivityViewController(
                        activityItems: [fileURL],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityController, animated: true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "Sensor report export failed. Please try again."
                }
            }
        }
    }
    
    private func exportRecentData(days: Int) {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = exportManager.exportRecentData(nfcSessions, days: days, format: .json) {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "Recent \(days) days data exported successfully to Files app"
                    
                    // Share the exported file
                    let activityController = UIActivityViewController(
                        activityItems: [fileURL],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityController, animated: true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "Recent data export failed. Please try again."
                }
            }
        }
    }
    
    private func exportDataByType(dataType: DataTypeFilter) {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = exportManager.exportDataByType(nfcSessions, dataType: dataType, format: .json) {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "\(dataType.rawValue) exported successfully to Files app"
                    
                    // Share the exported file
                    let activityController = UIActivityViewController(
                        activityItems: [fileURL],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityController, animated: true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "Data export failed. Please try again."
                }
            }
        }
    }
    
    private func createSensorDataExport() -> [String: Any] {
        var exportData: [String: Any] = [:]
        
        // 应用设置
        exportData["appSettings"] = [
            "imuCollectionDuration": imuCollectionDuration,
            "locationAccuracy": locationAccuracy,
            "microphoneRecordingDuration": microphoneRecordingDuration,
            "hapticFeedbackEnabled": hapticFeedbackEnabled
        ]
        
        // 传感器状态
        exportData["sensorStatus"] = [
            "totalSessions": nfcSessions.count,
            "exportTimestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // 最近的数据样本（如果有的话）
        if let recentSession = nfcSessions.first {
            exportData["recentDataSample"] = [
                "timestamp": ISO8601DateFormatter().string(from: recentSession.timestamp),
                "hasLocation": recentSession.latitude != nil && recentSession.longitude != nil,
                "hasIMU": recentSession.imuData != nil,
                "hasMicrophone": recentSession.microphoneData != nil
            ]
        }
        
        return exportData
    }
}

struct ExportDialogView: View {
    @Binding var selectedFormat: ExportFormat
    @Binding var isExporting: Bool
    @Binding var exportResult: String?
    let sessions: [NFCSessionData]
    let exportManager: DataExportManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export All Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Export \(sessions.count) sessions with complete sensor data, NFC usage, and screen state information")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // 数据统计概览
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Overview:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    let report = exportManager.generateSensorDataReport(from: sessions)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Sessions with location: \(report.sessionsWithLocation) (\(String(format: "%.1f%%", report.locationPercentage * 100)))")
                        Text("• Sessions with IMU data: \(report.sessionsWithIMU) (\(String(format: "%.1f%%", report.imuDataPercentage * 100)))")
                        Text("• Sessions with NFC data: \(report.sessionsWithNFCTag) (\(String(format: "%.1f%%", report.nfcTagPercentage * 100)))")
                        Text("• Total IMU data points: \(report.totalIMUDataPoints)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Picker("Export Format", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Format Details:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    switch selectedFormat {
                    case .csv:
                        Text("• Spreadsheet-compatible format\n• Easy to import into Excel or Numbers\n• Includes all sensor data, NFC usage, and screen state information\n• Data quality score for each session")
                    case .json:
                        Text("• Complete data including all sensor readings\n• Developer-friendly format with detailed metadata\n• Includes comprehensive NFC usage and screen state history\n• Full sensor data summary and statistics")
                    case .csvPrivacy:
                        Text("• Spreadsheet-compatible format\n• No GPS coordinates (privacy-safe)\n• Includes all sensor data, NFC usage, and screen state information\n• Data quality score for each session")
                    case .jsonPrivacy:
                        Text("• Complete sensor and session data\n• No GPS coordinates (privacy-safe)\n• Includes comprehensive NFC usage and screen state history\n• Full sensor data summary and statistics")
                    case .audioSamples:
                        Text("• Audio samples export in ZIP format\n• Includes all recorded audio data from sessions\n• Contains metadata and session information\n• Suitable for audio analysis and processing")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                Button(action: exportData) {
                    if isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Exporting...")
                        }
                    } else {
                        Text("Export Data")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = exportManager.exportData(sessions, format: selectedFormat) {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "Data exported successfully to Files app"
                    
                    // Share the exported file
                    let activityController = UIActivityViewController(
                        activityItems: [fileURL],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityController, animated: true)
                    }
                    
                    dismiss()
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "Export failed. Please try again."
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: NFCSessionData.self, inMemory: true)
}
