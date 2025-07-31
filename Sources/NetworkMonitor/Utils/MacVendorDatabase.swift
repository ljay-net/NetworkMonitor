import Foundation

struct MacVendor: Codable {
    let prefix: String
    let vendor: String
}

class MacVendorDatabase {
    static let shared = MacVendorDatabase()
    private var vendors: [String: String] = [:] // OUI -> Vendor mapping
    private let cacheURL: URL
    private let apiBaseURL = "https://api.macvendors.com/"
    private var lastCacheUpdate: Date?
    private let cacheValidityDays = 30
    private var apiQueue: DispatchQueue
    private var pendingRequests: Set<String> = []
    private let apiCallInterval: TimeInterval = 1.1 // 1.1 seconds between calls (API limit is 1/sec)
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheURL = documentsPath.appendingPathComponent("mac_vendors_cache.json")
        apiQueue = DispatchQueue(label: "com.networkmonitor.macvendor", qos: .utility)
        loadCachedVendors()
    }
    
    func lookupVendor(forMac macAddress: String) -> String? {
        let oui = extractOUI(from: macAddress)
        guard !oui.isEmpty else { return nil }
        
        // Check local cache first
        if let cachedVendor = vendors[oui] {
            return cachedVendor
        }
        
        // Fetch from API asynchronously
        fetchVendorFromAPI(for: macAddress, oui: oui)
        
        // Return fallback vendor for common prefixes while API loads
        return getFallbackVendor(for: oui)
    }
    
    private func extractOUI(from macAddress: String) -> String {
        let normalizedMac = macAddress.replacingOccurrences(of: ":", with: "")
                                      .replacingOccurrences(of: "-", with: "")
                                      .replacingOccurrences(of: ".", with: "")
                                      .uppercased()
        
        guard normalizedMac.count >= 6 else { return "" }
        return String(normalizedMac.prefix(6))
    }
    
    private func loadCachedVendors() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            loadFallbackVendors()
            return
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let cache = try JSONDecoder().decode([String: String].self, from: data)
            vendors = cache
            
            // Check if cache needs refresh
            let attributes = try FileManager.default.attributesOfItem(atPath: cacheURL.path)
            if let modificationDate = attributes[.modificationDate] as? Date {
                lastCacheUpdate = modificationDate
                let daysSinceUpdate = Calendar.current.dateComponents([.day], from: modificationDate, to: Date()).day ?? 0
                if daysSinceUpdate > cacheValidityDays {
                    DebugLogger.shared.info("MAC vendor cache is \(daysSinceUpdate) days old, needs refresh")
                }
            }
        } catch {
            DebugLogger.shared.error("Failed to load vendor cache: \(error)")
            loadFallbackVendors()
        }
    }
    
    private func loadFallbackVendors() {
        vendors = [
            // Apple
            "001E52": "Apple", "001F5B": "Apple", "002241": "Apple", "002500": "Apple",
            "0026BB": "Apple", "E4CE8F": "Apple", "E0B9BA": "Apple", "D0E140": "Apple",
            "8C8EF2": "Apple", "F0DCE2": "Apple", "B8FF61": "Apple", "B88D12": "Apple",
            "B817C2": "Apple", "68967B": "Apple", "F02475": "Apple", "BC9FEF": "Apple",
            "F0B479": "Apple", "F41BA1": "Apple", "3035AD": "Apple", "E0B52D": "Apple",
            "D49A20": "Apple", "9CF48E": "Apple", "F0F61C": "Apple", "D8D1CB": "Apple",
            "B4F0AB": "Apple", "10417F": "Apple", "7CF05F": "Apple", "A8BBCF": "Apple",
            "90B21F": "Apple", "7CC537": "Apple", "F4F951": "Apple", "18AF61": "Apple",
            "C82A14": "Apple", "9CFC01": "Apple", "6C72E7": "Apple", "A4B197": "Apple",
            
            // Samsung
            "001C43": "Samsung", "001D25": "Samsung", "B0D0C5": "Samsung", "B0EC43": "Samsung",
            "B0C420": "Samsung", "B07234": "Samsung", "B04747": "Samsung", "B03456": "Samsung",
            
            // Intel
            "0024D7": "Intel", "001B21": "Intel", "0015F2": "Intel", "001E64": "Intel",
            "001F3C": "Intel", "002186": "Intel", "0022FB": "Intel", "002564": "Intel",
            
            // Cisco
            "001122": "Cisco", "000142": "Cisco", "000143": "Cisco", "000163": "Cisco",
            "000164": "Cisco", "000165": "Cisco", "000166": "Cisco", "000167": "Cisco",
            
            // TP-Link
            "001D0F": "TP-Link", "000AEB": "TP-Link", "001CA2": "TP-Link", "00904C": "TP-Link",
            "C46E1F": "TP-Link", "E8DE27": "TP-Link",
            
            // VMware
            "000C29": "VMware", "000569": "VMware", "001C14": "VMware", "005056": "VMware",
            
            // Google
            "001A11": "Google", "3C5AB4": "Google", "F4F5D8": "Google", "6C19C0": "Google",
            
            // Microsoft
            "001DD8": "Microsoft", "7C1E52": "Microsoft", "000D3A": "Microsoft", "001E3C": "Microsoft",
            
            // Netgear
            "001B2F": "Netgear", "002101": "Netgear", "0024B2": "Netgear", "002722": "Netgear",
            
            // D-Link
            "001195": "D-Link", "001346": "D-Link", "001CF0": "D-Link", "0015E9": "D-Link",
            
            // Belkin
            "002275": "Belkin", "001CDF": "Belkin", "EC1A59": "Belkin", "944452": "Belkin",
            
            // Broadcom
            "001018": "Broadcom", "000AF7": "Broadcom", "0010DB": "Broadcom", "001839": "Broadcom"
        ]
    }
    
    private func fetchVendorFromAPI(for macAddress: String, oui: String) {
        // Don't make duplicate requests for the same OUI
        guard !pendingRequests.contains(oui) else { return }
        
        // Use OUI format for API (first 6 characters with colons)
        let ouiFormatted = String(oui.prefix(2)) + ":" + String(oui.dropFirst(2).prefix(2)) + ":" + String(oui.dropFirst(4).prefix(2))
        guard let url = URL(string: apiBaseURL + ouiFormatted) else { return }
        
        pendingRequests.insert(oui)
        
        // Use the queue to ensure proper rate limiting
        apiQueue.asyncAfter(deadline: .now() + apiCallInterval) { [weak self] in
            guard let self = self else { return }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self else { return }
                
                defer {
                    DispatchQueue.main.async {
                        self.pendingRequests.remove(oui)
                    }
                }
                
                guard let data = data, error == nil else {
                    DebugLogger.shared.debug("API request failed for \(oui): \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let vendor = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                // Handle rate limiting and other API errors
                if vendor.contains("slow down") || vendor.contains("upgrade") || vendor.contains("rate limit") {
                    DebugLogger.shared.warning("API rate limited for \(oui), using fallback")
                    return
                }
                
                if vendor.isEmpty || vendor.contains("Not Found") {
                    DebugLogger.shared.debug("No vendor found for \(oui)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.vendors[oui] = vendor
                    self.saveCacheToFile()
                    DebugLogger.shared.info("Fetched vendor for \(oui): \(vendor)")
                }
            }.resume()
        }
    }
    
    private func getFallbackVendor(for oui: String) -> String? {
        // Return known vendors while API loads
        return vendors[oui]
    }
    
    private func saveCacheToFile() {
        do {
            let data = try JSONEncoder().encode(vendors)
            try data.write(to: cacheURL)
            lastCacheUpdate = Date()
        } catch {
            DebugLogger.shared.error("Failed to save vendor cache: \(error)")
        }
    }
    
    func refreshCache() {
        DebugLogger.shared.info("Refreshing MAC vendor cache...")
        vendors.removeAll()
        loadFallbackVendors()
        
        // Remove old cache file
        try? FileManager.default.removeItem(at: cacheURL)
    }
}