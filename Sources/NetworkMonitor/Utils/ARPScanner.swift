import Foundation

class ARPScanner {
    static func scanARPTable() -> [(ipAddress: String, macAddress: String)] {
        var results: [(ipAddress: String, macAddress: String)] = []
        
        print("Starting ARP table scan...")
        
        let task = Process()
        task.launchPath = "/usr/sbin/arp"
        task.arguments = ["-a"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("ARP output received: \n\(output)")
                results = parseARPOutput(output)
                print("Found \(results.count) devices in ARP table")
            } else {
                print("Failed to decode ARP output")
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
            
            // Format from your output: ? (10.13.13.1) at 60:83:e7:3b:e0:8d on en1 ifscope [ethernet]
            let components = line.components(separatedBy: " ")
            
            // Need at least 4 components: ? (ip) at mac
            guard components.count >= 4 else { continue }
            
            // Get IP address - format is (10.13.13.1)
            let ipComponent = components[1]
            let ipAddress = ipComponent.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            
            // Get MAC address - should be after "at"
            let atIndex = components.firstIndex(of: "at")
            guard let macIndex = atIndex, macIndex + 1 < components.count else { continue }
            
            let macAddress = components[macIndex + 1]
            
            // Skip incomplete entries and broadcast addresses
            if macAddress != "(incomplete)" && macAddress != "ff:ff:ff:ff:ff:ff" {
                print("Found device: \(ipAddress) with MAC: \(macAddress)")
                results.append((ipAddress: ipAddress, macAddress: macAddress))
            }
        }
        
        return results
    }
}