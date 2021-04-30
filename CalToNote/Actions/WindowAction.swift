import Cocoa
import Preferences

enum WindowAction {
    case registerPreferencesController(PreferencesWindowController)
    case closeAndShowPreferencesWindow
    case showPreferencesWindow
    
    case registerPopover(NSPopover, EventMonitor?, NSStatusBarButton?)
    case hidePopover
    case showPopover
}
