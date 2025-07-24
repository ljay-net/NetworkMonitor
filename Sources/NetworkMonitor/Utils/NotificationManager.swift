import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private var notificationsEnabled = false
    
    private init() {
        // Don't request permission immediately to avoid the error
        // We'll check if we're running in a proper app environment first
        checkNotificationAvailability()
    }
    
    private func checkNotificationAvailability() {
        // Check if we're running in a proper app bundle
        if Bundle.main.bundleURL.pathExtension == "app" {
            requestPermission()
        } else {
            DebugLogger.shared.warning("Not running in an app bundle, notifications disabled")
            notificationsEnabled = false
        }
    }
    
    func requestPermission() {
        do {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    DebugLogger.shared.info("Notification permission granted")
                    self.notificationsEnabled = true
                } else if let error = error {
                    DebugLogger.shared.error("Error requesting notification permission: \(error.localizedDescription)")
                    self.notificationsEnabled = false
                } else {
                    DebugLogger.shared.warning("Notification permission denied")
                    self.notificationsEnabled = false
                }
            }
        } catch {
            DebugLogger.shared.error("Exception when requesting notification permission: \(error.localizedDescription)")
            notificationsEnabled = false
        }
    }
    
    func sendNewDeviceNotification(device: NetworkDevice) {
        guard notificationsEnabled else {
            DebugLogger.shared.debug("Skipping notification for new device - notifications disabled")
            return
        }
        
        do {
            let content = UNMutableNotificationContent()
            content.title = "New Device Detected"
            content.body = "A new device '\(device.name)' with IP \(device.ipAddress) was detected on your network."
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "new-device-\(device.id)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    DebugLogger.shared.error("Failed to send notification: \(error.localizedDescription)")
                }
            }
        } catch {
            DebugLogger.shared.error("Exception when sending notification: \(error.localizedDescription)")
        }
    }
    
    func sendImportantDeviceOfflineNotification(device: NetworkDevice) {
        guard notificationsEnabled else {
            DebugLogger.shared.debug("Skipping notification for offline device - notifications disabled")
            return
        }
        
        do {
            let content = UNMutableNotificationContent()
            content.title = "Important Device Offline"
            content.body = "The important device '\(device.name)' with IP \(device.ipAddress) is no longer on your network."
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "offline-device-\(device.id)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    DebugLogger.shared.error("Failed to send offline notification: \(error.localizedDescription)")
                }
            }
        } catch {
            DebugLogger.shared.error("Exception when sending offline notification: \(error.localizedDescription)")
        }
    }
}