//
//  AnalyticsView.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI
import SwiftData
import MapKit

struct AnalyticsView: View {
    @Query private var nfcSessions: [NFCSessionData]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("Analytics")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if nfcSessions.isEmpty {
                        EmptyAnalyticsView()
                    } else {
                        VStack(spacing: 20) {
                            // Overview Stats
                            OverviewStatsView(sessions: nfcSessions)
                            
                            // Location Map
                            LocationMapView(sessions: nfcSessions)
                            
                            // Time Analysis
                            TimeAnalysisView(sessions: nfcSessions)
                            
                            // App Usage
                            AppUsageView(sessions: nfcSessions)
                            
                            // Data Quality
                            DataQualityView(sessions: nfcSessions)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct OverviewStatsView: View {
    let sessions: [NFCSessionData]
    
    var totalSessions: Int { sessions.count }
    var sessionsWithLocation: Int { sessions.filter { $0.latitude != nil && $0.longitude != nil }.count }
    var sessionsWithIMU: Int { sessions.filter { $0.imuData != nil }.count }
    var uniqueApps: Int { Set(sessions.compactMap { $0.currentAppName }).count }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Total Sessions", value: "\(totalSessions)", icon: "doc.text", color: .blue)
                StatCard(title: "With Location", value: "\(sessionsWithLocation)", icon: "location", color: .green)
                StatCard(title: "With IMU Data", value: "\(sessionsWithIMU)", icon: "gyroscope", color: .orange)
                StatCard(title: "Unique Apps", value: "\(uniqueApps)", icon: "app", color: .purple)
            }
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}





struct TimeAnalysisView: View {
    let sessions: [NFCSessionData]
    
    var sessionsToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.filter { $0.timestamp >= today }.count
    }
    
    var sessionsThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.timestamp >= weekAgo }.count
    }
    
    var mostActiveHour: String {
        let hourCounts = Dictionary(grouping: sessions) { session in
            Calendar.current.component(.hour, from: session.timestamp)
        }.mapValues { $0.count }
        
        if let mostActive = hourCounts.max(by: { $0.value < $1.value }) {
            return "\(mostActive.key):00"
        }
        return "N/A"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Analysis")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Today:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(sessionsToday) sessions")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("This Week:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(sessionsThisWeek) sessions")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Most Active Hour:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(mostActiveHour)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct AppUsageView: View {
    let sessions: [NFCSessionData]
    
    var appCounts: [(String, Int)] {
        let counts = Dictionary(grouping: sessions.compactMap { $0.currentAppName }) { $0 }
            .mapValues { $0.count }
        return counts.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Usage")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if appCounts.isEmpty {
                Text("No app data available")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(appCounts.prefix(5).enumerated()), id: \.offset) { index, item in
                        HStack {
                            Text(item.0)
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.1)")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                        
                        if index < min(4, appCounts.count - 1) {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

struct DataQualityView: View {
    let sessions: [NFCSessionData]
    
    var locationDataRate: Double {
        guard !sessions.isEmpty else { return 0 }
        let withLocation = sessions.filter { $0.latitude != nil && $0.longitude != nil }.count
        return Double(withLocation) / Double(sessions.count) * 100
    }
    
    var imuDataRate: Double {
        guard !sessions.isEmpty else { return 0 }
        let withIMU = sessions.filter { $0.imuData != nil }.count
        return Double(withIMU) / Double(sessions.count) * 100
    }
    
    var ipDataRate: Double {
        guard !sessions.isEmpty else { return 0 }
        let withIP = sessions.filter { $0.ipAddress != nil }.count
        return Double(withIP) / Double(sessions.count) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Quality")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                DataQualityRow(title: "Location Data", percentage: locationDataRate, color: .green)
                DataQualityRow(title: "Motion Data", percentage: imuDataRate, color: .orange)
                DataQualityRow(title: "Network Data", percentage: ipDataRate, color: .blue)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct DataQualityRow: View {
    let title: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(percentage))%")
                    .fontWeight(.medium)
            }
            
            ProgressView(value: percentage / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }
}

struct EmptyAnalyticsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Data to Analyze")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Collect some NFC session data to see analytics and insights here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: NFCSessionData.self, inMemory: true)
}
