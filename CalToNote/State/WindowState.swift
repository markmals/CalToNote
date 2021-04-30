import Cocoa
import Preferences
import ComposableArchitecture

struct WindowState: Equatable {
    var preferencesController: PreferencesWindowController? = nil
    var popover: NSPopover? = nil
    var eventMonitor: EventMonitor? = nil
    var statusBarButton: NSStatusBarButton? = nil
}
