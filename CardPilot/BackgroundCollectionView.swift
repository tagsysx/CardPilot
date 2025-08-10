//
//  BackgroundCollectionView.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI
import SwiftData

struct BackgroundCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataCollectionService = NFCDataCollectionService()
    @State private var collectionComplete = false
    @State private var countdown = 3
    @State private var showSuccess = false
    @State private var countdownTimer: Timer?
    @State private var silentCountdown = 3
    
    let autoExit: Bool
    let sourceApp: String?
    let silentMode: Bool
    let nfc: String?
    
    var body: some View {
        ZStack {
            if silentMode {
                // 静默模式：简洁暗色界面
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        // 进度指示器
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        
                        // 当前采集状态
                        if dataCollectionService.isCollecting {
                            if !dataCollectionService.collectionProgress.isEmpty {
                                Text(dataCollectionService.collectionProgress)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("正在采集数据...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        } else if collectionComplete {
                            Text("采集完成")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                            
                            if silentCountdown > 0 {
                                Text("退出 \(silentCountdown)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        } else {
                            Text("准备采集...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
            } else {
                // 普通模式：完整界面
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                // NFC Icon
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(dataCollectionService.isCollecting ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatWhileAnimating(dataCollectionService.isCollecting), value: dataCollectionService.isCollecting)
                
                VStack(spacing: 16) {
                    if dataCollectionService.isCollecting {
                        // Collection in progress
                        Text("Collecting Data...")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if !dataCollectionService.collectionProgress.isEmpty {
                            Text(dataCollectionService.collectionProgress)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                    } else if showSuccess {
                        // Collection complete
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Data Collected Successfully!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if let result = dataCollectionService.lastCollectionResult {
                            VStack(spacing: 8) {
                                CollectionSummaryRow(
                                    icon: "location", 
                                    label: "Location", 
                                    value: result.latitude != nil ? "✓" : "✗"
                                )
                                CollectionSummaryRow(
                                    icon: "network", 
                                    label: "Network", 
                                    value: result.ipAddress != nil ? "✓" : "✗"
                                )
                                CollectionSummaryRow(
                                    icon: "gyroscope", 
                                    label: "Motion", 
                                    value: result.imuData != nil ? "✓" : "✗"
                                )
                            }
                            .padding(.top, 10)
                        }
                        
                        if autoExit {
                            HStack {
                                Text("Auto-closing in")
                                Text("\(countdown)")
                                    .fontWeight(.bold)
                                Text("seconds...")
                            }
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        }
                        
                    } else {
                        // Initial state
                        Text("NFC Data Collection")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Tap to start collecting sensor data")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Start Collection") {
                            startCollection()
                        }
                        .buttonStyle(BackgroundCollectionButtonStyle())
                    }
                    
                    // Error display
                    if let error = dataCollectionService.lastError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(error)
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 8)
                    }
                }
                
                // Close button (only if not auto-exiting)
                if !autoExit || !showSuccess {
                    Button("Close") {
                        exitApp()
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .font(.body)
                }
            }
            .padding(.horizontal, 40)
            }
        }
        .onAppear {
            // Auto-start if triggered from NFC
            if sourceApp != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startCollection()
                }
            }
        }
        .onChange(of: showSuccess) { oldValue, newValue in
            if newValue && autoExit {
                startCountdown()
            }
        }
    }
    
    private func startCollection() {
        HapticManager.shared.triggerImpact(style: .medium)
        Task {
                            // 准备URL参数，包含sourceApp和nfc信息
                var urlParameters: [String: Any] = [:]
                if let sourceApp = sourceApp {
                    urlParameters["sourceApp"] = sourceApp
                }
                if let nfc = nfc {
                    urlParameters["nfc"] = nfc
                }
            
            let result = await dataCollectionService.collectAllData(modelContext: modelContext, urlParameters: urlParameters)
            
            await MainActor.run {
                if silentMode {
                    // 静默模式：显示完成状态并启动倒计时
                    collectionComplete = true
                    HapticManager.shared.triggerSuccess()
                    
                    // 启动静默模式倒计时
                    startSilentCountdown()
                } else {
                    // 普通模式：显示成功界面
                    showSuccess = true
                    
                    // Provide haptic feedback based on result
                    if result.latitude != nil || result.ipAddress != nil || result.imuData != nil {
                        HapticManager.shared.triggerSuccess()
                    } else {
                        HapticManager.shared.triggerWarning()
                    }
                }
            }
        }
    }
    
    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
                countdownTimer = nil
                exitApp()
            }
        }
    }
    
    private func startSilentCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            silentCountdown -= 1
            if silentCountdown <= 0 {
                timer.invalidate()
                countdownTimer = nil
                exitApp()
            }
        }
    }
    
    private func exitApp() {
        HapticManager.shared.triggerSelection()
        
        // Clean up timer
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // First, dismiss this view by notifying parent
        NotificationCenter.default.post(name: NSNotification.Name("DismissBackgroundCollection"), object: nil)
        
        // For silent mode or autoExit, minimize the app immediately
        if silentMode || autoExit {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 直接将应用最小化到后台
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            }
        }
    }
}

struct CollectionSummaryRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(value == "✓" ? .green : .red)
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.9))
    }
}

struct BackgroundCollectionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Animation modifier for pulsing effect
extension Animation {
    func repeatWhileAnimating(_ condition: Bool) -> Animation {
        return condition ? self.repeatForever(autoreverses: true) : .default
    }
}

#Preview {
            BackgroundCollectionView(autoExit: true, sourceApp: "Shortcuts", silentMode: false, nfc: nil)
        .modelContainer(for: NFCSessionData.self, inMemory: true)
}
