import Cocoa
import Combine
import EventKit
import UserNotifications

enum Permissions {
    private static func getNotificationStatus() -> AnyPublisher<UNAuthorizationStatus, Never> {
        Future<UNAuthorizationStatus, Never> { promise in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                promise(.success(settings.authorizationStatus))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private static func requestNotificationAccess() -> AnyPublisher<Void, Error> {
        Future<(), Error> { promise in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, error in
                if let error = error {
                    promise(.failure(error))
                } else if granted {
                    promise(.success(()))
                } else {
                    promise(.failure(CalToNoteError.unknownError))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func authorizeNotifications() -> AnyPublisher<Void, Never> {
        getNotificationStatus()
            .flatMap { status -> AnyPublisher<Void, Never> in
                guard (status == .authorized) || (status == .provisional) else {
                    return self.requestNotificationAccess()
                        .assertNoFailure()
                        .flatMap(self.authorizeNotifications)
                        .eraseToAnyPublisher()
                }
                
                return Just(()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private static func requestCalendarAccess(for store: EKEventStore) -> AnyPublisher<Void, Error> {
        Future<(), Error> { promise in
            store.requestAccess(to: .event) { granted, error in
                if let error = error {
                    promise(.failure(error))
                } else if granted {
                    promise(.success(()))
                } else {
                    promise(.failure(CalToNoteError.unknownError))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func authorizeCalendar(for store: EKEventStore) -> AnyPublisher<Void, Never> {
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else {
            return requestCalendarAccess(for: store)
                .assertNoFailure()
                .flatMap { authorizeCalendar(for: store) }
                .eraseToAnyPublisher()
        }
        
        return Just(()).eraseToAnyPublisher()
    }
}
