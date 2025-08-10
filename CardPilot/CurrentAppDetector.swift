//
//  CurrentAppDetector.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import Foundation
import UIKit

class CurrentAppDetector: ObservableObject {
    
    func getCurrentAppName() -> String? {
        // Note: Getting the currently active app name from another app is restricted on iOS
        // for privacy and security reasons. This implementation provides fallback methods.
        
        // Method 1: Try to get app bundle info (this will return our own app)
        if let bundleDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return bundleDisplayName
        }
        
        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return bundleName
        }
        
        // Method 2: Check if we can detect the app that triggered this via URL scheme
        // This would require the triggering app to pass its identifier
        return detectTriggeringApp()
    }
    
    private func detectTriggeringApp() -> String? {
        // In a real implementation, you might:
        // 1. Use URL schemes to receive the triggering app's identifier
        // 2. Use Shortcuts app integration to pass context
        // 3. Use shared pasteboard with specific identifiers
        
        // For now, we'll return a placeholder that indicates the trigger method
        return "Triggered via iOS Shortcuts"
    }
    
    // Alternative method: If the app is triggered via Shortcuts,
    // the Shortcuts app can pass parameters about the triggering context
    func getCurrentAppNameFromShortcuts(parameters: [String: Any]?) -> String? {
        // Extract app information from Shortcuts parameters if available
        if let params = parameters,
           let triggeringApp = params["triggeringApp"] as? String {
            return triggeringApp
        }
        
        // Fallback to detecting current foreground app (limited on iOS)
        return getCurrentAppName()
    }
    
    // Method to be called when app is launched via URL scheme
    func handleURLScheme(_ url: URL) -> String? {
        // Parse URL to extract triggering app information
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        if let queryItems = components?.queryItems {
            for item in queryItems {
                if item.name == "sourceApp" {
                    return item.value
                }
            }
        }
        
        return nil
    }
}
