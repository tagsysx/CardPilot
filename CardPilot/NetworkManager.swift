//
//  NetworkManager.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import Foundation
import Network

class NetworkManager: ObservableObject {
    
    func getCurrentIPAddress() async -> String? {
        // Try to get the local IP address from network interfaces
        if let localIP = getLocalIPAddress() {
            return localIP
        }
        
        // Fallback: Get public IP address from external service
        return await getPublicIPAddress()
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "pdp_ip0" { // WiFi or Cellular
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
    
    private func getPublicIPAddress() async -> String? {
        guard let url = URL(string: "https://api.ipify.org") else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("Failed to get public IP address: \(error)")
            return nil
        }
    }
}
