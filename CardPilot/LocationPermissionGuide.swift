//
//  LocationPermissionGuide.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI

struct LocationPermissionGuide: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            Text("Location Permission Guide")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("Follow these steps to enable location access for CardPilot")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                    
                    // Step 1: Check App Settings
                    GroupBox("Step 1: Check App Settings") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "1.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Open iOS Settings")
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• Go to Settings app on your iPhone")
                                Text("• Scroll down and tap 'CardPilot'")
                                Text("• Tap 'Location'")
                                Text("• Select 'While Using App' or 'Always'")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Step 2: App Permission Request
                    GroupBox("Step 2: App Permission Request") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "2.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Grant Permission in App")
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• Return to CardPilot app")
                                Text("• Go to Settings → Location Permissions")
                                Text("• Tap 'Request Location Permission'")
                                Text("• Tap 'Allow While Using App' when prompted")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Step 3: Verify Permission
                    GroupBox("Step 3: Verify Permission") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "3.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Verify Permission Status")
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• Check the Location Permissions section")
                                Text("• Status should show 'Location permission available'")
                                Text("• Location data collection should now work")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Troubleshooting
                    GroupBox("Troubleshooting") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .foregroundColor(.orange)
                                Text("Common Issues & Solutions")
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• If permission is still denied:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("  - Restart the CardPilot app")
                                Text("  - Check if Location Services are enabled in Settings → Privacy → Location Services")
                                Text("  - Try toggling location permission off and on again")
                                
                                Text("• For persistent issues:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.top, 8)
                                Text("  - Offload and reinstall the app")
                                Text("  - Contact support with error details")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Why Location Access is Needed
                    GroupBox("Why Location Access is Needed") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CardPilot needs location access to:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Record GPS coordinates for NFC usage")
                                Text("• Provide detailed address information")
                                Text("• Enable location-based analytics")
                                Text("• Support location tagging features")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Location Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LocationPermissionGuide()
}
