import XCTest
@testable import NetworkMonitor

final class DeviceStoreTests: XCTestCase {
    var deviceStore: DeviceStore!
    var testDevices: [NetworkDevice]!
    
    override func setUp() {
        super.setUp()
        deviceStore = DeviceStore()
        
        // Create test devices
        testDevices = [
            NetworkDevice(
                name: "Test Router",
                ipAddress: "192.168.1.1",
                macAddress: "aa:bb:cc:dd:ee:ff",
                type: .router,
                isImportant: true
            ),
            NetworkDevice(
                name: "Test Computer",
                ipAddress: "192.168.1.2",
                macAddress: "11:22:33:44:55:66",
                type: .computer
            )
        ]
    }
    
    override func tearDown() {
        deviceStore = nil
        testDevices = nil
        super.tearDown()
    }
    
    func testSaveAndLoadDevices() {
        // Save devices
        deviceStore.saveDevices(testDevices)
        
        // Load devices
        let loadedDevices = deviceStore.loadDevices()
        
        XCTAssertNotNil(loadedDevices, "Loaded devices should not be nil")
        XCTAssertEqual(loadedDevices?.count, testDevices.count, "Should load the same number of devices")
        
        // Check if the first device is the same
        if let firstLoaded = loadedDevices?.first, let firstTest = testDevices.first {
            XCTAssertEqual(firstLoaded.id, firstTest.id)
            XCTAssertEqual(firstLoaded.name, firstTest.name)
            XCTAssertEqual(firstLoaded.ipAddress, firstTest.ipAddress)
            XCTAssertEqual(firstLoaded.macAddress, firstTest.macAddress)
            XCTAssertEqual(firstLoaded.type, firstTest.type)
            XCTAssertEqual(firstLoaded.isImportant, firstTest.isImportant)
        } else {
            XCTFail("Failed to load the first device")
        }
    }
}