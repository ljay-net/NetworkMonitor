import XCTest
@testable import NetworkMonitor

final class DataExporterTests: XCTestCase {
    var testDevices: [NetworkDevice]!
    
    override func setUp() {
        super.setUp()
        
        // Create test devices
        testDevices = [
            NetworkDevice(
                name: "Test Router",
                ipAddress: "192.168.1.1",
                macAddress: "aa:bb:cc:dd:ee:ff",
                type: .router,
                isImportant: true,
                tags: ["network", "important"]
            ),
            NetworkDevice(
                name: "Test Computer",
                ipAddress: "192.168.1.2",
                macAddress: "11:22:33:44:55:66",
                type: .computer,
                tags: ["work"]
            )
        ]
    }
    
    override func tearDown() {
        testDevices = nil
        super.tearDown()
    }
    
    func testExportToCSV() {
        let csv = DataExporter.exportDevicesToCSV(testDevices)
        
        // Check if CSV contains headers
        XCTAssertTrue(csv.contains("Name,IP Address,MAC Address,Type,Status"), "CSV should contain headers")
        
        // Check if CSV contains device data
        XCTAssertTrue(csv.contains("Test Router,192.168.1.1,aa:bb:cc:dd:ee:ff,router"), "CSV should contain router data")
        XCTAssertTrue(csv.contains("Test Computer,192.168.1.2,11:22:33:44:55:66,computer"), "CSV should contain computer data")
        
        // Check if CSV contains tags
        XCTAssertTrue(csv.contains("network; important"), "CSV should contain router tags")
        XCTAssertTrue(csv.contains("work"), "CSV should contain computer tags")
    }
    
    func testExportToJSON() {
        let jsonData = DataExporter.exportDevicesToJSON(testDevices)
        
        XCTAssertNotNil(jsonData, "JSON data should not be nil")
        
        if let jsonData = jsonData {
            // Try to decode the JSON back to devices
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedDevices = try decoder.decode([NetworkDevice].self, from: jsonData)
                
                XCTAssertEqual(decodedDevices.count, testDevices.count, "Should decode the same number of devices")
                
                // Check if the first device is the same
                XCTAssertEqual(decodedDevices[0].id, testDevices[0].id)
                XCTAssertEqual(decodedDevices[0].name, testDevices[0].name)
                XCTAssertEqual(decodedDevices[0].ipAddress, testDevices[0].ipAddress)
                XCTAssertEqual(decodedDevices[0].tags, testDevices[0].tags)
                
            } catch {
                XCTFail("Failed to decode JSON: \(error)")
            }
        }
    }
}