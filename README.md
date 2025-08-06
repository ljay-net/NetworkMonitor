# Network Monitor

A privacy-focused macOS application that maps your local network, displays all connected devices, and alerts you to basic network anomalies.

## Features

- **Network Device Discovery**: Scans your local network using App Store-compliant methods
- **Anomaly Detection**: Alerts when new devices appear or important devices go missing
- **Privacy-Focused**: All data stays on your device, no cloud sync or third-party data collection
- **SwiftUI Interface**: Modern, native macOS interface with multiplatform support in mind
- **Device Tagging**: Organize devices with custom tags and notes
- **Visual Network Map**: Interactive visualization of your network topology
- **Data Export**: Export device data in CSV or JSON format
- **Device Filtering**: Filter devices by status, type, or custom tags

## Requirements

- macOS 12.0 or later
- Xcode 13.0 or later

## Building the Project

1. Open Terminal and navigate to the project directory:
   ```
   cd ~/NetworkMonitor
   ```

2. Build the project using Swift Package Manager:
   ```
   swift build
   ```

3. Run the application:
   ```
   swift run
   ```

## App Store Compliance

This application follows all Apple sandboxing and privacy rules:
- Uses only approved APIs for network discovery (Bonjour/mDNS, NWConnection)
- Includes proper usage descriptions for network access and notifications
- No raw packet sniffing or privileged port usage
- All data stays local on the device
- Respects user privacy with transparent data handling

## Architecture

The app is built with a clean architecture that separates concerns:
- **Models**: Data structures for network devices
- **Views**: SwiftUI interface components
- **Services**: Network discovery and device management logic

## Features Implemented

- Timeline/history of device appearance
- Device tagging/grouping
- Visual network map with zoom and pan
- Local export of device data (CSV/JSON)
- Device filtering by status, type, and tags
- System notifications for network changes

## Future Enhancements

- Network traffic monitoring
- Device fingerprinting for better identification
- Customizable alerts and thresholds
- Network speed testing
- Integration with HomeKit for smart home device monitoring
