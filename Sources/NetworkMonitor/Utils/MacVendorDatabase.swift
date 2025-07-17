import Foundation

struct MacVendor: Codable {
    let prefix: String
    let vendor: String
}

class MacVendorDatabase {
    static let shared = MacVendorDatabase()
    private var vendors: [MacVendor] = []
    
    private init() {
        loadVendorDatabase()
    }
    
    func lookupVendor(forMac macAddress: String) -> String? {
        // Normalize MAC address format
        let normalizedMac = macAddress.replacingOccurrences(of: ":", with: "")
                                      .replacingOccurrences(of: "-", with: "")
                                      .replacingOccurrences(of: ".", with: "")
                                      .uppercased()
        
        // Get first 6 characters (OUI)
        guard normalizedMac.count >= 6 else { return nil }
        let oui = String(normalizedMac.prefix(6))
        
        // Find matching vendor
        return vendors.first(where: { $0.prefix == oui })?.vendor
    }
    
    private func loadVendorDatabase() {
        // Start with a small set of common vendors
        vendors = [
            MacVendor(prefix: "000C29", vendor: "VMware"),
            MacVendor(prefix: "00005E", vendor: "IANA"),
            MacVendor(prefix: "000393", vendor: "Apple"),
            MacVendor(prefix: "0050C2", vendor: "IEEE"),
            MacVendor(prefix: "001122", vendor: "Cisco"),
            MacVendor(prefix: "001A11", vendor: "Google"),
            MacVendor(prefix: "001D0F", vendor: "TP-Link"),
            MacVendor(prefix: "001018", vendor: "Broadcom"),
            MacVendor(prefix: "001C43", vendor: "Samsung"),
            MacVendor(prefix: "001D25", vendor: "Samsung"),
            MacVendor(prefix: "001E52", vendor: "Apple"),
            MacVendor(prefix: "001F5B", vendor: "Apple"),
            MacVendor(prefix: "002241", vendor: "Apple"),
            MacVendor(prefix: "002500", vendor: "Apple"),
            MacVendor(prefix: "0026BB", vendor: "Apple"),
            MacVendor(prefix: "E4CE8F", vendor: "Apple"),
            MacVendor(prefix: "E0B9BA", vendor: "Apple"),
            MacVendor(prefix: "D0E140", vendor: "Apple"),
            MacVendor(prefix: "8C8EF2", vendor: "Apple"),
            MacVendor(prefix: "F0DCE2", vendor: "Apple"),
            MacVendor(prefix: "B8FF61", vendor: "Apple"),
            MacVendor(prefix: "B88D12", vendor: "Apple"),
            MacVendor(prefix: "B817C2", vendor: "Apple"),
            MacVendor(prefix: "68967B", vendor: "Apple"),
            MacVendor(prefix: "F02475", vendor: "Apple"),
            MacVendor(prefix: "BC9FEF", vendor: "Apple"),
            MacVendor(prefix: "F0B479", vendor: "Apple"),
            MacVendor(prefix: "F41BA1", vendor: "Apple"),
            MacVendor(prefix: "3035AD", vendor: "Apple"),
            MacVendor(prefix: "E0B52D", vendor: "Apple"),
            MacVendor(prefix: "D49A20", vendor: "Apple"),
            MacVendor(prefix: "9CF48E", vendor: "Apple"),
            MacVendor(prefix: "F0F61C", vendor: "Apple"),
            MacVendor(prefix: "D8D1CB", vendor: "Apple"),
            MacVendor(prefix: "B4F0AB", vendor: "Apple"),
            MacVendor(prefix: "10417F", vendor: "Apple"),
            MacVendor(prefix: "7CF05F", vendor: "Apple"),
            MacVendor(prefix: "A8BBCF", vendor: "Apple"),
            MacVendor(prefix: "90B21F", vendor: "Apple"),
            MacVendor(prefix: "7CC537", vendor: "Apple"),
            MacVendor(prefix: "F4F951", vendor: "Apple"),
            MacVendor(prefix: "18AF61", vendor: "Apple"),
            MacVendor(prefix: "C82A14", vendor: "Apple"),
            MacVendor(prefix: "9CFC01", vendor: "Apple"),
            MacVendor(prefix: "6C72E7", vendor: "Apple"),
            MacVendor(prefix: "001D0F", vendor: "TP-Link"),
            MacVendor(prefix: "000AEB", vendor: "TP-Link"),
            MacVendor(prefix: "001CA2", vendor: "ADB Broadband"),
            MacVendor(prefix: "002275", vendor: "Belkin"),
            MacVendor(prefix: "001CDF", vendor: "Belkin"),
            MacVendor(prefix: "00904C", vendor: "Epigram"),
            MacVendor(prefix: "001018", vendor: "Broadcom"),
            MacVendor(prefix: "0024D7", vendor: "Intel"),
            MacVendor(prefix: "000C29", vendor: "VMware"),
            MacVendor(prefix: "000569", vendor: "VMware"),
            MacVendor(prefix: "001C14", vendor: "VMware"),
            MacVendor(prefix: "005056", vendor: "VMware")
        ]
    }
}