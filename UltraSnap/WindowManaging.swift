import Cocoa

protocol WindowManaging {
    func checkAccessibilityPermissions() -> Bool
    func getFrontmostWindow() -> AXUIElement?
    func setWindowFrame(_ element: AXUIElement, to frame: CGRect) -> Bool
    func getWindowFrame(_ element: AXUIElement) -> CGRect?
}