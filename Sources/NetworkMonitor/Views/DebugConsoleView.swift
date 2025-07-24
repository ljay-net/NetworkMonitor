import SwiftUI

struct DebugConsoleView: View {
    @ObservedObject private var logger = DebugLogger.shared
    @State private var filterText = ""
    @State private var selectedLevel: DebugLogger.LogLevel? = nil
    @State private var autoScroll = true
    @Binding var isVisible: Bool
    
    init(isVisible: Binding<Bool>) {
        self._isVisible = isVisible
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Debug Console")
                    .font(.headline)
                
                Spacer()
                
                HStack {
                    Button(action: { logger.clear() }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: { isVisible = false }) {
                        Label("Close", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal)
            
            HStack {
                TextField("Filter logs...", text: $filterText)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Level", selection: $selectedLevel) {
                    Text("All").tag(nil as DebugLogger.LogLevel?)
                    Text("Info").tag(DebugLogger.LogLevel.info as DebugLogger.LogLevel?)
                    Text("Debug").tag(DebugLogger.LogLevel.debug as DebugLogger.LogLevel?)
                    Text("Warning").tag(DebugLogger.LogLevel.warning as DebugLogger.LogLevel?)
                    Text("Error").tag(DebugLogger.LogLevel.error as DebugLogger.LogLevel?)
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.switch)
            }
            .padding(.horizontal)
            
            ScrollViewReader { scrollView in
                List {
                    ForEach(filteredLogs) { entry in
                        HStack(alignment: .top) {
                            Text(entry.formattedTimestamp)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            
                            Text(entry.level.rawValue)
                                .font(.caption)
                                .foregroundColor(entry.level.color)
                                .frame(width: 70, alignment: .leading)
                            
                            Text(entry.message)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                        .id(entry.id)
                    }
                    
                    // Bottom anchor for auto-scrolling
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .onChange(of: logger.logs) { _ in
                    if autoScroll && !logger.logs.isEmpty {
                        withAnimation {
                            scrollView.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    private var filteredLogs: [DebugLogger.LogEntry] {
        logger.logs.filter { entry in
            let matchesFilter = filterText.isEmpty || entry.message.localizedCaseInsensitiveContains(filterText)
            let matchesLevel = selectedLevel == nil || entry.level == selectedLevel
            return matchesFilter && matchesLevel
        }
    }
}