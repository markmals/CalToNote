import EventKit
import UserNotifications
import ComposableArchitecture
import Combine

protocol EventsEnvironment {
    var eventStore: EKEventStore { get }
    func fetchEvents(matching predicate: NSPredicate) -> [EKEvent]
    func fetchCalendars() -> [EKCalendar]
    func generateNotificationRequests(for events: [EKEvent]) -> [UNNotificationRequest]
    func eventStoreChanged() -> AnyPublisher<Void, Never>
}

struct EventsClient: EventsEnvironment {
    let eventStore = EKEventStore()
    
    func fetchEvents(matching predicate: NSPredicate) -> [EKEvent] {
        eventStore.events(matching: predicate)
    }
    
    func fetchCalendars() -> [EKCalendar] {
        eventStore.calendars(for: .event)
    }
    
    func generateNotificationRequests(for events: [EKEvent]) -> [UNNotificationRequest] {
        events.map { event -> UNNotificationRequest in
            let content = UNMutableNotificationContent()
            content.title = "Create New Note for \(event.title ?? "[Untitled Event]")?"
            content.body = "Do you want to create a note for your event, \(event.title ?? "[Untitled Event]")?"
            // For the notification action button
            // See: UserNotificationsClient.Responder
            content.categoryIdentifier =  "createEventNotif"
            if let title = event.title { content.userInfo = ["title": title] }
            
            let dateInfo = Calendar.current.dateComponents(
                [.minute, .hour, .day, .month, .year],
                from: event.startDate
            )
            
            let thirtyMinutes = DateComponents(minute: 30)
            // Alert the user 30 min before the event
            // TODO: Make this user configurable
            let alertDate = dateInfo - thirtyMinutes
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: alertDate, repeats: false)
            
            return UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        }
    }
    
    func eventStoreChanged() -> AnyPublisher<Void, Never> {
        NotificationCenter
            .default
            .publisher(for: .EKEventStoreChanged, object: eventStore)
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

extension EKEvent: Comparable, Identifiable {
    public static func < (lhs: EKEvent, rhs: EKEvent) -> Bool {
        lhs.startDate < rhs.startDate
    }
    
    public var id: String { calendarItemIdentifier }
}

extension EKCalendar: Identifiable {
    public var id: String { calendarIdentifier }
}
