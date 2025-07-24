import Foundation

class ARPScanner {
    static func scanARPTable() -> [(ipAddress: String, macAddress: String)] {
        var results: [(ipAddress: String, macAddress: String)] = []
        
        DebugLogger.shared.info("Starting ARP table scan...")
        
        // First, run a simple command to show the ARP command being used
        let debugTask = Process()
        debugTask.launchPath = "/bin/bash"
        debugTask.arguments = ["-c", "which arp"]
        
        let debugPipe = Pipe()
        debugTask.standardOutput = debugPipe
        
        do {
            try debugTask.run()
            let debugData = debugPipe.fileHandleForReading.readDataToEndOfFile()
            if let debugOutput = String(data: debugData, encoding: .utf8) {
                DebugLogger.shared.debug("ARP command path: \(debugOutput.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
            debugTask.waitUntilExit()
        } catch {
            DebugLogger.shared.warning("Could not determine arp command path: \(error.localizedDescription)")
        }
        
        // Now run the actual ARP command
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
        
        // Example line: ? (10.13.13.1) at 60:83:e7:3b:e0:8d on en1 ifscope [ethernet]
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            // Skip empty lines
            guard !line.isEmpty else { continue }
            
            DebugLogger.shared.debug("Processing ARP line: \(line)")
            
            // Simple parsing approach - split by spaces and extract components
            let components = line.components(separatedBy: " ")
            
            // Need at least 4 components for a valid entry
            guard components.count >= 4 else {
                DebugLogger.shared.debug("Line has too few components")
                continue
            }
            
            // Find the IP address component (in parentheses)
            var ipAddress = ""
            for component in components {
                if component.hasPrefix("(") && component.hasSuffix(")") {
                    ipAddress = component.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                    break
                }
            }
            
            if ipAddress.isEmpty {
                DebugLogger.shared.debug("No IP address found in line")
                continue
            }
            
            // Find the MAC address (after "at")
            var macAddress = ""
            if let atIndex = components.firstIndex(of: "at"), atIndex + 1 < components.count {
                macAddress = components[atIndex + 1]
            }
            
            if macAddress.isEmpty {
                DebugLogger.shared.debug("No MAC address found in line")
                continue
            }
            
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