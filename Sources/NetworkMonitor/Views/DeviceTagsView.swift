import SwiftUI

struct DeviceTagsView: View {
    @EnvironmentObject private var networkManager: NetworkManager
    let device: NetworkDevice
    
    @State private var newTag = ""
    @State private var deviceTags: [String]
    @State private var notes: String
    
    init(device: NetworkDevice) {
        self.device = device
        _deviceTags = State(initialValue: device.tags)
        _notes = State(initialValue: device.notes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Device Tags")
                .font(.headline)
            
            // Tag input field
            HStack {
                TextField("Add new tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newTag.isEmpty)
            }
            
            // Tags display
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(deviceTags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Button(action: {
                                removeTag(tag)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(15)
                    }
                }
            }
            .frame(height: deviceTags.isEmpty ? 0 : 40)
            
            Divider()
            
            // Notes section
            Text("Notes")
                .font(.headline)
            
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                )
            
            // Common tags suggestions
            if !networkManager.getAllTags().isEmpty {
                Text("Common Tags")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(networkManager.getAllTags().filter { !deviceTags.contains($0) }, id: \.self) { tag in
                            Button(action: {
                                deviceTags.append(tag)
                                saveTags()
                            }) {
                                Text(tag)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(15)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            Button("Save Changes") {
                saveTags()
                saveNotes()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !deviceTags.contains(trimmedTag) {
            deviceTags.append(trimmedTag)
            newTag = ""
            saveTags()
        }
    }
    
    private func removeTag(_ tag: String) {
        deviceTags.removeAll { $0 == tag }
        saveTags()
    }
    
    private func saveTags() {
        networkManager.updateDeviceTags(device, tags: deviceTags)
    }
    
    private func saveNotes() {
        networkManager.updateDeviceNotes(device, notes: notes)
    }
}