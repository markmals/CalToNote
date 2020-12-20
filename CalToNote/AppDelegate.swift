import Cocoa
import EventKit
import SwiftUI
import Combine
import Defaults
import Preferences

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarItem: AnyObject?
    lazy var preferencesWindowController = PreferencesWindowController(
        panes: [
            Preferences.Pane(
                identifier: Preferences.PaneIdentifier("general"),
                title: "General",
                toolbarIcon: NSImage(named: "gear")!,
                contentView: { GeneralPreferencePane().environmentObject(CalendarObservable(store: store)) }
            )
        ]
    )
    
    private var cancellables = Set<AnyCancellable>()
    deinit { cancellables.forEach { $0.cancel() } }
    
    private let store = EKEventStore()
    var notificationManager: Notifications?
    
    let oneDay: TimeInterval = 60 * 60 * 24
    lazy var predicate: NSPredicate = {
        let now = Date()
        var tomorrow: Date {
            var oneDay = DateComponents()
            oneDay.day = 1
            return Calendar.current.date(byAdding: oneDay, to: now)!
        }
        
        let selectedCalendar = Defaults[.selectedCalendar]
        
        return store.predicateForEvents(
            withStart: now,
            end: tomorrow,
            calendars: store.calendars(for: .event).filter { $0.title != selectedCalendar }
        )
    }()
    
    lazy var eventFetcher = Events(store: store, predicate: predicate, refresh: oneDay) { events in
        events
            .filter { $0.calendar.title != Defaults[.selectedCalendar] }
            .filter { $0.notes?.lowercased().contains(Defaults[.filterKeyword]) ?? false }
            .compactMap { event -> EKEvent? in
                if event.startDate != nil {
                    return event
                }

                return nil
            }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if FileManager.default.fileExists(atPath: FilePath.template.path) {
            Defaults[.templateIsSet] = true
        }
        
        menuBarItem = MenuBarAccessoryItem(width: 360, height: 480) { hidePopover in
            ContentView(hidePopover: hidePopover)
                .frame(width: 360, height: 480)
                .environmentObject(preferencesWindowController)
                .environmentObject(eventFetcher)
        }
        
        // FIXME: Make the popover show on the first launch
        // This code does not work...
//        if Defaults[.isFirstLaunch] {
//            (menuBarItem as! PopoverControllable).showPopover(menuBarItem!)
//        }
        
        Defaults.publisher(.selectedCalendar)
            .flatMap { _ in Defaults.publisher(.filterKeyword) }
            .sink { _ in self.eventFetcher.refreshEventCache() }
            .store(in: &cancellables)
                
        Defaults.publisher(.isFirstLaunch)
            .sink { isFirstLaunch in
                if !isFirstLaunch.newValue {
                    self.notificationManager = Notifications(
                        store: self.store,
                        eventFetcher: self.eventFetcher,
                        interval: .fifteenMinutes
                    )
                }
            }
            .store(in: &cancellables)
    }
        
    func applicationWillTerminate(_ notification: Notification) {
        if Defaults[.isFirstLaunch] { Defaults[.isFirstLaunch].toggle() }
    }
}

extension NSApplicationDelegate {
    static func main() {
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}

extension PreferencesWindowController: ObservableObject {}
