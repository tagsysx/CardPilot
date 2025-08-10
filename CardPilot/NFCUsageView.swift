//
//  NFCUsageView.swift
//  CardPilot
//
//  Interface for viewing NFC usage records
//

import SwiftUI
import SwiftData
import Charts

struct NFCUsageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NFCUsageRecord.timestamp, order: .reverse) private var usageRecords: [NFCUsageRecord]
    @StateObject private var usageTracker = NFCUsageTracker()
    
    @State private var selectedUsageType: NFCUsageType = .unknown
    @State private var analytics: NFCUsageAnalytics?
    
    var filteredRecords: [NFCUsageRecord] {
        if selectedUsageType == .unknown {
            return Array(usageRecords.prefix(50)) // Show recent 50 records
        } else {
            return usageRecords.filter { $0.usageType == selectedUsageType }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistics overview
                if !usageRecords.isEmpty {
                    usageOverviewSection
                        .padding()
                        .background(Color(.systemGray6))
                }
                
                // Type filter
                usageTypeFilter
                    .padding(.horizontal)
                
                // Usage records list
                if filteredRecords.isEmpty {
                    // Empty state prompt
                    VStack(spacing: 20) {
                        Image(systemName: "creditcard.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            Text("No NFC Usage Records")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("When you use NFC tags to trigger iOS Shortcuts to launch CardPilot,\nthe system automatically records each NFC usage")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("Including usage time, location, type and other information")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 50)
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            NFCUsageRowView(record: record)
                        }
                        .onDelete(perform: deleteRecords)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await usageTracker.updateUsageStatistics(modelContext: modelContext)
                    }
                }
            }
            .navigationTitle("NFC Usage Records")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Records", systemImage: "trash") {
                        clearAllRecords()
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                updateAnalytics()
            }
        }
    }
    
    // MARK: - Usage Overview Section
    
    private var usageOverviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Usage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(todayUsageCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total Usage Count")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(usageRecords.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            if let analytics = analytics {
                // Usage type distribution chart
                usageTypeChart(analytics: analytics)
            }
        }
    }
    
    private var todayUsageCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return usageRecords.filter { record in
            record.timestamp >= today && record.timestamp < tomorrow
        }.count
    }
    
    private func usageTypeChart(analytics: NFCUsageAnalytics) -> some View {
        VStack(alignment: .leading) {
            Text("Usage Type Distribution")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Chart {
                ForEach(Array(analytics.usagesByType.keys), id: \.self) { type in
                    BarMark(
                        x: .value("Type", type.rawValue),
                        y: .value("Count", analytics.usagesByType[type] ?? 0)
                    )
                    .foregroundStyle(colorForUsageType(type))
                }
            }
            .frame(height: 100)
        }
    }
    
    // MARK: - Usage Type Filter
    
    private var usageTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    icon: "list.bullet",
                    isSelected: selectedUsageType == .unknown
                ) {
                    selectedUsageType = .unknown
                }
                
                ForEach(NFCUsageType.allCases.filter { $0 != .unknown }, id: \.self) { type in
                    FilterChip(
                        title: type.rawValue,
                        icon: type.icon,
                        isSelected: selectedUsageType == type,
                        count: usageRecords.filter { $0.usageType == type }.count
                    ) {
                        selectedUsageType = type
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions
    
    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredRecords[index])
            }
        }
    }
    
    private func clearAllRecords() {
        withAnimation {
            for record in usageRecords {
                modelContext.delete(record)
            }
        }
    }
    
    private func updateAnalytics() {
        analytics = usageTracker.getUsageAnalytics(modelContext: modelContext)
    }
    
    private func colorForUsageType(_ type: NFCUsageType) -> Color {
        switch type {
        case .payment: return .green
        case .transport: return .blue
        case .access: return .orange
        case .identification: return .purple
        case .unknown: return .gray
        }
    }
}

// MARK: - Usage Row View

struct NFCUsageRowView: View {
    let record: NFCUsageRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: record.usageType.icon)
                .font(.title2)
                .foregroundColor(colorForUsageType(record.usageType))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.usageType.rawValue)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(record.formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(record.locationString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let duration = record.sessionDuration {
                        Text("\(String(format: "%.1f", duration))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    if record.triggerSource != "unknown" {
                        Text("Source: \(record.triggerSource)")
                            .font(.caption2)
                            .foregroundColor(Color.secondary)
                    }
                    
                    if let nfcUID = record.nfcUID, !nfcUID.isEmpty {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "contactlessreader.radio.waves")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("UID: \(nfcUID)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForUsageType(_ type: NFCUsageType) -> Color {
        switch type {
        case .payment: return .green
        case .transport: return .blue
        case .access: return .orange
        case .identification: return .purple
        case .unknown: return .gray
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void
    
    init(title: String, icon: String, isSelected: Bool, count: Int? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.count = count
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Automatic NFC Usage Tracking
// NFC usage is now automatically recorded by Shortcuts, no manual addition needed

#Preview {
    NFCUsageView()
}
