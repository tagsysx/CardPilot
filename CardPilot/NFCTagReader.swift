//
//  NFCTagReader.swift
//  CardPilot
//
//  Created for NFC tag data reading functionality
//

import Foundation
import CoreNFC

class NFCTagReader: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var isReading = false
    @Published var lastReadData: String?
    @Published var readError: String?
    
    private var readerSession: NFCNDEFReaderSession?
    
    // MARK: - Public Methods
    
    func startReading() {
        guard NFCNDEFReaderSession.readingAvailable else {
            readError = "NFC reading not available on this device"
            return
        }
        
        readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        readerSession?.alertMessage = "Hold your iPhone near an NFC tag to read its contents"
        readerSession?.begin()
        isReading = true
        readError = nil
    }
    
    func stopReading() {
        readerSession?.invalidate()
        isReading = false
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            self.isReading = false
            
            var extractedData: [String] = []
            
            for message in messages {
                for record in message.records {
                    // Parse different types of NFC data
                    if let payload = String(data: record.payload, encoding: .utf8) {
                        let typeString = String(data: record.type, encoding: .utf8) ?? "Unknown"
                        extractedData.append("Type: \(typeString), Data: \(payload)")
                    }
                    
                    // Handle URL records
                    if record.typeNameFormat == .nfcWellKnown && record.type == Data("U".utf8) {
                        if let url = self.parseURLRecord(record.payload) {
                            extractedData.append("URL: \(url)")
                        }
                    }
                    
                    // Handle text records
                    if record.typeNameFormat == .nfcWellKnown && record.type == Data("T".utf8) {
                        if let text = self.parseTextRecord(record.payload) {
                            extractedData.append("Text: \(text)")
                        }
                    }
                }
            }
            
            self.lastReadData = extractedData.joined(separator: "\n")
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isReading = false
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    // User canceled - not an error
                    break
                case .readerSessionInvalidationErrorSessionTimeout:
                    self.readError = "NFC reading timed out"
                case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
                    self.readError = "NFC session terminated unexpectedly"
                case .readerSessionInvalidationErrorSystemIsBusy:
                    self.readError = "NFC system is busy"
                default:
                    self.readError = "NFC reading failed: \(nfcError.localizedDescription)"
                }
            } else {
                self.readError = "NFC reading failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseURLRecord(_ payload: Data) -> String? {
        guard payload.count > 1 else { return nil }
        
        let prefixByte = payload[0]
        let urlData = payload.dropFirst()
        
        let prefixes = [
            0x00: "",
            0x01: "http://www.",
            0x02: "https://www.",
            0x03: "http://",
            0x04: "https://",
            0x05: "tel:",
            0x06: "mailto:",
            0x07: "ftp://anonymous:anonymous@",
            0x08: "ftp://ftp.",
            0x09: "ftps://",
            0x0A: "sftp://",
            0x0B: "smb://",
            0x0C: "nfs://",
            0x0D: "ftp://",
            0x0E: "dav://",
            0x0F: "news:",
            0x10: "telnet://",
            0x11: "imap:",
            0x12: "rtsp://",
            0x13: "urn:",
            0x14: "pop:",
            0x15: "sip:",
            0x16: "sips:",
            0x17: "tftp:",
            0x18: "btspp://",
            0x19: "btl2cap://",
            0x1A: "btgoep://",
            0x1B: "tcpobex://",
            0x1C: "irdaobex://",
            0x1D: "file://",
            0x1E: "urn:epc:id:",
            0x1F: "urn:epc:tag:",
            0x20: "urn:epc:pat:",
            0x21: "urn:epc:raw:",
            0x22: "urn:epc:",
            0x23: "urn:nfc:"
        ]
        
        let prefix = prefixes[Int(prefixByte)] ?? ""
        let urlString = String(data: urlData, encoding: .utf8) ?? ""
        
        return prefix + urlString
    }
    
    private func parseTextRecord(_ payload: Data) -> String? {
        guard payload.count > 1 else { return nil }
        
        let statusByte = payload[0]
        let languageCodeLength = Int(statusByte & 0x3F)
        
        guard payload.count > 1 + languageCodeLength else { return nil }
        
        let textData = payload.dropFirst(1 + languageCodeLength)
        return String(data: textData, encoding: .utf8)
    }
}

// MARK: - NFC Data Structure for Storage

struct NFCTagData: Codable {
    let timestamp: Date
    let tagType: String
    let content: String
    let rawData: Data?
    
    init(content: String, tagType: String = "NDEF", rawData: Data? = nil) {
        self.timestamp = Date()
        self.content = content
        self.tagType = tagType
        self.rawData = rawData
    }
}
