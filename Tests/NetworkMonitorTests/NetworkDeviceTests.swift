import XCTest
@testable import NetworkMonitor

final class NetworkDeviceTests: XCTestCase {
    func testDeviceEquality() {
        let id = UUID()
        let device1 = NetworkDevice(
            id: id,
            name: "Test Device",
            ipAddress: "192.168.1.1",
            macAddress: "aa:bb:cc:dd:ee:ff"
        )
        
        let device2 = NetworkDevice(
            id: id,
            name: "Different Name",
            ipAddress: "192.168.1.2",
            macAddress: "11:22:33:44:55:66"
        )
        
        XCTAssertEqual(device1, device2, "Devices with the same ID should be equal")
        
        let device3 = NetworkDevice(
            id: UUID(),
            name: "Test Device",
            ipAddress: "192.168.1.1",
            macAddress: "aa:bb:cc:dd:ee:ff"
        )
        
        XCTAssertNotEqual(device1, device3, "Devices with different IDs should not be equal")
    }
    
    func testDeviceTypeEnumeration() {
        XCTAssertEqual(DeviceType.allCases.count, 5, "There should be 5 device types")
        XCTAssertTrue(DeviceType.allCases.contains(.computer))
        XCTAssertTrue(DeviceType.allCases.contains(.mobile))
        XCTAssertTrue(DeviceType.allCases.contains(.iot))
        XCTAssertTrue(DeviceType.allCases.contains(.router))
        XCTAssertTrue(DeviceType.allCases.contains(.unknown))
    }
}