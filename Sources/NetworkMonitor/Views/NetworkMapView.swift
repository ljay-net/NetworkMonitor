import SwiftUI

struct NetworkMapView: View {
    @EnvironmentObject private var networkManager: NetworkManager
    @State private var selectedDevice: NetworkDevice?
    @State private var mapScale: CGFloat = 1.0
    @State private var mapOffset = CGSize.zero
    @State private var showOfflineDevices = false
    @State private var animateConnections = true
    
    var body: some View {
        VStack {
            HStack {
                Text("Network Map")
                    .font(.largeTitle)
                
                Spacer()
                
                Button(action: { networkManager.scanNetwork() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(networkManager.isScanning)
                .padding(.trailing)
                
                Button(action: { 
                    withAnimation {
                        mapScale = 1.0
                        mapOffset = .zero
                    }
                }) {
                    Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                }
            }
            .padding(.horizontal)
            
            // Controls
            HStack {
                Toggle("Show Offline", isOn: $showOfflineDevices)
                Toggle("Animate", isOn: $animateConnections)
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            ZStack {
                // Background
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 300, height: 300)
                
                // Connection lines
                if animateConnections {
                    ForEach(devicesToShow.filter { $0.type != .router }) { device in
                        if networkManager.devices.contains(where: { $0.type == .router }) {
                            ConnectionLine(from: .zero, to: positionForDevice(device, in: devicesToShow))
                        }
                    }
                }
                
                // Router at center
                if let router = networkManager.devices.first(where: { $0.type == .router }) {
                    deviceCircle(for: router, position: .zero, isRouter: true)
                        .onTapGesture {
                            withAnimation {
                                selectedDevice = router
                            }
                        }
                }
                
                // Other devices in a circle around the router
                ForEach(Array(devicesToShow.filter { $0.type != .router }.enumerated()), id: \.element.id) { index, device in
                    let position = positionForDevice(device, in: devicesToShow.filter { $0.type != .router }, index: index)
                    
                    deviceCircle(for: device, position: position)
                        .onTapGesture {
                            withAnimation {
                                selectedDevice = device
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 350)
            .scaleEffect(mapScale)
            .offset(x: mapOffset.width, y: mapOffset.height)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / mapScale
                        mapScale *= delta
                        mapScale = min(max(mapScale, 0.5), 3.0)
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        mapOffset = CGSize(
                            width: mapOffset.width + gesture.translation.width / mapScale,
                            height: mapOffset.height + gesture.translation.height / mapScale
                        )
                    }
            )
            
            if networkManager.isScanning {
                HStack {
                    ProgressView()
                        .padding(.trailing, 10)
                    Text("Scanning network...")
                }
                .padding()
            } else {
                Text("Tap on a device to view details • Pinch to zoom • Drag to pan")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            
            if let device = selectedDevice {
                VStack(alignment: .leading) {
                    HStack {
                        Text(device.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                selectedDevice = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(device.ipAddress)
                    Text("Type: \(device.type.rawValue.capitalized)")
                    Text("Status: \(device.isOnline ? "Online" : "Offline")")
                        .foregroundColor(device.isOnline ? .green : .red)
                    
                    if !device.tags.isEmpty {
                        Text("Tags: \(device.tags.joined(separator: ", "))")
                    }
                    
                    if !device.notes.isEmpty {
                        Text("Notes: \(device.notes)")
                            .lineLimit(2)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                .padding()
            }
            
            Spacer()
        }
    }
    
    var devicesToShow: [NetworkDevice] {
        if showOfflineDevices {
            return networkManager.devices
        } else {
            return networkManager.devices.filter { $0.isOnline }
        }
    }
    
    func positionForDevice(_ device: NetworkDevice, in devices: [NetworkDevice], index: Int? = nil) -> CGPoint {
        let idx = index ?? devices.firstIndex(where: { $0.id == device.id }) ?? 0
        let angle = 2 * Double.pi * Double(idx) / Double(max(1, devices.count))
        let x = 120 * cos(angle)
        let y = 120 * sin(angle)
        return CGPoint(x: x, y: y)
    }
    
    @ViewBuilder
    func deviceCircle(for device: NetworkDevice, position: CGPoint, isRouter: Bool = false) -> some View {
        let size: CGFloat = isRouter ? 60 : 40
        let isSelected = selectedDevice?.id == device.id
        
        ZStack {
            Circle()
                .fill(colorForDeviceType(device.type))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
                )
            
            Image(systemName: iconForDeviceType(device.type))
                .font(.system(size: isRouter ? 30 : 20))
                .foregroundColor(.white)
                
            if !device.isOnline {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                    .background(Circle().fill(Color.black).frame(width: 20, height: 20))
                    .offset(x: size/2 - 5, y: -size/2 + 5)
            }
            
            if device.isImportant {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                    .background(Circle().fill(Color.black).frame(width: 20, height: 20))
                    .offset(x: -size/2 + 5, y: -size/2 + 5)
            }
        }
        .offset(x: position.x, y: position.y)
        .overlay(
            Text(device.name)
                .font(.caption)
                .lineLimit(1)
                .offset(x: position.x, y: position.y + size/2 + 10)
        )
    }
    
    private func iconForDeviceType(_ type: DeviceType) -> String {
        switch type {
        case .computer:
            return "desktopcomputer"
        case .mobile:
            return "iphone"
        case .iot:
            return "homepod"
        case .router:
            return "network"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private func colorForDeviceType(_ type: DeviceType) -> Color {
        switch type {
        case .computer:
            return .blue
        case .mobile:
            return .green
        case .iot:
            return .orange
        case .router:
            return .purple
        case .unknown:
            return .gray
        }
    }
}