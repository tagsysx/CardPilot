//
//  BackupStatusView.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupStatusView: View {
    let backupStatus: BackupStatus
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var fileToShare: URL?
    
    var body: some View {
        NavigationView {
            List {
                // 主备份文件状态
                Section("Main Backup File") {
                    HStack {
                        Image(systemName: backupStatus.mainFileExists ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(backupStatus.mainFileExists ? .green : .red)
                        Text("Main Backup File")
                        Spacer()
                        Text(backupStatus.mainFileExists ? "Available" : "Not Found")
                            .foregroundColor(.secondary)
                    }
                    
                    if backupStatus.mainFileExists {
                        Button(action: shareMainBackup) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Main Backup")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // 备份目录状态
                Section("Backup Directory") {
                    HStack {
                        Image(systemName: backupStatus.backupDirectoryExists ? "folder.fill" : "folder")
                            .foregroundColor(backupStatus.backupDirectoryExists ? .blue : .gray)
                        Text("Backup Directory")
                        Spacer()
                        Text(backupStatus.backupDirectoryExists ? "Available" : "Not Found")
                            .foregroundColor(.secondary)
                    }
                    
                    if backupStatus.backupDirectoryExists {
                        HStack {
                            Text("Total Backup Files")
                            Spacer()
                            Text("\(backupStatus.totalBackupFiles)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Total Size")
                            Spacer()
                            Text(formatFileSize(backupStatus.totalBackupSize))
                                .foregroundColor(.secondary)
                        }
                        
                        if let latestDate = backupStatus.latestBackupDate {
                            HStack {
                                Text("Latest Backup")
                                Spacer()
                                Text(latestDate, style: .date)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 备份文件列表
                if !backupStatus.backupFiles.isEmpty {
                    Section("Backup Files") {
                        ForEach(backupStatus.backupFiles, id: \.name) { backupFile in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(backupFile.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(backupFile.formattedFileSize)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text(backupFile.formattedDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    
                                    Button(action: { shareBackupFile(backupFile.url) }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // 文件路径信息
                Section("File Locations") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Main Backup File:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(backupStatus.mainFileURL.path)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                        
                        Text("Backup Directory:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(backupStatus.backupDirectoryURL.path)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                        
                        // 添加访问指南
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How to Access:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("1. Open Files app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("2. Go to 'On My iPhone' or 'iCloud Drive'")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("3. Look for 'CardPilot' folder")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("4. Your backup files are stored there")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
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
                    }
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Backup Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let fileURL = fileToShare {
                ShareSheet(activityItems: [fileURL])
            }
        }
    }
    
    // MARK: - 辅助函数
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func shareMainBackup() {
        fileToShare = backupStatus.mainFileURL
        showingShareSheet = true
    }
    
    private func shareBackupFile(_ url: URL) {
        fileToShare = url
        showingShareSheet = true
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let mockBackupStatus = BackupStatus(
        mainFileExists: true,
        backupDirectoryExists: true,
        backupFiles: [
            BackupFileInfo(
                name: "CardPilot_Backup_2025-08-11_22-30-00.json",
                creationDate: Date(),
                fileSize: 1024 * 1024,
                url: URL(fileURLWithPath: "/mock/path")
            )
        ],
        mainFileURL: URL(fileURLWithPath: "/mock/main"),
        backupDirectoryURL: URL(fileURLWithPath: "/mock/backup")
    )
    
    BackupStatusView(backupStatus: mockBackupStatus)
}
