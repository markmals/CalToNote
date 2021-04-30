import EventKit

enum AppAction {
    case checkIfTemplateExists
    case listenForCalendarChanges
    case updateCalendar
    case fetchCalendars
    
    case scheduleEventNotifications
    case createNote(from: EKEvent)
    case presentError(Error)
    
    case preference(PreferenceAction)
    case window(WindowAction)
    case notification(NotificationAction)
}
