import SwiftUI

struct DeviceDetailView: View {
    @EnvironmentObject private var networkManager: NetworkManager
    @State private var editedName: String
    @State private var isEditingName = false
    @State private var selectedType: DeviceType
    @State private var selectedTab = 0
    
    let device: NetworkDevice
    
    init(device: NetworkDevice) {
        self.device = device
        _editedName = State(initialValue: device.name)
        _selectedType = State(initialValue: device.type)
    }
    
    var body: some View {
        VStack {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Details").tag(0)
                Text("History").tag(1)
                Text("Tags").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if selectedTab == 0 {
                detailsView
            } else if selectedTab == 1 {
                DeviceHistoryView(device: device)
            } else {
                DeviceTagsView(device: device)
            }
        }
    }
    
    var detailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with device info
                HStack {
                    VStack(alignment: .leading) {
                        if isEditingName {
                            TextField("Device Name", text: $editedName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    saveDeviceChanges()
                                }
                        } else {
                            Text(device.name)
                                .font(.largeTitle)
                                .bold()
                        }
                        
                        Text(device.ipAddress)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if isEditingName {
                            saveDeviceChanges()
                        } else {
                            isEditingName = true
                        }
                    }) {
                        Image(systemName: isEditingName ? "checkmark" : "pencil")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Divider()
                
                // Device details
                Group {
                    DetailRow(label: "Status", value: device.isOnline ? "Online" : "Offline")
                    
                    HStack {
                        Text("Device Type:")
                        
                        Picker("", selection: $selectedType) {
                            Text("Computer").tag(DeviceType.computer)
                            Text("Mobile").tag(DeviceType.mobile)
                            Text("IoT Device").tag(DeviceType.iot)
                            Text("Router").tag(DeviceType.router)
                            Text("Unknown").tag(DeviceType.unknown)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedType) { _ in
                            saveDeviceChanges()
                        }
                    }
                    
                    DetailRow(label: "MAC Address", value: device.macAddress)
                    if let vendor = device.vendor {
                        DetailRow(label: "Vendor", value: vendor)
                    }
                    DetailRow(label: "First Seen", value: device.firstSeen.formatted())
                    DetailRow(label: "Last Seen", value: device.lastSeen.formatted())
                }
                
                Divider()
                
                // Important toggle
                Toggle("Mark as Important Device", isOn: Binding(
                    get: { device.isImportant },
                    set: { newValue in
                        networkManager.toggleImportantFlag(for: device)
                    }
                ))
                .padding(.vertical)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func saveDeviceChanges() {
        networkManager.updateDevice(device, newName: editedName, newType: selectedType)
        isEditingName = false
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)
            Text(value)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}