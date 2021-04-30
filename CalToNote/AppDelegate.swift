import Cocoa
import SwiftUI
import Combine
import Preferences
import ComposableArchitecture

typealias AppStore = Store<AppState, AppAction>

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let store = AppStore(
        initialState: AppState(),
        reducer: appReducer,
        environment: AppEnvironment(
            notificationsClient: UserNotificationsClient(),
            fileClient: .live,
            eventsClient: .live
        )
    )
    lazy private(set) var viewStore = ViewStore(store)
    var menuBarItem: AnyObject?
    var calendarUpdatedCancellable: AnyCancellable? = nil
        
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check if a template exists and set its state flag
        viewStore.send(.checkIfTemplateExists)
        
        // Set the menu bar popover and root view
        menuBarItem = MenuBarAccessoryItem(
            width: 360,
            height: 480,
            store: store,
            content: ContentView(store: store)
        )
        
        // Show the popover automatically on first launch
        if viewStore.state.isFirstLaunch { viewStore.send(.showPopover) }
        // Populate the calendar cache on launch
        viewStore.send(.updateCalendar)
        // Every time the calendar is updated, update the calendar cache
        viewStore.send(.listenForCalendarChanges)
        // If notification permission hasn't been requested yet, ask for it
        viewStore.send(.requestNotificationPermission(.alert))
    }
}

extension NSApplicationDelegate {
    static func main() {
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}
