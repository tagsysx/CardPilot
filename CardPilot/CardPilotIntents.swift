import AppIntents
import Foundation
import UIKit  // For UIApplication

struct CollectDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Collect Sensor Data"
    static var description = IntentDescription("Collects sensor data (excluding microphone) with WiFi and NFC info from Shortcuts")
    static var openAppWhenRun = true
    
    @Parameter(title: "WiFi Info", description: "WiFi SSID or network information", default: "")
    var wifi: String
    
    @Parameter(title: "NFC Info", description: "NFC tag UID or information", default: "")
    var nfc: String
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let urlString = "cardpilot://collect?sourceApp=Shortcuts&ssid=\(wifi)&nfc=\(nfc)&autoExit=true&silent=true&skipMicrophone=true"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
        }
        
        // Open the app with the URL to trigger collection
        await UIApplication.shared.open(url)
        
        return .result(dialog: IntentDialog("Started data collection with WiFi: \(wifi) and NFC: \(nfc). Microphone skipped."))
    }
}

// Make the intent available in Shortcuts app
struct CardPilotAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CollectDataIntent(),
            phrases: [
                "Collect sensor data using ${applicationName}",
                "Start data collection in ${applicationName}",
                "Record sensor data with ${applicationName}"
            ],
            shortTitle: "Collect Data",
            systemImageName: "sensor.tag.radiowaves.forward"
        )
    }
}