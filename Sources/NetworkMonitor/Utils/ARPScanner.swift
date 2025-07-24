import Foundation

class ARPScanner {
    static func scanARPTable() -> [(ipAddress: String, macAddress: String)] {
        var results: [(ipAddress: String, macAddress: String)] = []
        
        DebugLogger.shared.info("Starting ARP table scan...")
        
        let task = Process()
        task.launchPath = "/usr/sbin/arp"
        task.arguments = ["-a"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                DebugLogger.shared.debug("ARP output received: \n\(output)")
                results = parseARPOutput(output)
                DebugLogger.shared.info("Found \(results.count) devices in ARP table")
            } else {
                DebugLogger.shared.error("Failed to decode ARP output")
            }
            
            task.waitUntilExit()
        } catch {
            DebugLogger.shared.error("Error executing arp command: \(error.localizedDescription)")
        }
        
        return results
    }
    
    private static func parseARPOutput(_ output: String) -> [(ipAddress: String, macAddress: String)] {
        var results: [(ipAddress: String, macAddress: String)] = []
        
        DebugLogger.shared.debug("Parsing ARP output...")
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            // Skip empty lines
            guard !line.isEmpty else { continue }
            
            DebugLogger.shared.debug("Processing ARP line: \(line)")
            
            // Extract IP address - it's usually in parentheses like (10.13.13.1)
            guard let ipRange = line.range(of: "\\([0-9\\.]+\\)") else {
                DebugLogger.shared.debug("No IP address found in line")
                continue
            }
            
            let ipWithParens = String(line[ipRange])
            let ipAddress = ipWithParens.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            
            // Extract MAC address - it's usually after "at" and before "on"
            guard let atRange = line.range(of: "at ") else {
                DebugLogger.shared.debug("No 'at' marker found for MAC address")
                continue
            }
            
            let afterAt = String(line[atRange.upperBound...])
            let macComponents = afterAt.components(separatedBy: " ")
            guard !macComponents.isEmpty else {
                DebugLogger.shared.debug("No MAC address found after 'at'")
                continue
            }
            
            let macAddress = macComponents[0]
            
            // Skip incomplete entries and broadcast addresses
            if macAddress != "(incomplete)" && !macAddress.lowercased().contains("ff:ff:ff:ff:ff:ff") {
                DebugLogger.shared.info("Found device: \(ipAddress) with MAC: \(macAddress)")
                results.append((ipAddress: ipAddress, macAddress: macAddress))
            } else {
                DebugLogger.shared.debug("Skipping incomplete or broadcast MAC: \(macAddress)")
            }
        }
        
        return results
    }
}