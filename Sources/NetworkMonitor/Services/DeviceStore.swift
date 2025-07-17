import Foundation

class DeviceStore {
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var devicesFileURL: URL {
        documentsDirectory.appendingPathComponent("devices.json")
    }
    
    func saveDevices(_ devices: [NetworkDevice]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(devices)
            try data.write(to: devicesFileURL)
        } catch {
            print("Error saving devices: \(error)")
        }
    }
    
    func loadDevices() -> [NetworkDevice]? {
        guard fileManager.fileExists(atPath: devicesFileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: devicesFileURL)
            let decoder = JSONDecoder()
            return try decoder.decode([NetworkDevice].self, from: data)
        } catch {
            print("Error loading devices: \(error)")
            return nil
        }
    }
}