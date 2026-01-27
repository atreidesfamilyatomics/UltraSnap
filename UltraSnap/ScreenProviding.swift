import Cocoa

protocol ScreenProviding {
    var screens: [NSScreen] { get }
    func screenContaining(point: CGPoint) -> NSScreen?
    func refreshScreenCache()
    func getDisplayID(for screen: NSScreen) -> CGDirectDisplayID?
}