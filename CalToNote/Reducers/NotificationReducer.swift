import ComposableArchitecture

let notificationReducer = Reducer<NotificationState, NotificationAction, UserNotificationsEnvironment> { state, action, environment in
    switch action {
    case let .requestNotificationPermission(options):
        return environment
            .getNotificationSettings()
            .receive(on: DispatchQueue.main)
            .map { NotificationAction.notificationSettingsResponse(options, $0.authorizationStatus) }
            .eraseToEffect()
    
    case let .notificationSettingsResponse(options, status):
        switch status {
        case .notDetermined, .authorized, .provisional, .ephemeral:
            state.userAllowedNotifications = true
            return environment
                .request(authorization: options)
                .receive(on: DispatchQueue.main)
                .catchToEffect()
                .map(NotificationAction.authorizationResponse)
            
        case .denied:
            state.userAllowedNotifications = false
            return .none
            
        @unknown default:
            return .none
        }
    
    case .authorizationResponse(.failure):
        state.userAllowedNotifications = false
        return .none

    case let .authorizationResponse(.success(granted)):
        state.userAllowedNotifications = granted
        return .none
    }
}
