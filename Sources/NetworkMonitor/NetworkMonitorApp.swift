import SwiftUI

@main
struct NetworkMonitorApp: App {
    @StateObject private var networkManager = NetworkManager()
    @State private var selectedTab = 0
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                ContentView()
                    .environmentObject(networkManager)
                    .tabItem {
                        Label("Devices", systemImage: "list.bullet")
                    }
                    .tag(0)
                    .onAppear {
                        // Start scanning automatically when the app appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            networkManager.scanNetwork()
                        }
                    }
                
                NetworkMapView()
                    .environmentObject(networkManager)
                    .tabItem {
                        Label("Map", systemImage: "network")
                    }
                    .tag(1)
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Network") {
                Button("Scan Network") {
                    networkManager.scanNetwork()
                }
                .keyboardShortcut("R", modifiers: [.command])
                
                Divider()
                
                Button("Show Devices List") {
                    selectedTab = 0
                }
                .keyboardShortcut("1", modifiers: [.command])
                
                Button("Show Network Map") {
                    selectedTab = 1
                }
                .keyboardShortcut("2", modifiers: [.command])
                
                Divider()
                
                Button("Clear Device History") {
                    networkManager.clearHistory()
                }
            }
        }
    }
}