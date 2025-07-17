import Foundation

class DataExporter {
    static func exportDevicesToCSV(_ devices: [NetworkDevice]) -> String {
        var csvString = "Name,IP Address,MAC Address,Vendor,Type,Status,First Seen,Last Seen,Important,Tags,Notes\n"
        
        for device in devices {
            let status = device.isOnline ? "Online" : "Offline"
            let important = device.isImportant ? "Yes" : "No"
            let tags = device.tags.joined(separator: "; ")
            
            // Escape quotes in notes and wrap in quotes
            let escapedNotes = device.notes.replacingOccurrences(of: "\"", with: "\"\"")
            let quotedNotes = "\"\(escapedNotes)\""
            
            let row = [
                device.name,
                device.ipAddress,
                device.macAddress,
                device.vendor ?? "Unknown",
                device.type.rawValue,
                status,
                formatDate(device.firstSeen),
                formatDate(device.lastSeen),
                important,
                tags,
                quotedNotes
            ].joined(separator: ",")
            
            csvString.append(row + "\n")
        }
        
        return csvString
    }
    
    static func exportDevicesToJSON(_ devices: [NetworkDevice]) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        return try? encoder.encode(devices)
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}