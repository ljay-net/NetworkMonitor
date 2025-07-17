import SwiftUI

struct DeviceHistoryView: View {
    let device: NetworkDevice
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Device Timeline")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack {
                VStack(alignment: .trailing) {
                    Text("First Seen:")
                        .foregroundColor(.secondary)
                    Text("Last Seen:")
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text(device.firstSeen.formatted(date: .abbreviated, time: .shortened))
                    Text(device.lastSeen.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(device.isOnline ? .green : .red)
                }
            }
            .padding(.bottom)
            
            Text("Status History")
                .font(.headline)
                .padding(.bottom, 5)
            
            // This is a placeholder for future implementation
            // In a real app, we would store and display a history of status changes
            Text("Status history will be displayed here in a future update.")
                .foregroundColor(.secondary)
                .italic()
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}