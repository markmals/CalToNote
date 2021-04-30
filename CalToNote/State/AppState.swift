import ComposableArchitecture
import EventKit

struct AppState: Equatable {
    var notifications: NotificationState
    var windows: WindowState
    
    var templateIsSet = false
    var isFirstLaunch = true
    
    var predicate: NSPredicate = .init()
    //    var predicate: NSPredicate {
//            let now = Date()
//            let tomorrow = Calendar
//                .current
//                .date(
//                    byAdding: DateComponents(day: 1),
//                    to: now
//                )
//
//            return eventStore.predicateForEvents(
//                withStart: now,
//                end: tomorrow!,
//                calendars: eventStore
//                    .calendars(for: .event)
//                    .filter { $0.title != selectedCalendar }
//            )
    //    }

    var events: [EKEvent] = []
    
    var calendars: [EKCalendar] = []
    var filterKeyword = "meeting"
    var selectedCalendar = ""
}
