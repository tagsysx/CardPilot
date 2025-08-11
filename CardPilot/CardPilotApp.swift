//
//  CardPilotApp.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI
import SwiftData
import AppIntents

@main
struct CardPilotApp: App {
    @StateObject private var dataPersistenceManager = DataPersistenceManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            NFCSessionData.self,
            NFCUsageRecord.self,
            ManualTransaction.self,
            LocationTag.self,
        ])
        
        // 首先尝试使用持久化存储
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Failed to create persistent ModelContainer: \(error)")
            print("Falling back to in-memory storage")
            
            // 如果持久化存储失败，回退到内存存储
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                print("Failed to create in-memory ModelContainer: \(error)")
                // 最后的回退：创建一个空的容器
                return try! ModelContainer(for: Schema([]), configurations: [])
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 应用启动时尝试恢复数据
                    restoreDataIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - 数据恢复
    
    private func restoreDataIfNeeded() {
        // 检查是否有备份数据需要恢复
        let backupStatus = dataPersistenceManager.getBackupStatus()
        
        if backupStatus.mainFileExists {
            print("📁 Found backup file, attempting to restore data...")
            
            // 在后台线程中恢复数据
            Task {
                let restoreSuccess = await dataPersistenceManager.restoreDataFromFile()
                
                if restoreSuccess {
                    print("✅ Successfully restored data from backup")
                    
                    // 在主线程中更新UI
                    await MainActor.run {
                        // 这里可以添加恢复成功的通知
                        print("📱 Data restoration completed on main thread")
                    }
                } else {
                    print("❌ Failed to restore data from backup")
                }
            }
        } else {
            print("📁 No backup file found, using existing SwiftData storage")
        }
    }
}
