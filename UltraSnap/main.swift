import Cocoa

// Manual app bootstrap - required for menu bar apps without storyboard/XIB
// The @main attribute alone doesn't instantiate the delegate without a storyboard
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
