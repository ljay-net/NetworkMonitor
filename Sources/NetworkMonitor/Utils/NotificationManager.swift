import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        requestPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func sendNewDeviceNotification(device: NetworkDevice) {
        let content = UNMutableNotificationContent()
        content.title = "New Device Detected"
        content.body = "A new device '\(device.name)' with IP \(device.ipAddress) was detected on your network."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "new-device-\(device.id)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendImportantDeviceOfflineNotification(device: NetworkDevice) {
        let content = UNMutableNotificationContent()
        content.title = "Important Device Offline"
        content.body = "The important device '\(device.name)' with IP \(device.ipAddress) is no longer on your network."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "offline-device-\(device.id)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}