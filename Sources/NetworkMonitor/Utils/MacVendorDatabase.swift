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
    private let apiCallInterval: TimeInterval = 2.0 // 2 seconds between calls to be safe
    private var dailyRequestCount: Int = 0
    private var lastRequestDate: Date?
    private let maxDailyRequests = 900 // Stay under 1000 limit
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheURL = documentsPath.appendingPathComponent("mac_vendors_cache.json")
        apiQueue = DispatchQueue(label: "com.networkmonitor.macvendor", qos: .utility)
        loadCachedVendors()
    }
    
    func lookupVendor(forMac macAddress: String, isOnline: Bool = false, forceAPI: Bool = false) -> String? {
        let oui = extractOUI(from: macAddress)
        guard !oui.isEmpty else { return nil }
        
        // Check local cache first
        if let cachedVendor = vendors[oui] {
            return cachedVendor
        }
        
        // ONLY make API calls when explicitly forced by user
        if forceAPI && shouldFetchFromAPI() {
            DebugLogger.shared.info("Manual API lookup requested for OUI: \(oui)")
            fetchVendorFromAPI(for: macAddress, oui: oui)
        }
        
        // Return nil if not in cache - no automatic API calls
        return nil
    }
    
    private func shouldFetchFromAPI() -> Bool {
        // Reset daily counter if it's a new day
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = lastRequestDate {
            let lastRequestDay = Calendar.current.startOfDay(for: lastDate)
            if today > lastRequestDay {
                dailyRequestCount = 0
            }
        }
        
        return dailyRequestCount < maxDailyRequests
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
        // Clear any existing cache to start fresh
        try? FileManager.default.removeItem(at: cacheURL)
        
        // Start with empty database
        loadFallbackVendors()
        
        DebugLogger.shared.info("Cleared vendor cache - starting fresh")
    }
    
    private func loadFallbackVendors() {
        // Start with empty database - rely only on API and cache
        vendors = [:]
        DebugLogger.shared.info("Starting with empty vendor database - will use API only")
    }
    
    private func fetchVendorFromAPI(for macAddress: String, oui: String) {
        // API calls completely disabled to prevent rate limiting
        DebugLogger.shared.info("API calls disabled - vendor lookup for \(oui) skipped")
        return
    }
    
    private func getFallbackVendor(for oui: String) -> String? {
        // Return only cached results from previous API calls
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
        DebugLogger.shared.info("Clearing MAC vendor cache...")
        vendors.removeAll()
        
        // Remove old cache file
        try? FileManager.default.removeItem(at: cacheURL)
        
        DebugLogger.shared.info("Vendor cache cleared - no API calls will be made")
    }
}