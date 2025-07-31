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
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheURL = documentsPath.appendingPathComponent("mac_vendors_cache.json")
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
            "000C29": "VMware",
            "001E52": "Apple",
            "001F5B": "Apple",
            "002241": "Apple",
            "E4CE8F": "Apple",
            "F0DCE2": "Apple",
            "B8FF61": "Apple",
            "001D0F": "TP-Link",
            "001C43": "Samsung",
            "0024D7": "Intel",
            "001122": "Cisco"
        ]
    }
    
    private func fetchVendorFromAPI(for macAddress: String, oui: String) {
        guard let url = URL(string: apiBaseURL + macAddress) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let vendor = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !vendor.isEmpty,
                  !vendor.contains("Not Found") else {
                DebugLogger.shared.debug("Failed to fetch vendor for \(oui): \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.vendors[oui] = vendor
                self.saveCacheToFile()
                DebugLogger.shared.info("Fetched vendor for \(oui): \(vendor)")
            }
        }.resume()
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