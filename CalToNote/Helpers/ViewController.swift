import Cocoa

class ViewController: NSViewController {
    override func viewDidAppear() {
        super.viewDidAppear()
        // TODO: Observe this notification to fetch new data when the user opens the menu bar app
        // NotificationCenter.default.post(name: Notification.Name("ViewDidAppear"), object: nil)
    }
}
