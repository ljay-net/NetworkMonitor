import Foundation

struct MacVendor: Codable {
    let prefix: String
    let vendor: String
}

extension Notification.Name {
    static let vendorDataUpdated = Notification.Name("vendorDataUpdated")
}

class MacVendorDatabase {
    static let shared = MacVendorDatabase()
    private var vendors: [String: String] = [:] // OUI -> Vendor mapping
    private let cacheURL: URL
    private let counterURL: URL
    private let apiBaseURL = "https://api.macvendors.com/"
    private var lastCacheUpdate: Date?
    private let cacheValidityDays = 30
    private var apiQueue: DispatchQueue
    private var requestQueue: [(oui: String, macAddress: String)] = []
    private var pendingRequests: Set<String> = []
    private let apiCallInterval: TimeInterval = 2.1 // 2.1 seconds between calls
    private var dailyRequestCount: Int = 0
    private var lastRequestDate: Date?
    private let maxDailyRequests = 950 // Stay well under 1000 limit
    private var isProcessingQueue = false
    weak var networkManager: NetworkManager?
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheURL = documentsPath.appendingPathComponent("mac_vendors_cache.json")
        counterURL = documentsPath.appendingPathComponent("api_counter.json")
        apiQueue = DispatchQueue(label: "com.networkmonitor.macvendor", qos: .utility)
        loadAPICounter()
        loadCachedVendors()
    }
    
    func lookupVendor(forMac macAddress: String, isOnline: Bool = false, forceAPI: Bool = false) -> String? {
        let oui = extractOUI(from: macAddress)
        guard !oui.isEmpty else { return nil }
        
        // Always return cached data if available
        if let cachedVendor = vendors[oui] {
            return cachedVendor
        }
        
        // Queue API request for online devices or when forced
        if (isOnline || forceAPI) && shouldFetchFromAPI() && !pendingRequests.contains(oui) {
            DebugLogger.shared.info("Queueing vendor lookup for \(oui) (online: \(isOnline), forced: \(forceAPI))")
            queueAPIRequest(oui: oui, macAddress: macAddress)
        }
        
        // Return nil if not cached - device will show "Loading..."
        return nil
    }
    
    func getCachedVendor(forMac macAddress: String) -> String? {
        let oui = extractOUI(from: macAddress)
        return vendors[oui]
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
    
    func extractOUI(from macAddress: String) -> String {
        // Normalize MAC address format and ensure leading zeros
        let cleanMac = macAddress.replacingOccurrences(of: ":", with: "")
                                 .replacingOccurrences(of: "-", with: "")
                                 .replacingOccurrences(of: ".", with: "")
                                 .uppercased()
        
        guard cleanMac.count >= 6 else { return "" }
        
        // Take first 6 characters and ensure proper formatting
        let oui = String(cleanMac.prefix(6))
        
        // Pad with leading zeros if needed (shouldn't happen but safety check)
        let paddedOUI = String(format: "%06@", oui)
        
        return paddedOUI
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
    
    private func queueAPIRequest(oui: String, macAddress: String) {
        requestQueue.append((oui: oui, macAddress: macAddress))
        pendingRequests.insert(oui)
        
        if !isProcessingQueue {
            processRequestQueue()
        }
    }
    
    private func processRequestQueue() {
        guard !requestQueue.isEmpty, !isProcessingQueue else { return }
        
        isProcessingQueue = true
        
        let request = requestQueue.removeFirst()
        let oui = request.oui
        let macAddress = request.macAddress
        
        // Calculate delay based on last request
        let delay: TimeInterval
        if let lastDate = lastRequestDate {
            let timeSinceLastRequest = Date().timeIntervalSince(lastDate)
            delay = max(0, apiCallInterval - timeSinceLastRequest)
        } else {
            delay = 0
        }
        
        apiQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.makeAPIRequest(oui: oui, macAddress: macAddress)
        }
    }
    
    private func makeAPIRequest(oui: String, macAddress: String) {
        guard shouldFetchFromAPI() else {
            DebugLogger.shared.warning("Daily API limit reached, skipping request for \(oui)")
            completeRequest(oui: oui)
            return
        }
        
        let ouiFormatted = String(oui.prefix(2)) + ":" + String(oui.dropFirst(2).prefix(2)) + ":" + String(oui.dropFirst(4).prefix(2))
        guard let url = URL(string: apiBaseURL + ouiFormatted) else {
            completeRequest(oui: oui)
            return
        }
        
        dailyRequestCount += 1
        lastRequestDate = Date()
        saveAPICounter()
        
        DebugLogger.shared.info("API request \(dailyRequestCount)/\(maxDailyRequests) for \(oui)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            defer {
                self.completeRequest(oui: oui)
            }
            
            // Log HTTP response details
            if let httpResponse = response as? HTTPURLResponse {
                DebugLogger.shared.debug("API response for \(oui): HTTP \(httpResponse.statusCode)")
            }
            
            guard let data = data, error == nil else {
                DebugLogger.shared.error("API request failed for \(oui): \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let vendor = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            DebugLogger.shared.info("API response for \(oui): '\(vendor)'")
            
            if vendor.contains("slow down") || vendor.contains("upgrade") || vendor.contains("rate limit") {
                DebugLogger.shared.warning("API rate limited for \(oui): \(vendor)")
                return
            }
            
            if vendor.contains("Not Found") {
                DebugLogger.shared.info("Vendor not found for \(oui) - setting to Unknown")
                DispatchQueue.main.async {
                    self.vendors[oui] = "Unknown"
                    self.saveCacheToFile()
                    self.networkManager?.updateDevicesWithVendor(oui: oui, vendor: "Unknown")
                }
                return
            }
            
            if !vendor.isEmpty {
                DispatchQueue.main.async {
                    self.vendors[oui] = vendor
                    self.saveCacheToFile()
                    DebugLogger.shared.info("Cached vendor for \(oui): \(vendor)")
                    
                    // Update devices directly
                    self.networkManager?.updateDevicesWithVendor(oui: oui, vendor: vendor)
                }
            } else {
                DebugLogger.shared.warning("Empty response for \(oui)")
            }
        }.resume()
    }
    
    private func completeRequest(oui: String) {
        DispatchQueue.main.async { [weak self] in
            self?.pendingRequests.remove(oui)
            self?.isProcessingQueue = false
            
            // Process next request if queue not empty
            if !(self?.requestQueue.isEmpty ?? true) {
                self?.processRequestQueue()
            }
        }
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
    
    private func loadAPICounter() {
        guard let data = try? Data(contentsOf: counterURL),
              let counter = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        if let count = counter["dailyRequestCount"] as? Int {
            dailyRequestCount = count
        }
        
        if let dateString = counter["lastRequestDate"] as? String,
           let date = ISO8601DateFormatter().date(from: dateString) {
            lastRequestDate = date
        }
        
        DebugLogger.shared.info("Loaded API counter: \(dailyRequestCount) requests today")
    }
    
    private func saveAPICounter() {
        let counter: [String: Any] = [
            "dailyRequestCount": dailyRequestCount,
            "lastRequestDate": ISO8601DateFormatter().string(from: lastRequestDate ?? Date())
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: counter)
            try data.write(to: counterURL)
        } catch {
            DebugLogger.shared.error("Failed to save API counter: \(error)")
        }
    }
}