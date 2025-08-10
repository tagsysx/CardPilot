//
//  ContentView.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showBackgroundCollection = false
    @State private var backgroundMode = false
    @State private var sourceApp: String?
    @State private var silentMode = false
    @State private var nfc: String?

    
    var body: some View {
        ZStack {
            if showBackgroundCollection {
                                        BackgroundCollectionView(
                            autoExit: backgroundMode,
                            sourceApp: sourceApp,
                            silentMode: silentMode,
                            nfc: nfc
                        )
                .transition(.opacity)
            } else {
                TabView {
                    SessionsView()
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Sessions")
                        }
                    
                    NFCUsageView()
                        .tabItem {
                            Image(systemName: "creditcard")
                            Text("NFC Usage")
                        }
                    
                    ScreenStateView()
                        .tabItem {
                            Image(systemName: "display")
                            Text("Screen State")
                        }
                    
                    AnalyticsView()
                        .tabItem {
                            Image(systemName: "chart.bar")
                            Text("Analytics")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text("Settings")
                        }
                }
            }
        }
        .onOpenURL { url in
            handleURLScheme(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissBackgroundCollection"))) { _ in
            dismissBackgroundCollection()
        }
    }
    
    private func dismissBackgroundCollection() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showBackgroundCollection = false
        }
        
        // Reset state
        backgroundMode = false
        sourceApp = nil
        silentMode = false
                    nfc = nil
    }
    
        private func handleURLScheme(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        // 处理WiFi SSID参数
        if let ssid = components?.queryItems?.first(where: { $0.name == "ssid" })?.value {
            WiFiSSIDManager.shared.updateSSID(ssid)
        }
        
                        // 处理nfc参数（NFC UID或其他输入）
                nfc = components?.queryItems?.first(where: { $0.name == "nfc" })?.value

        // 检查是否为静默模式
        let isSilentMode = components?.queryItems?.first(where: { $0.name == "silent" })?.value == "true"

        // Check if this is a background collection request
        if url.host == "collect" || url.path.contains("collect") {
            sourceApp = components?.queryItems?.first(where: { $0.name == "sourceApp" })?.value ?? "Unknown"
            backgroundMode = components?.queryItems?.first(where: { $0.name == "autoExit" })?.value == "true"
            silentMode = isSilentMode

            // 统一使用BackgroundCollectionView，但传递silentMode参数
            withAnimation(.easeInOut(duration: 0.3)) {
                showBackgroundCollection = true
            }
        } else if url.host == "trigger" {
            // Legacy support for existing URL scheme
            sourceApp = components?.queryItems?.first(where: { $0.name == "sourceApp" })?.value ?? "Shortcuts"
            backgroundMode = true
            silentMode = isSilentMode

            // 统一使用BackgroundCollectionView，但传递silentMode参数
            withAnimation(.easeInOut(duration: 0.3)) {
                showBackgroundCollection = true
            }
        }
    }
}

struct SessionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NFCSessionData.timestamp, order: .reverse) private var nfcSessions: [NFCSessionData]
    @StateObject private var dataCollectionService = NFCDataCollectionService()
    @State private var searchText = ""
    
    var filteredSessions: [NFCSessionData] {
        if searchText.isEmpty {
            return nfcSessions
        } else {
            return nfcSessions.filter { session in
                (session.currentAppName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (session.ipAddress?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                session.locationString.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("CardPilot")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    Text("\(nfcSessions.count) NFC Sessions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if dataCollectionService.isCollecting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(dataCollectionService.collectionProgress.isEmpty ? "Collecting data..." : dataCollectionService.collectionProgress)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    
                    if let error = dataCollectionService.lastError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        .padding(.top, 4)
                    }
                    
                    // Manual trigger button for testing
                    Button(action: triggerDataCollection) {
                        Label("Trigger Data Collection", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(dataCollectionService.isCollecting)
                }
                .padding()
                
                // Search Bar
                if !nfcSessions.isEmpty {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                }
                
                // NFC Sessions List
                List {
                    ForEach(filteredSessions) { session in
                        NavigationLink {
                            NFCSessionDetailView(session: session)
                        } label: {
                            NFCSessionRowView(session: session)
                        }
                    }
                    .onDelete(perform: deleteSessions)
                }
                .listStyle(PlainListStyle())
                
                if nfcSessions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No NFC sessions recorded")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Trigger this app via NFC or iOS Shortcuts to start collecting data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    private func triggerDataCollection() {
        HapticManager.shared.triggerImpact(style: .light)
        Task {
            let result = await dataCollectionService.collectAllData(modelContext: modelContext)
            if result.latitude != nil || result.ipAddress != nil {
                HapticManager.shared.triggerSuccess()
            } else {
                HapticManager.shared.triggerWarning()
            }
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredSessions[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: NFCSessionData.self, inMemory: true)
}
