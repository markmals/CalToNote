import UserNotifications

enum NotificationAction {
    case requestNotificationPermission(UNAuthorizationOptions)
    case notificationSettingsResponse(UNAuthorizationOptions, UNAuthorizationStatus)
    case authorizationResponse(Result<Bool, Error>)
}
