//
//  ExportTestView.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI
import SwiftData

struct ExportTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var nfcSessions: [NFCSessionData]
    @StateObject private var exportManager = DataExportManager()
    @State private var exportResult: String?
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Test View")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Total Sessions: \(nfcSessions.count)")
                    Text("Sample Session Data:")
                        .font(.headline)
                    
                    if let sampleSession = nfcSessions.first {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Timestamp: \(sampleSession.timestamp)")
                            Text("Location: \(sampleSession.locationString)")
                            Text("NFC Tag: \(sampleSession.nfcTagData ?? "N/A")")
                            Text("Screen State: \(sampleSession.screenState ?? "N/A")")
                            Text("IMU Data: \(sampleSession.imuData != nil ? "Available" : "N/A")")
                            Text("Magnetometer: \(sampleSession.magnetometerData != nil ? "Available" : "N/A")")
                            Text("Barometer: \(sampleSession.barometerData != nil ? "Available" : "N/A")")
                            Text("Ambient Light: \(sampleSession.ambientLightData != nil ? "Available" : "N/A")")
                            Text("Proximity: \(sampleSession.proximityData != nil ? "Available" : "N/A")")
                            Text("Pedometer: \(sampleSession.pedometerData != nil ? "Available" : "N/A")")
                            Text("Temperature: \(sampleSession.temperatureData != nil ? "Available" : "N/A")")
                            Text("Microphone: \(sampleSession.microphoneData != nil ? "Available" : "N/A")")
                            Text("Weather: \(sampleSession.weatherData != nil ? "Available" : "N/A")")
                        }
                        .font(.caption)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 15) {
                    Button("Test JSON Export") {
                        testJSONExport()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Test CSV Export") {
                        testCSVExport()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Test Privacy Export") {
                        testPrivacyExport()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if let result = exportResult {
                    Text(result)
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if isExporting {
                    ProgressView("Exporting...")
                }
            }
            .padding()
            .navigationTitle("Export Test")
        }
    }
    
    private func testJSONExport() {
        guard !nfcSessions.isEmpty else {
            exportResult = "No sessions to export"
            return
        }
        
        isExporting = true
        exportResult = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = exportManager.exportData(nfcSessions, format: .json) {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "JSON export successful: \(fileURL.lastPathComponent)"
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "JSON export failed"
                }
            }
        }
    }
    
    private func testCSVExport() {
        guard !nfcSessions.isEmpty else {
            exportResult = "No sessions to export"
            return
        }
        
        isExporting = true
        exportResult = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = exportManager.exportData(nfcSessions, format: .csv) {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "CSV export successful: \(fileURL.lastPathComponent)"
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "CSV export failed"
                }
            }
        }
    }
    
    private func testPrivacyExport() {
        guard !nfcSessions.isEmpty else {
            exportResult = "No sessions to export"
            return
        }
        
        isExporting = true
        exportResult = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let fileURL = exportManager.exportData(nfcSessions, format: .jsonPrivacy) {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "Privacy export successful: \(fileURL.lastPathComponent)"
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    exportResult = "Privacy export failed"
                }
            }
        }
    }
}

#Preview {
    ExportTestView()
        .modelContainer(for: NFCSessionData.self, inMemory: true)
}
