import Combine
import ComposableArchitecture
import UserNotifications

protocol UserNotificationsEnvironment {
    func getNotificationSettings() -> Effect<UNNotificationSettings, Never>
    func request(authorization: UNAuthorizationOptions) -> Effect<Bool, Error>
    func removeAllRequests()
    func schedule(requests: [UNNotificationRequest])
    func registerCategories()
}

struct UserNotificationsClient: UserNotificationsEnvironment {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let liveResponder = Responder(FileSystemClient())
    
    func getNotificationSettings() -> Effect<UNNotificationSettings, Never> {
        .future { promise in
            notificationCenter.getNotificationSettings { settings in
                promise(.success(settings))
            }
        }
    }
    
    func request(authorization: UNAuthorizationOptions) -> Effect<Bool, Error> {
        .future { promise in
            notificationCenter.requestAuthorization(options: authorization) { granted, error in
                if let error = error { promise(.failure(error)) }
                else { promise(.success(granted)) }
            }
        }
    }
    
    func removeAllRequests() { notificationCenter.removeAllPendingNotificationRequests() }
    
    func schedule(requests: [UNNotificationRequest]) {
        requests.forEach { request in
            UNUserNotificationCenter
                .current()
                .add(request)
        }
    }
    
    func registerCategories() {
        liveResponder.registerCategories()
    }
}

extension UserNotificationsClient {
    class Responder: NSObject, UNUserNotificationCenterDelegate {
        let fsEnvironment: FileSystemEnvironment
        init(_ fsEnvironment: FileSystemEnvironment) { self.fsEnvironment = fsEnvironment }
        
        func registerCategories() {
            UNUserNotificationCenter.current().delegate = self
            let create = UNNotificationAction(identifier: "create", title: "Create Note", options: .foreground)
            let category = UNNotificationCategory(identifier: "createEventNotif", actions: [create], intentIdentifiers: [])
            UNUserNotificationCenter.current().setNotificationCategories([category])
        }
        
        // FIXME: Make this work within the TCA system
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            let userInfo = response.notification.request.content.userInfo
            completionHandler()
            
            switch response.actionIdentifier {
            case "create":
                do {
                    let url = try fsEnvironment.chooseDocument(
                        title: "Where Would You Like to Create this Note?",
                        canChooseFiles: false,
                        canChooseDirectories: true,
                        allowedFileTypes: []
                    )
                    
                    let formatter = DateFormatter(dateFormat: "yyyy-MM-dd HH.mm.ss")
                    let tempTitle = "CalToNote Untitled Event \(formatter.string(from: Date()))"
                    let destination = url.appendingPathComponent("\(userInfo["title"] as? String ?? tempTitle).boxnote")
                    try FileManager.default.copyItem(at: FilePath.template, to: destination)
                // TODO: Handle Errors
                } catch {}
            default: break
            }
        }
    }
}
