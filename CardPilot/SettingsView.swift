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
    @StateObject private var dataPersistenceManager = DataPersistenceManager.shared
    @StateObject private var locationManager = LocationManager()
    @AppStorage("imuCollectionDuration") private var imuCollectionDuration: Double = 3.0
    @AppStorage("locationAccuracy") private var locationAccuracy: Int = 0 // 0 = best, 1 = 10m, 2 = 100m
    @AppStorage("microphoneRecordingDuration") private var microphoneRecordingDuration: Double = 3.0
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @State private var locationPermissionStatus: (isAvailable: Bool, userMessage: String?)?
    @State private var showingExportDialog = false
    @State private var selectedExportFormat: ExportFormat = .json
    @State private var showingDeleteAllAlert = false
    @State private var isExporting = false
    @State private var exportResult: String?
    @State private var showingBackupStatus = false
    @State private var isBackingUp = false
    @State private var isRestoring = false
    @State private var backupResult: String?
    @State private var showingLocationGuide = false
    
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
                
                // Location Permissions
                Section("Location Permissions") {
                    HStack {
                        Image(systemName: "location")
                        Text("Location Access")
                        Spacer()
                        Button("Check Status") {
                            checkLocationPermissionStatus()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let locationStatus = locationPermissionStatus {
                        HStack {
                            Image(systemName: locationStatus.isAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(locationStatus.isAvailable ? .green : .orange)
                            Text(locationStatus.userMessage ?? "Location permission available")
                                .font(.caption)
                                .foregroundColor(locationStatus.isAvailable ? .green : .orange)
                        }
                    }
                    
                    Button("Request Location Permission") {
                        requestLocationPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(locationPermissionStatus?.isAvailable == true)
                    
                    Button("View Permission Guide") {
                        showingLocationGuide = true
                    }
                    .buttonStyle(.bordered)
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
                    
                    // 数据备份功能 - 始终显示，即使没有数据
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Backup & Recovery:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 12) {
                            Button(action: backupDataToFile) {
                                HStack {
                                    if isBackingUp {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Image(systemName: "externaldrive")
                                    }
                                    Text(isBackingUp ? "Backing Up..." : "Backup to File")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isBackingUp)
                            
                            Button(action: restoreDataFromFile) {
                                HStack {
                                    if isRestoring {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text(isRestoring ? "Restoring..." : "Restore from File")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isRestoring)
                            
                            Button(action: { showingBackupStatus = true }) {
                                HStack {
                                    Image(systemName: "info.circle")
                                    Text("Backup Status")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // 显示备份状态信息
                        if nfcSessions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("No data to backup yet. Start using NFC features to collect data.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                
                                // 添加生成测试数据的按钮
                                Button(action: generateTestData) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Generate Test Data")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                        } else {
                            Text("Ready to backup \(nfcSessions.count) sessions")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        // 备份结果反馈
                        if let backupResult = backupResult {
                            FeedbackView(message: backupResult)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // 只有在有数据时才显示导出选项
                    if !nfcSessions.isEmpty {
                        Button(action: exportAllData) {
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
                    } else {
                        // 没有数据时的提示
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No Data Available:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Start using NFC features to collect data. Once you have data, export and backup options will become available.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // 说明信息
                Section("About Data Backup") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data backup ensures your NFC session data is preserved even if the app is deleted or updated.")
                            .font(.caption)
                        
                        Text("Backup files are stored in the Files app and can be accessed through the Files app or shared with other applications.")
                            .font(.caption)
                        
                        Text("The main backup file is automatically updated when you use the backup function, while timestamped backup files provide version history.")
                            .font(.caption)
                        
                        // 添加文件存储详细信息
                        VStack(alignment: .leading, spacing: 4) {
                            Text("File Storage Details:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("• Main file: CardPilot_Data.json (always up-to-date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Backup files: CardPilot_Backup_YYYY-MM-DD_HH-mm-ss.json")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Location: Files app → On My iPhone → CardPilot")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Format: JSON with all session data and sensor readings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                        
                        // 添加权限检查按钮
                        Button(action: checkFilePermissions) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                Text("Check File Permissions")
                            }
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                    .foregroundColor(.secondary)
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
                    
                    Link(destination: URL(string: "https://github.com/tagsysx/CardPilot")!) {
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
                        FeedbackView(message: result)
                    }
                }
                
                if let backupResult = backupResult {
                    Section("Backup Status") {
                        Text(backupResult)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportDialog) {
                // 简化的导出对话框
                VStack(spacing: 20) {
                    Text("Export All Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Export \(nfcSessions.count) sessions with complete sensor data")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Export as JSON") {
                        exportAllData()
                        showingExportDialog = false
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Cancel") {
                        showingExportDialog = false
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .sheet(isPresented: $showingBackupStatus) {
                BackupStatusView(backupStatus: dataPersistenceManager.getBackupStatus())
            }
            .sheet(isPresented: $showingLocationGuide) {
                LocationPermissionGuide()
            }
            .alert("Delete All Data", isPresented: $showingDeleteAllAlert) {
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All NFC session data will be permanently deleted.")
            }
            .onAppear {
                checkLocationPermissionStatus()
            }
        }
    }
    
    private func deleteAllData() {
        for session in nfcSessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
    
    // MARK: - Location Permission Methods
    
    private func checkLocationPermissionStatus() {
        locationPermissionStatus = locationManager.checkLocationPermissionStatus()
    }
    
    private func requestLocationPermission() {
        locationManager.manuallyRequestLocationPermission()
        // Check status again after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkLocationPermissionStatus()
        }
    }
    
    private func exportSensorDataReport() {
        isExporting = true
        exportResult = "🔄 Exporting sensor data report..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = exportManager.exportSensorDataReportCSV(from: nfcSessions) {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "✅ Sensor report exported successfully!\n\n📁 File: \(fileURL.lastPathComponent)\n📊 Format: CSV report\n📱 Location: Files app → On My iPhone → CardPilot"
                    
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
                    exportResult = "❌ Sensor report export failed!\n\n🔍 Possible causes:\n• Storage space insufficient\n• File permissions not granted\n\n💡 Try:\n• Check device storage\n• Check file permissions"
                }
            }
            
            // 5秒后清除消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                exportResult = nil
            }
        }
    }
    
    private func exportRecentData(days: Int) {
        isExporting = true
        exportResult = "🔄 Exporting recent \(days) days data..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = exportManager.exportRecentData(nfcSessions, days: days, format: .json) {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "✅ Recent \(days) days data exported successfully!\n\n📁 File: \(fileURL.lastPathComponent)\n📊 Format: JSON\n📱 Location: Files app → On My iPhone → CardPilot"
                    
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
                    exportResult = "❌ Recent data export failed!\n\n🔍 Possible causes:\n• Storage space insufficient\n• File permissions not granted\n\n💡 Try:\n• Check device storage\n• Check file permissions"
                }
            }
            
            // 5秒后清除消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                exportResult = nil
            }
        }
    }
    
    private func exportDataByType(dataType: DataTypeFilter) {
        isExporting = true
        exportResult = "🔄 Exporting \(dataType.rawValue) data..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = exportManager.exportDataByType(nfcSessions, dataType: dataType, format: .json) {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "✅ \(dataType.rawValue) exported successfully!\n\n📁 File: \(fileURL.lastPathComponent)\n📊 Format: JSON\n📱 Location: Files app → On My iPhone → CardPilot"
                    
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
                    exportResult = "❌ \(dataType.rawValue) export failed!\n\n🔍 Possible causes:\n• Storage space insufficient\n• File permissions not granted\n\n💡 Try:\n• Check device storage\n• Check file permissions"
                }
            }
            
            // 5秒后清除消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                exportResult = nil
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
    
    // MARK: - 数据备份功能
    
    private func backupDataToFile() {
        isBackingUp = true
        backupResult = "🔄 Starting backup process..."
        
        // 检查是否有数据可以备份
        if nfcSessions.isEmpty {
            isBackingUp = false
            backupResult = "❌ No data available to backup. Start using NFC features to collect data first."
            // 5秒后清除消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                backupResult = nil
            }
            return
        }
        
        Task {
            // 更新进度
            await MainActor.run {
                backupResult = "📊 Preparing \(nfcSessions.count) sessions for backup..."
            }
            
            let success = await dataPersistenceManager.backupDataToFile(nfcSessions) { progress in
                // 实时更新进度
                Task { @MainActor in
                    backupResult = progress
                }
            }
            
            await MainActor.run {
                isBackingUp = false
                
                if success {
                    backupResult = "✅ Backup completed successfully!\n\n📁 Files saved to:\n• Files app → On My iPhone → CardPilot\n• Main file: CardPilot_Data.json\n• Backup: CardPilot_Backups/ folder\n\n📊 Total sessions backed up: \(nfcSessions.count)"
                    
                    // 清理旧备份文件
                    dataPersistenceManager.cleanupOldBackups()
                    
                    // 显示成功提示
                    showSuccessAlert()
                } else {
                    backupResult = "❌ Backup failed!\n\n🔍 Possible causes:\n• File permissions not granted\n• Storage space insufficient\n• Files app access restricted\n\n💡 Try:\n• Check file permissions\n• Restart the app\n• Check device storage"
                }
                
                // 8秒后清除消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                    backupResult = nil
                }
            }
        }
    }
    
    private func restoreDataFromFile() {
        // 显示文件选择器
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json, .text])
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        
        // 设置初始目录为备份文件夹
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let backupURL = documentsURL.appendingPathComponent("CardPilot_Backups")
            documentPicker.directoryURL = backupURL
        }
        
        // 使用NSObject来包装delegate
        let delegateWrapper = DocumentPickerDelegateWrapper { selectedURL in
            self.performDataRestore(from: selectedURL)
        }
        
        documentPicker.delegate = delegateWrapper
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(documentPicker, animated: true)
        }
    }
    
    // MARK: - 执行数据恢复
    
    private func performDataRestore(from fileURL: URL) {
        isRestoring = true
        backupResult = "🔄 Starting data restoration from: \(fileURL.lastPathComponent)"
        
        Task {
            let success = await dataPersistenceManager.restoreDataFromFile(fileURL: fileURL) { progress in
                Task { @MainActor in
                    backupResult = progress
                }
            }
            
            await MainActor.run {
                isRestoring = false
                
                if success {
                    backupResult = "✅ Data restored successfully!\n\n📁 File: \(fileURL.lastPathComponent)\n📊 Total sessions restored: \(nfcSessions.count)\n\n💡 The restored data is now available in your app."
                    
                    // 清理旧备份文件
                    dataPersistenceManager.cleanupOldBackups()
                    
                    // 显示成功提示
                    showRestoreSuccessAlert(fileURL: fileURL)
                } else {
                    backupResult = "❌ Data restoration failed!\n\n🔍 Possible causes:\n• File format not supported\n• File corrupted or incomplete\n• Storage space insufficient\n• File permissions not granted\n\n💡 Try:\n• Check file format (should be JSON)\n• Verify file integrity\n• Check file permissions\n• Restart the app"
                }
                
                // 8秒后清除消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                    backupResult = nil
                }
            }
        }
    }
    
    // MARK: - 恢复成功提示
    
    private func showRestoreSuccessAlert(fileURL: URL) {
        let alert = UIAlertController(
            title: "✅ Restore Successful!",
            message: "Your data has been restored from:\n\n📁 File: \(fileURL.lastPathComponent)\n📊 Total sessions: \(nfcSessions.count)\n\nThe restored data is now available in your app.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "View Data", style: .default) { _ in
            // 可以在这里导航到数据视图
            print("Navigate to data view")
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    // MARK: - 成功提示
    
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "✅ Backup Successful!",
            message: "Your data has been backed up to the Files app.\n\nLocation: Files app → On My iPhone → CardPilot\n\nYou can now access your backup files even if the app is deleted.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Files App", style: .default) { _ in
            // 尝试打开Files应用
            if let filesURL = URL(string: "x-apple-files://") {
                UIApplication.shared.open(filesURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func generateTestData() {
        // 创建测试数据
        let testSession = NFCSessionData(
            timestamp: Date(),
            latitude: 22.3193, // 香港纬度
            longitude: 114.1694, // 香港经度
            ipAddress: "192.168.1.100",
            wifiSSID: "TestWiFi",
            currentAppName: "CardPilot Test",
            nfcTagData: "TestNFC123456",
            screenState: "on",
            screenBrightness: 0.8,
            nfcUsageType: "Test",
            nfcTriggerSource: "Manual",
            nfcSessionDuration: 2.5,
            street: "Test Street",
            city: "Test City",
            state: "Test State",
            country: "Test Country",
            locationTag: "Test Location"
        )
        
        // 插入到数据库
        modelContext.insert(testSession)
        
        do {
            try modelContext.save()
            backupResult = "Test data generated successfully! You can now test the backup function."
        } catch {
            backupResult = "Failed to save test data: \(error.localizedDescription)"
        }
        
        // 5秒后清除消息
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            backupResult = nil
        }
    }
    
    private func checkFilePermissions() {
        print("🔍 Checking file permissions...")
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        var permissionStatus = "File Access Permissions Check:\n\n"
        
        // 检查Documents目录权限
        do {
            let testFileURL = documentsURL.appendingPathComponent("permission_test.tmp")
            try "test".write(to: testFileURL, atomically: true, encoding: .utf8)
            try fileManager.removeItem(at: testFileURL)
            permissionStatus += "✅ Documents directory: Writable\n"
        } catch {
            permissionStatus += "❌ Documents directory: Not writable - \(error.localizedDescription)\n"
        }
        
        // 检查备份目录
        let backupDirURL = documentsURL.appendingPathComponent("CardPilot_Backups")
        if fileManager.fileExists(atPath: backupDirURL.path) {
            permissionStatus += "✅ Backup directory: Exists\n"
        } else {
            do {
                try fileManager.createDirectory(at: backupDirURL, withIntermediateDirectories: true, attributes: nil)
                permissionStatus += "✅ Backup directory: Created successfully\n"
            } catch {
                permissionStatus += "❌ Backup directory: Creation failed - \(error.localizedDescription)\n"
            }
        }
        
        // 检查文件共享权限
        permissionStatus += "\n📱 Files App Integration:\n"
        permissionStatus += "• UIFileSharingEnabled: Enabled in Info.plist\n"
        permissionStatus += "• LSSupportsOpeningDocumentsInPlace: Enabled\n"
        permissionStatus += "• NSDocumentsFolderUsageDescription: Configured\n"
        
        permissionStatus += "\n🔧 Troubleshooting Steps:\n"
        permissionStatus += "1. Ensure app has Files app permissions\n"
        permissionStatus += "2. Check Settings → Privacy & Security → Files app access\n"
        permissionStatus += "3. Try restarting the app after granting permissions\n"
        permissionStatus += "4. Check if Files app can access the CardPilot folder\n"
        
        let alert = UIAlertController(title: "File Permissions Status", message: permissionStatus, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // 添加打开设置的按钮
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true, completion: nil)
        }
        
        // 打印到控制台
        print(permissionStatus)
    }
    
    // MARK: - 数据导出功能
    
    private func exportAllData() {
        isExporting = true
        exportResult = "🔄 Starting export process..."
        
        Task {
            // 更新进度
            await MainActor.run {
                exportResult = "📊 Preparing \(nfcSessions.count) sessions for export..."
            }
            
            if let fileURL = exportManager.exportData(nfcSessions, format: .json) {
                await MainActor.run {
                    isExporting = false
                    exportResult = "✅ All data exported successfully!\n\n📁 File: \(fileURL.lastPathComponent)\n📊 Total sessions: \(nfcSessions.count)\n💾 Format: JSON with complete data\n📱 Location: Files app → On My iPhone → CardPilot"
                    
                    // 显示成功提示
                    showExportSuccessAlert(fileURL: fileURL)
                }
            } else {
                await MainActor.run {
                    isExporting = false
                    exportResult = "❌ Export failed!\n\n🔍 Possible causes:\n• Storage space insufficient\n• File permissions not granted\n• Export format not supported\n\n💡 Try:\n• Check device storage\n• Check file permissions\n• Try different export format"
                }
            }
            
            // 5秒后清除消息
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    exportResult = nil
                }
            }
        }
    }
    
    // MARK: - 导出成功提示
    
    private func showExportSuccessAlert(fileURL: URL) {
        let alert = UIAlertController(
            title: "✅ Export Successful!",
            message: "Your data has been exported to the Files app.\n\nFile: \(fileURL.lastPathComponent)\nLocation: Files app → On My iPhone → CardPilot\n\nYou can now share this file or open it in other applications.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Share File", style: .default) { _ in
            // 分享文件
            let activityController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityController, animated: true)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Open Files App", style: .default) { _ in
            // 尝试打开Files应用
            if let filesURL = URL(string: "x-apple-files://") {
                UIApplication.shared.open(filesURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - Document Picker Delegate Wrapper

class DocumentPickerDelegateWrapper: NSObject, UIDocumentPickerDelegate {
    private let completion: (URL) -> Void
    
    init(completion: @escaping (URL) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        completion(selectedURL)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // 用户取消了文件选择
        print("File selection cancelled")
    }
}

// MARK: - Feedback View Component

struct FeedbackView: View {
    let message: String
    
    private var iconName: String {
        if message.contains("✅") || message.contains("successfully") {
            return "checkmark.circle.fill"
        } else if message.contains("❌") || message.contains("failed") {
            return "exclamationmark.triangle.fill"
        } else if message.contains("🔄") || message.contains("Starting") {
            return "arrow.clockwise.circle.fill"
        } else {
            return "info.circle.fill"
        }
    }
    
    private var iconColor: Color {
        if message.contains("✅") || message.contains("successfully") {
            return .green
        } else if message.contains("❌") || message.contains("failed") {
            return .red
        } else if message.contains("🔄") || message.contains("Starting") {
            return .blue
        } else {
            return .orange
        }
    }
    
    private var backgroundColor: Color {
        if message.contains("✅") || message.contains("successfully") {
            return .green.opacity(0.1)
        } else if message.contains("❌") || message.contains("failed") {
            return .red.opacity(0.1)
        } else if message.contains("🔄") || message.contains("Starting") {
            return .blue.opacity(0.1)
        } else {
            return .orange.opacity(0.1)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.title2)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(iconColor.opacity(0.3), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: message)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: NFCSessionData.self, inMemory: true)
}
