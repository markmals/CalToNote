import Cocoa
import UserNotifications

extension Notifications {
    class Responder: NSObject, UNUserNotificationCenterDelegate {
        func registerCategories() {
            UNUserNotificationCenter.current().delegate = self
            let create = UNNotificationAction(identifier: "create", title: "Create Note", options: .foreground)
            let category = UNNotificationCategory(identifier: "createEventNotif", actions: [create], intentIdentifiers: [])
            UNUserNotificationCenter.current().setNotificationCategories([category])
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            let userInfo = response.notification.request.content.userInfo
            completionHandler()
            
            switch response.actionIdentifier {
            case "create":
                do {
                    let url = try Modal
                        .chooseDocument(
                            title: "Where Would You Like to Create this Note?",
                            canChooseFiles: false,
                            canChooseDirectories: true
                        )
                        .get()
                    
                    let formatter = DateFormatter(dateFormat: "yyyy-MM-dd HH.mm.ss")
                    let tempTitle = "CalToNote Untitled Event \(formatter.string(from: Date()))"
                    let destination = url.appendingPathComponent("\(userInfo["title"] as? String ?? tempTitle).boxnote")
                    try FileManager.default.copyItem(at: FilePath.template, to: destination)
                } catch {
                    Modal.alert(forError: error)
                }
            default: break
            }
        }
    }

}
