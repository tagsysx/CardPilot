//
//  HapticManager.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import Foundation
import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func triggerSuccess() {
        guard isHapticEnabled() else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func triggerError() {
        guard isHapticEnabled() else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func triggerWarning() {
        guard isHapticEnabled() else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isHapticEnabled() else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func triggerSelection() {
        guard isHapticEnabled() else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    private func isHapticEnabled() -> Bool {
        // Default to true if not set
        if UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "hapticFeedbackEnabled")
        }
        return UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
    }
}
