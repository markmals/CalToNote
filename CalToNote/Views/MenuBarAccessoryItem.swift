import Cocoa
import SwiftUI

final class MenuBarAccessoryItem<Content: View>: NSObject, NSMenuDelegate {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var quitMenu: NSMenu
    
    private var popover: NSPopover
    
    private var eventMonitor: EventMonitor?
    
    init(width: CGFloat, height: CGFloat, statusItemWidth: CGFloat? = nil, @ViewBuilder content: (@escaping () -> Void) -> Content) {
        popover = NSPopover()
        popover.contentViewController = ViewController()
        popover.contentSize = NSSize(width: width, height: height)
        
        statusBar = NSStatusBar()
        statusItem = statusBar.statusItem(withLength: statusItemWidth ?? 20)
        
        quitMenu = NSMenu(title: "Status Bar Menu")
        
        super.init()
        
        if let button = statusItem.button {
            button.image = NSImage(named: "menu-bar-icon")
            button.image?.isTemplate = true
            
            button.action = #selector(togglePopover(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], handler: mouseEventHandler)
        
        quitMenu.delegate = self
        quitMenu.addItem(
            withTitle: "Quit",
            action: #selector(NSApplication.shared.terminate),
            keyEquivalent: "q"
        )
        
        popover.contentViewController?.view = NSHostingView(rootView: content { self.hidePopover(self) })
    }
    
    @objc func togglePopover(sender: AnyObject) {
        let event = NSApp.currentEvent!
        
        if event.type == .rightMouseUp {
            statusItem.menu = quitMenu
            statusItem.button?.performClick(nil)
        } else {
            if popover.isShown { hidePopover(sender) }
            else { showPopover(sender) }
        }
    }
    
    func showPopover(_ sender: AnyObject) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.maxY)
            eventMonitor?.start()
        }
    }
    
    func hidePopover(_ sender: AnyObject) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
    
    func mouseEventHandler(_ event: NSEvent?) {
        if popover.isShown { hidePopover(event!) }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // Remove menu so button works as before
        statusItem.menu = nil
    }
}

