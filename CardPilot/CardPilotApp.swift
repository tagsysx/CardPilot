//
//  CardPilotApp.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI
import SwiftData

@main
struct CardPilotApp: App {
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
        }
        .modelContainer(sharedModelContainer)
    }
}
