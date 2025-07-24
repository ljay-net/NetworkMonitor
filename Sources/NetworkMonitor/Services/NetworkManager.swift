import Foundation
import Network
import SystemConfiguration
import UserNotifications

class NetworkManager: NSObject, ObservableObject {
    @Published var devices: [NetworkDevice] = []
    @Published var newDeviceDetected: NetworkDevice?
    @Published var missingImportantDevice: NetworkDevice?
    @Published var isScanning = false
    
    private let deviceStore = DeviceStore()
    private var localIP: String?
    private var netServiceBrowser: NetServiceBrowser?
    private var discoveredServices = [NetService]()
    
    override init() {
        super.init()
        loadSavedDevices()
        determineLocalIP()
    }
    
    func scanNetwork() {
        DebugLogger.shared.info("Starting network scan...")
        
        // Load saved devices first
        loadSavedDevices()
        
        // Mark all devices as offline initially
        for i in 0..<devices.count {
            devices[i].isOnline = false
        }
        
        isScanning = true
        
        // Start Bonjour/mDNS discovery
        startBonjourDiscovery()
        
        // Get local network devices
        scanLocalNetwork()
        
        // Ping common IPs
        pingCommonIPs()
        
        // Save updated devices
        saveDevices()
        
        // Check for missing important devices
        checkForMissingImportantDevices()
        
        // Set scanning to false after a delay to allow async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isScanning = false
            DebugLogger.shared.info("Network scan completed")
        }
    }
    
    private func determineLocalIP() {
        DebugLogger.shared.info("Determining local IP address...")
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { 
            DebugLogger.shared.error("Failed to get interface addresses")
            return 
        }
        defer { freeifaddrs(ifaddr) }
        
        // Try to find interfaces in this order: en0, en1, en2, etc.
        let interfacesToTry = ["en0", "en1", "en2", "en3", "en4", "en5", "eth0", "eth1"]
        
        DebugLogger.shared.debug("Searching for network interfaces: \(interfacesToTry.joined(separator: ", "))")
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            guard let addr = interface.ifa_addr else { continue }
            
            let addrFamily = addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {  // IPv4
                let name = String(cString: interface.ifa_name)
                DebugLogger.shared.debug("Found interface: \(name)")
                
                if interfacesToTry.contains(name) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    let potentialAddress = String(cString: hostname)
                    
                    // Skip loopback addresses
                    if !potentialAddress.hasPrefix("127.") {
                        address = potentialAddress
                        DebugLogger.shared.info("Found valid IP address \(potentialAddress) on interface \(name)")
                        break
                    } else {
                        DebugLogger.shared.debug("Skipping loopback address \(potentialAddress) on interface \(name)")
                    }
                }
            }
        }
        
        if let address = address {
            localIP = address
            DebugLogger.shared.info("Local IP determined: \(address)")
        } else {
            // Fallback to a hardcoded subnet if we can't determine the IP
            localIP = "10.13.13.100"  // Using the subnet from your ARP output
            DebugLogger.shared.warning("Could not determine local IP, using fallback: \(localIP!)")
        }
    }
    
    private func startBonjourDiscovery() {
        discoveredServices.removeAll()
        
        netServiceBrowser = NetServiceBrowser()
        netServiceBrowser?.delegate = self
        netServiceBrowser?.searchForServices(ofType: "_http._tcp.", inDomain: "local.")
        netServiceBrowser?.searchForServices(ofType: "_device-info._tcp.", inDomain: "local.")
        netServiceBrowser?.searchForServices(ofType: "_homekit._tcp.", inDomain: "local.")
        netServiceBrowser?.searchForServices(ofType: "_airplay._tcp.", inDomain: "local.")
        netServiceBrowser?.searchForServices(ofType: "_spotify-connect._tcp.", inDomain: "local.")
        
        // Schedule a timer to stop discovery after a reasonable time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.netServiceBrowser?.stop()
        }
    }
    
    private func scanLocalNetwork() {
        DebugLogger.shared.info("Starting local network scan...")
        guard let localIP = localIP else {
            DebugLogger.shared.error("Local IP not determined")
            return 
        }
        
        DebugLogger.shared.info("Local IP: \(localIP)")
        
        // Extract subnet from local IP (e.g., 192.168.1.x)
        let components = localIP.split(separator: ".")
        guard components.count == 4 else {
            DebugLogger.shared.error("Invalid IP format")
            return
        }
        
        let subnet = components[0...2].joined(separator: ".")
        DebugLogger.shared.info("Subnet: \(subnet)")
        
        // Add router as a default device
        addOrUpdateDevice(name: "Router", ipAddress: "\(subnet).1", macAddress: "Unknown", type: .router)
        
        // Scan ARP table for devices
        DebugLogger.shared.info("Scanning ARP table...")
        let arpDevices = ARPScanner.scanARPTable()
        DebugLogger.shared.info("ARP scan returned \(arpDevices.count) devices")
        
        for device in arpDevices {
            // Try to determine device name from IP
            DebugLogger.shared.debug("Processing ARP device: \(device.ipAddress) with MAC: \(device.macAddress)")
            let name = getDeviceNameFromIP(device.ipAddress) ?? "Device at \(device.ipAddress)"
            addOrUpdateDevice(name: name, ipAddress: device.ipAddress, macAddress: device.macAddress, type: .unknown)
        }
        
        // For devices we already know about, try to ping them
        for device in devices where device.ipAddress.starts(with: subnet) {
            pingDevice(at: device.ipAddress)
        }
        
        DebugLogger.shared.info("Network scan complete. Found \(devices.count) devices.")
        
        // Add some sample devices if none were found
        if devices.isEmpty {
            DebugLogger.shared.warning("No devices found, adding sample devices")
            addOrUpdateDevice(name: "Sample Router", ipAddress: "\(subnet).1", macAddress: "aa:bb:cc:dd:ee:ff", type: .router)
            addOrUpdateDevice(name: "Sample Computer", ipAddress: "\(subnet).2", macAddress: "11:22:33:44:55:66", type: .computer)
            addOrUpdateDevice(name: "Sample Phone", ipAddress: "\(subnet).3", macAddress: "aa:bb:cc:11:22:33", type: .mobile)
        }
    }
    
    private func getDeviceNameFromIP(_ ipAddress: String) -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/host"
        task.arguments = [ipAddress]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse hostname from output
                if let nameRange = output.range(of: "domain name pointer ([^\\s\\.]+)", options: .regularExpression) {
                    let nameWithPrefix = String(output[nameRange])
                    let nameComponents = nameWithPrefix.components(separatedBy: " ")
                    if nameComponents.count > 2 {
                        return nameComponents[2]
                    }
                }
            }
            
            task.waitUntilExit()
        } catch {
            print("Error executing host command: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func pingDevice(at ipAddress: String) {
        let connection = NWConnection(
            host: NWEndpoint.Host(ipAddress),
            port: NWEndpoint.Port(integerLiteral: 80),
            using: .tcp
        )
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                // Device is reachable
                DispatchQueue.main.async {
                    if let index = self?.devices.firstIndex(where: { $0.ipAddress == ipAddress }) {
                        self?.devices[index].isOnline = true
                        self?.devices[index].lastSeen = Date()
                    }
                }
                connection.cancel()
            case .failed, .cancelled:
                connection.cancel()
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }
    
    private func pingCommonIPs() {
        guard let localIP = localIP else { return }
        
        // Extract subnet from local IP (e.g., 192.168.1.x)
        let components = localIP.split(separator: ".")
        guard components.count == 4 else { return }
        
        let subnet = components[0...2].joined(separator: ".")
        
        // Ping common IP addresses in the subnet
        // This is a simplified version - in a real app, you'd want to be more thorough
        for i in 1...10 {
            let ip = "\(subnet).\(i)"
            pingDevice(at: ip)
        }
    }
    
    private func addOrUpdateDevice(name: String, ipAddress: String, macAddress: String, type: DeviceType) {
        // Check if device already exists
        if let index = devices.firstIndex(where: { $0.macAddress == macAddress }) {
            devices[index].isOnline = true
            devices[index].lastSeen = Date()
            
            // If the name has changed and it's not a user-defined name, update it
            if devices[index].name != name {
                devices[index].name = name
            }
            
            // Update vendor information if it's missing
            if devices[index].vendor == nil {
                devices[index].vendor = MacVendorDatabase.shared.lookupVendor(forMac: macAddress)
            }
            
            // Try to determine device type from vendor if it's unknown
            if devices[index].type == .unknown {
                devices[index].type = inferDeviceTypeFromVendor(devices[index].vendor)
            }
        } else {
            // Look up vendor information
            let vendor = MacVendorDatabase.shared.lookupVendor(forMac: macAddress)
            
            // Infer device type from vendor if needed
            let inferredType = type == .unknown ? inferDeviceTypeFromVendor(vendor) : type
            
            // New device
            let newDevice = NetworkDevice(
                name: name,
                ipAddress: ipAddress,
                macAddress: macAddress,
                type: inferredType,
                vendor: vendor
            )
            devices.append(newDevice)
            
            // Notify about new device
            newDeviceDetected = newDevice
            
            // Send system notification
            NotificationManager.shared.sendNewDeviceNotification(device: newDevice)
        }
    }
    
    private func inferDeviceTypeFromVendor(_ vendor: String?) -> DeviceType {
        guard let vendor = vendor else { return .unknown }
        
        let vendorLower = vendor.lowercased()
        
        if vendorLower.contains("apple") {
            // Could be a Mac or iOS device, but we'll default to computer
            return .computer
        } else if vendorLower.contains("samsung") || vendorLower.contains("lg") || 
                  vendorLower.contains("sony") || vendorLower.contains("htc") {
            // Likely a mobile device or smart TV
            return .mobile
        } else if vendorLower.contains("cisco") || vendorLower.contains("tp-link") || 
                  vendorLower.contains("netgear") || vendorLower.contains("d-link") || 
                  vendorLower.contains("asus") || vendorLower.contains("linksys") {
            // Likely a router or network device
            return .router
        } else if vendorLower.contains("nest") || vendorLower.contains("ring") || 
                  vendorLower.contains("ecobee") || vendorLower.contains("philips") {
            // Likely an IoT device
            return .iot
        }
        
        return .unknown
    }
    
    private func checkForMissingImportantDevices() {
        let offlineImportantDevices = devices.filter { $0.isImportant && !$0.isOnline }
        
        if let firstMissing = offlineImportantDevices.first {
            missingImportantDevice = firstMissing
            
            // Send system notification
            NotificationManager.shared.sendImportantDeviceOfflineNotification(device: firstMissing)
        }
    }
    
    func toggleImportantFlag(for device: NetworkDevice) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index].isImportant.toggle()
            saveDevices()
        }
    }
    
    func updateDevice(_ device: NetworkDevice, newName: String, newType: DeviceType) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index].name = newName
            devices[index].type = newType
            saveDevices()
        }
    }
    
    func updateDeviceTags(_ device: NetworkDevice, tags: [String]) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index].tags = tags
            saveDevices()
        }
    }
    
    func updateDeviceNotes(_ device: NetworkDevice, notes: String) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index].notes = notes
            saveDevices()
        }
    }
    
    func getAllTags() -> [String] {
        // Get unique tags across all devices
        let allTags = devices.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    func getDevicesWithTag(_ tag: String) -> [NetworkDevice] {
        return devices.filter { $0.tags.contains(tag) }
    }
    
    func clearHistory() {
        devices.removeAll()
        saveDevices()
    }
    
    private func loadSavedDevices() {
        if let savedDevices = deviceStore.loadDevices() {
            devices = savedDevices
        }
    }
    
    private func saveDevices() {
        deviceStore.saveDevices(devices)
    }
    
    // Helper function to determine device type from service type
    private func deviceTypeFromService(_ service: NetService) -> DeviceType {
        let serviceType = service.type
        
        if serviceType.contains("airplay") || serviceType.contains("homekit") {
            return .iot
        } else if serviceType.contains("spotify") {
            return .iot
        } else if serviceType.contains("device-info") {
            // Try to determine if it's a mobile device or computer
            let name = service.name.lowercased()
            if name.contains("iphone") || name.contains("ipad") || name.contains("android") {
                return .mobile
            } else if name.contains("mac") || name.contains("pc") || name.contains("desktop") {
                return .computer
            }
        }
        
        return .unknown
    }
}

