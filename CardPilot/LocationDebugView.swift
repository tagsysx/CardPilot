//
//  LocationDebugView.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI
import CoreLocation

struct LocationDebugView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var debugInfo: String = ""
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 状态概览
                    GroupBox("Location Status") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Location Services:")
                                Spacer()
                                Text(locationManager.locationServicesEnabled ? "✅ Enabled" : "❌ Disabled")
                                    .foregroundColor(locationManager.locationServicesEnabled ? .green : .red)
                            }
                            
                            HStack {
                                Text("Authorization:")
                                Spacer()
                                Text(authorizationStatusText)
                                    .foregroundColor(authorizationStatusColor)
                            }
                            
                            HStack {
                                Text("Location Updates:")
                                Spacer()
                                Text(locationManager.isLocationServiceActive ? "✅ Active" : "❌ Inactive")
                                    .foregroundColor(locationManager.isLocationServiceActive ? .green : .red)
                            }
                        }
                    }
                    
                    // 当前位置信息
                    GroupBox("Current Location") {
                        VStack(alignment: .leading, spacing: 10) {
                            if let location = locationManager.location {
                                HStack {
                                    Text("Latitude:")
                                    Spacer()
                                    Text(String(format: "%.6f", location.coordinate.latitude))
                                        .font(.system(.body, design: .monospaced))
                                }
                                
                                HStack {
                                    Text("Longitude:")
                                    Spacer()
                                    Text(String(format: "%.6f", location.coordinate.longitude))
                                        .font(.system(.body, design: .monospaced))
                                }
                                
                                HStack {
                                    Text("Accuracy:")
                                    Spacer()
                                    Text("\(Int(location.horizontalAccuracy))m")
                                        .foregroundColor(location.horizontalAccuracy <= 100 ? .green : .orange)
                                }
                                
                                HStack {
                                    Text("Timestamp:")
                                    Spacer()
                                    Text(location.timestamp, style: .time)
                                        .font(.caption)
                                }
                            } else {
                                Text("No location available")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // 最后已知位置
                    if let lastLocation = locationManager.lastKnownLocation {
                        GroupBox("Last Known Location") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Latitude:")
                                    Spacer()
                                    Text(String(format: "%.6f", lastLocation.coordinate.latitude))
                                        .font(.system(.body, design: .monospaced))
                                }
                                
                                HStack {
                                    Text("Longitude:")
                                    Spacer()
                                    Text(String(format: "%.6f", lastLocation.coordinate.longitude))
                                        .font(.system(.body, design: .monospaced))
                                }
                                
                                HStack {
                                    Text("Accuracy:")
                                    Spacer()
                                    Text("\(Int(lastLocation.horizontalAccuracy))m")
                                        .foregroundColor(lastLocation.horizontalAccuracy <= 100 ? .green : .orange)
                                }
                                
                                HStack {
                                    Text("Age:")
                                    Spacer()
                                    Text("\(Int(Date().timeIntervalSince(lastLocation.timestamp)))s ago")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    // 操作按钮
                    GroupBox("Actions") {
                        VStack(spacing: 15) {
                            Button("Request Location Permission") {
                                locationManager.requestLocation { location in
                                    // Handle the location result if needed
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Start Location Updates") {
                                locationManager.startLocationUpdates()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Stop Location Updates") {
                                locationManager.stopLocationUpdates()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Force Location Refresh") {
                                forceRefreshLocation()
                            }
                            .buttonStyle(.bordered)
                            .disabled(isRefreshing)
                            
                            if isRefreshing {
                                ProgressView("Refreshing...")
                            }
                        }
                    }
                    
                    // 调试信息
                    if !debugInfo.isEmpty {
                        GroupBox("Debug Info") {
                            ScrollView {
                                Text(debugInfo)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                    
                    // 系统信息
                    GroupBox("System Info") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("iOS Version:")
                                Spacer()
                                Text(UIDevice.current.systemVersion)
                            }
                            
                            HStack {
                                Text("Device Model:")
                                Spacer()
                                Text(UIDevice.current.model)
                            }
                            
                            HStack {
                                Text("Simulator:")
                                Spacer()
                                Text(ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil ? "Yes" : "No")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Location Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Debug") {
                        debugInfo = ""
                    }
                }
            }
        }
        .onAppear {
            addDebugLog("LocationDebugView appeared")
        }
    }
    
    private var authorizationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "⏳ Not Determined"
        case .restricted:
            return "🚫 Restricted"
        case .denied:
            return "❌ Denied"
        case .authorizedWhenInUse:
            return "✅ When In Use"
        case .authorizedAlways:
            return "✅ Always"
        @unknown default:
            return "❓ Unknown"
        }
    }
    
    private var authorizationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private func forceRefreshLocation() {
        isRefreshing = true
        addDebugLog("Force refreshing location...")
        
        Task {
            if let location = await locationManager.forceLocationRefresh() {
                addDebugLog("✅ Location refreshed: \(location.coordinate)")
            } else {
                addDebugLog("❌ Location refresh failed")
            }
            
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func addDebugLog(_ message: String) {
        let timestamp = DateFormatter.debugFormatter.string(from: Date())
        let logEntry = "[\(timestamp)] \(message)\n"
        
        DispatchQueue.main.async {
            debugInfo += logEntry
        }
    }
}

extension DateFormatter {
    static let debugFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

#Preview {
    LocationDebugView()
}
