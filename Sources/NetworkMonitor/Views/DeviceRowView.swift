import SwiftUI

struct DeviceRowView: View {
    let device: NetworkDevice
    
    var body: some View {
        HStack {
            Image(systemName: iconForDeviceType(device.type))
                .foregroundColor(device.isOnline ? .green : .gray)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                Text(device.ipAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if device.isImportant {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 4)
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
}