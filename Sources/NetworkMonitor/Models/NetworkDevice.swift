import Foundation

enum DeviceType: String, Codable, CaseIterable {
    case computer
    case mobile
    case iot
    case router
    case unknown
}

struct NetworkDevice: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var ipAddress: String
    var macAddress: String
    var type: DeviceType
    var isOnline: Bool
    var isImportant: Bool
    let firstSeen: Date
    var lastSeen: Date
    var tags: [String]
    var notes: String
    var vendor: String?
    
    init(id: UUID = UUID(), name: String, ipAddress: String, macAddress: String, 
         type: DeviceType = .unknown, isOnline: Bool = true, isImportant: Bool = false,
         tags: [String] = [], notes: String = "", vendor: String? = nil) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.type = type
        self.isOnline = isOnline
        self.isImportant = isImportant
        self.firstSeen = Date()
        self.lastSeen = Date()
        self.tags = tags
        self.notes = notes
        self.vendor = vendor ?? MacVendorDatabase.shared.lookupVendor(forMac: macAddress, isOnline: isOnline)
    }
    
    static func == (lhs: NetworkDevice, rhs: NetworkDevice) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}