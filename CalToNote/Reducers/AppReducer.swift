import ComposableArchitecture
import Cocoa
//import CasePaths

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case .checkIfTemplateExists:
        if environment.fileClient.fileExists(at: FilePath.template.path) {
            state.templateIsSet = true
        }
    
    case .listenForCalendarChanges:
        return environment.eventsClient
            .eventStoreChanged()
            .map { _ in AppAction.updateCalendar }
            .eraseToEffect()
    
    case .updateCalendar:
        state.events = environment.eventsClient
            .fetchEvents(matching: state.predicate)
            .compactMap { $0 }
            .sorted()
        
        return Effect(value: AppAction.scheduleEventNotifications)
        
    case .scheduleEventNotifications:
        if state.notifications.userWantsToReceiveNotifications {
            let requests = environment.eventsClient.generateNotificationRequests(for: state.events)
            environment.notificationsClient.removeAllRequests()
            environment.notificationsClient.schedule(requests: requests)
        }
    
    case let .createNote(event):
        do {
            let url = try environment.fileClient.chooseDocument(
                title: "Where Would You Like to Create this Note?",
                canChooseFiles: false,
                canChooseDirectories: true,
                allowedFileTypes: []
            )
            
            let formatter = DateFormatter(dateFormat: "yyyy-MM-dd HH.mm.ss")
            let tempTitle = "CalToNote Untitled Event \(formatter.string(from: Date()))"
            let destination = url.appendingPathComponent("\(event.title ?? tempTitle).boxnote")
            try environment.fileClient.copy(from: FilePath.template, to: destination)
        } catch {
            return Effect(value: AppAction.presentError(error))
        }
    
    case let .presentError(error):
        if let error = error as? CalToNoteError, error == .userCancelled { return .none }
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
        
        
    case .fetchCalendars:
        state.calendars = environment.eventsClient.fetchCalendars()
        
    default: return .none
    }
    
    return .none
}

let totalReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    appReducer,
    notificationReducer.pullback(state: \.notifications, action: /AppAction.notification, environment: { $0.notificationsClient }),
    preferenceReducer.pullback(state: \.self, action: /AppAction.preference, environment: { $0 }),
    windowReducer.pullback(state: \.self, action: /AppAction.window, environment: { $0 })
)
