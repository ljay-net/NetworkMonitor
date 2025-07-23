import SwiftUI

class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    
    @Published var logs: [LogEntry] = []
    @Published var isEnabled = true
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: LogLevel
        
        var formattedTimestamp: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter.string(from: timestamp)
        }
    }
    
    enum LogLevel: String {
        case info = "INFO"
        case debug = "DEBUG"
        case warning = "WARNING"
        case error = "ERROR"
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .debug: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
    }
    
    func log(_ message: String, level: LogLevel = .info) {
        DispatchQueue.main.async {
            self.logs.append(LogEntry(timestamp: Date(), message: message, level: level))
            print("[\(level.rawValue)] \(message)")
        }
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
    
    func clear() {
        logs.removeAll()
    }
}