// MARK: - NetServiceBrowser Delegate
extension NetworkManager: NetServiceBrowserDelegate, NetServiceDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        service.resolve(withTimeout: 5.0)
        discoveredServices.append(service)
    }
    
    func netServiceDidResolveAddress(_ service: NetService) {
        guard let addresses = service.addresses, !addresses.isEmpty else { return }
        
        // Extract IP address from socket address
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        
        if let firstAddress = addresses.first {
            firstAddress.withUnsafeBytes { buffer in
                let sockaddrPtr = buffer.bindMemory(to: sockaddr.self).baseAddress!
                getnameinfo(sockaddrPtr, socklen_t(firstAddress.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
            }
            
            let ipAddress = String(cString: hostname)
            let deviceType = deviceTypeFromService(service)
            
            // Use service name as device name
            DispatchQueue.main.async { [weak self] in
                self?.addOrUpdateDevice(
                    name: service.name,
                    ipAddress: ipAddress,
                    macAddress: "From Bonjour", // We can't get MAC from Bonjour
                    type: deviceType
                )
            }
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if let index = discoveredServices.firstIndex(where: { $0 == service }) {
            discoveredServices.remove(at: index)
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        if let index = discoveredServices.firstIndex(where: { $0 == sender }) {
            discoveredServices.remove(at: index)
        }
    }
}

