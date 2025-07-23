import Foundation

class ARPScanner {
    static func scanARPTable() -> [(ipAddress: String, macAddress: String)] {
        var results: [(ipAddress: String, macAddress: String)] = []
        
        let task = Process()
        task.launchPath = "/usr/sbin/arp"
        task.arguments = ["-a"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                results = parseARPOutput(output)
            }
            
            task.waitUntilExit()
        } catch {
            print("Error executing arp command: \(error.localizedDescription)")
        }
        
        return results
    }
    
    private static func parseARPOutput(_ output: String) -> [(ipAddress: String, macAddress: String)] {
        var results: [(ipAddress: String, macAddress: String)] = []
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            // Skip empty lines
            guard !line.isEmpty else { continue }
            
            // Parse IP address
            if let ipRange = line.range(of: "\\(([0-9\\.]+)\\)", options: .regularExpression) {
                let ipAddress = String(line[ipRange]).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                
                // Parse MAC address
                if let macRange = line.range(of: "at ([0-9a-f:]+)", options: .regularExpression) {
                    let macWithPrefix = String(line[macRange])
                    let macComponents = macWithPrefix.components(separatedBy: " ")
                    if macComponents.count > 1 {
                        let macAddress = macComponents[1]
                        
                        // Skip incomplete entries and broadcast addresses
                        if macAddress != "(incomplete)" && macAddress != "ff:ff:ff:ff:ff:ff" {
                            results.append((ipAddress: ipAddress, macAddress: macAddress))
                        }
                    }
                }
            }
        }
        
        return results
    }
}