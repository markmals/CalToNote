import Cocoa
import Combine
import EventKit
import UserNotifications
import Defaults

final class Notifications {
    enum Interval: TimeInterval, Codable {
        case fifteenMinutes = 900
        case thirtyMinutes = 1800
        case fourtyFiveMinutes = 2700
        case oneHour = 3600
    }
    
    private let store: EKEventStore
    private let responder = Responder()
    private let eventFetcher: Events
    
    private var notificationCancellable: AnyCancellable?
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.forEach { $0.cancel() }
        timerCancellable?.cancel()
        notificationCancellable?.cancel()
    }
                    
    private func fireNotification(forEvent event: EKEvent) {
        let content = UNMutableNotificationContent()
        content.title = "Create New Note for \(event.title ?? "[Untitled Event]")?"
        content.body = "Do you want to create a note for your event, \(event.title ?? "[Untitled Event]")?"
        content.categoryIdentifier =  "createEventNotif"
        if let title = event.title { content.userInfo = ["title": title] }
        
        UNUserNotificationCenter
            .current()
            .add(UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil)
            )
    }
    
    let timerSubject = PassthroughSubject<EKEvent, Never>()
    
    init(store: EKEventStore, eventFetcher: Events, interval: Interval) {
        self.store = store
        self.eventFetcher = eventFetcher
        
        responder.registerCategories()
        
        // IF shouldShowNotifications THEN init the notifications publisher pipeline
        // IF !shouldShowNotifications THEN cancel the notificationCancellable
        Defaults.publisher(.shouldShowNotifications)
            .sink { shouldShowNotifications in
                if shouldShowNotifications.newValue {
                    self.timerCancellable = Timer.publish(every: Defaults[.fetchInterval].rawValue, on: RunLoop.main, in: .common)
                        .autoconnect()
                        .map { date -> [EKEvent] in
                            var intervalComponents = DateComponents()
                            intervalComponents.minute = Int(interval.rawValue)
                            let nextFire = Calendar.current.date(byAdding: intervalComponents, to: date)!

                            return self.eventFetcher.cachedEvents?
                                .filter { $0.startDate > date || $0.startDate < nextFire } ?? []
                        }
                        .flatMap { Publishers.Sequence(sequence: $0) }
                        .receive(on: DispatchQueue.main)
                        .subscribe(self.timerSubject)
                    
                    self.notificationCancellable = Permissions.authorizeNotifications()
                        .flatMap { Permissions.authorizeCalendar(for: self.store) }
                        .flatMap { self.timerSubject }
                        .sink(receiveValue: self.fireNotification(forEvent:))
                } else {
                    self.timerCancellable?.cancel()
                    self.notificationCancellable?.cancel()
                }
            }
            .store(in: &cancellables)
    }
}
