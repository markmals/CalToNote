import ComposableArchitecture

struct NotificationState: Equatable {
    var userAllowedNotifications = false
    var userWantsToReceiveNotifications = false {
        didSet {
            guard userAllowedNotifications else {
                userWantsToReceiveNotifications = false
                return
            }
        }
    }
}
