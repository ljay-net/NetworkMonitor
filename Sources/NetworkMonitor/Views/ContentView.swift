import SwiftUI
import UniformTypeIdentifiers

enum ExportFormat {
    case csv
    case json
}

enum DeviceFilter {
    case all
    case online
    case offline
    case important
    case tag(String)
    case type(DeviceType)
}

struct ContentView: View {
    @EnvironmentObject private var networkManager: NetworkManager
    @State private var selectedDevice: NetworkDevice?
    @State private var showingNewDeviceAlert = false
    @State private var showingMissingDeviceAlert = false
    @State private var alertDevice: NetworkDevice?
    @State private var showingExportPanel = false
    @State private var exportData: Data?
    @State private var exportFilename = ""
    @State private var showingDebugConsole = false
    @State private var currentFilter: DeviceFilter = .all
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        filterChip(title: "All", filter: .all)
                        filterChip(title: "Online", filter: .online)
                        filterChip(title: "Offline", filter: .offline)
                        filterChip(title: "Important", filter: .important)
                        
                        // Device type filters
                        ForEach(DeviceType.allCases, id: \.self) { type in
                            filterChip(title: type.rawValue.capitalized, filter: .type(type))
                        }
                        
                        // Tag filters - show only if we have tags
                        ForEach(networkManager.getAllTags(), id: \.self) { tag in
                            filterChip(title: "#\(tag)", filter: .tag(tag))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                List {
                    if networkManager.isScanning {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 10)
                            Text("Scanning network...")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                    
                    let filteredDevices = filterDevices(networkManager.devices)
                    
                    if filteredDevices.isEmpty && !networkManager.isScanning {
                        Text("No devices match the current filter")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(filteredDevices) { device in
                        DeviceRowView(device: device)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDevice = device
                            }
                            .contextMenu {
                                Button("Edit Name") {
                                    selectedDevice = device
                                }
                                Button(device.isImportant ? "Remove Important Flag" : "Mark as Important") {
                                    networkManager.toggleImportantFlag(for: device)
                                }
                            }
                    }
                }
            }
            .navigationTitle("Network Devices")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { networkManager.scanNetwork() }) {
                        Label("Scan", systemImage: "arrow.clockwise")
                    }
                    .disabled(networkManager.isScanning)
                }
                
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button("All Devices") {
                            currentFilter = .all
                        }
                        Button("Online Only") {
                            currentFilter = .online
                        }
                        Button("Offline Only") {
                            currentFilter = .offline
                        }
                        Button("Important Only") {
                            currentFilter = .important
                        }
                        
                        Menu("By Device Type") {
                            ForEach(DeviceType.allCases, id: \.self) { type in
                                Button(type.rawValue.capitalized) {
                                    currentFilter = .type(type)
                                }
                            }
                        }
                        
                        if !networkManager.getAllTags().isEmpty {
                            Menu("By Tag") {
                                ForEach(networkManager.getAllTags(), id: \.self) { tag in
                                    Button(tag) {
                                        currentFilter = .tag(tag)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        Button("Clear History", role: .destructive) {
                            networkManager.clearHistory()
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button("Export as CSV") {
                            exportDevices(as: .csv)
                        }
                        Button("Export as JSON") {
                            exportDevices(as: .json)
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingDebugConsole.toggle() }) {
                        Label("Debug Console", systemImage: "terminal")
                    }
                }
            }
            
            if let device = selectedDevice {
                DeviceDetailView(device: device)
            } else {
                Text("Select a device")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .onReceive(networkManager.$newDeviceDetected) { newDevice in
            if let device = newDevice {
                alertDevice = device
                showingNewDeviceAlert = true
                networkManager.newDeviceDetected = nil
            }
        }
        .onReceive(networkManager.$missingImportantDevice) { missingDevice in
            if let device = missingDevice {
                alertDevice = device
                showingMissingDeviceAlert = true
                networkManager.missingImportantDevice = nil
            }
        }
        .alert("New Device Detected", isPresented: $showingNewDeviceAlert) {
            Button("Dismiss", role: .cancel) { }
            Button("View Device") {
                selectedDevice = alertDevice
            }
        } message: {
            if let device = alertDevice {
                Text("A new device '\(device.name)' with IP \(device.ipAddress) was detected on your network.")
            }
        }
        .alert("Important Device Missing", isPresented: $showingMissingDeviceAlert) {
            Button("Dismiss", role: .cancel) { }
        } message: {
            if let device = alertDevice {
                Text("The important device '\(device.name)' with IP \(device.ipAddress) is no longer on your network.")
            }
        }
        .fileExporter(
            isPresented: $showingExportPanel,
            document: ExportedDocument(data: exportData ?? Data()),
            contentType: UTType.commaSeparatedText,
            defaultFilename: exportFilename
        ) { result in
            switch result {
            case .success(let url):
                DebugLogger.shared.info("Exported data to \(url)")
            case .failure(let error):
                DebugLogger.shared.error("Export error: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $showingDebugConsole) {
            DebugConsoleView()
        }
    }
    
    func exportDevices(as format: ExportFormat) {
        // Export only filtered devices
        let devicesToExport = filterDevices(networkManager.devices)
        
        switch format {
        case .csv:
            let csvString = DataExporter.exportDevicesToCSV(devicesToExport)
            exportData = csvString.data(using: .utf8)
            exportFilename = "network_devices.csv"
        case .json:
            exportData = DataExporter.exportDevicesToJSON(devicesToExport)
            exportFilename = "network_devices.json"
        }
        
        showingExportPanel = true
    }
    
    @ViewBuilder
    func filterChip(title: String, filter: DeviceFilter) -> some View {
        Button(action: {
            currentFilter = filter
        }) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(currentFilter.isSameFilter(as: filter) ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(currentFilter.isSameFilter(as: filter) ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    func filterDevices(_ devices: [NetworkDevice]) -> [NetworkDevice] {
        switch currentFilter {
        case .all:
            return devices
        case .online:
            return devices.filter { $0.isOnline }
        case .offline:
            return devices.filter { !$0.isOnline }
        case .important:
            return devices.filter { $0.isImportant }
        case .tag(let tag):
            return devices.filter { $0.tags.contains(tag) }
        case .type(let type):
            return devices.filter { $0.type == type }
        }
    }
}

extension DeviceFilter {
    func isSameFilter(as other: DeviceFilter) -> Bool {
        switch (self, other) {
        case (.all, .all),
             (.online, .online),
             (.offline, .offline),
             (.important, .important):
            return true
        case (.tag(let tag1), .tag(let tag2)):
            return tag1 == tag2
        case (.type(let type1), .type(let type2)):
            return type1 == type2
        default:
            return false
        }
    }
}