import Cocoa
import ApplicationServices

// MARK: - Accessibility Manager
// Handles window manipulation via macOS Accessibility API
// Pattern referenced from Rectangle's AccessibilityElement.swift

class AccessibilityManager {

    static let shared = AccessibilityManager()

    private init() {}

    // MARK: - Permissions Check

    func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    // MARK: - Coordinate Conversion
    // NSScreen uses Cocoa coordinates: origin at BOTTOM-left of primary screen, Y increases UP
    // Accessibility API uses Quartz coordinates: origin at TOP-left of primary screen, Y increases DOWN

    /// Convert Cocoa Y coordinate to Quartz Y coordinate
    func cocoaToQuartzY(_ cocoaY: CGFloat, height: CGFloat) -> CGFloat {
        guard let primaryScreen = ScreenManager.shared.primaryScreen else { return cocoaY }
        // In Quartz: y = primaryScreenHeight - cocoaY - windowHeight
        return primaryScreen.frame.height - cocoaY - height
    }

    /// Convert Quartz Y coordinate to Cocoa Y coordinate
    func quartzToCocoaY(_ quartzY: CGFloat, height: CGFloat) -> CGFloat {
        guard let primaryScreen = ScreenManager.shared.primaryScreen else { return quartzY }
        return primaryScreen.frame.height - quartzY - height
    }

    /// Convert a Cocoa frame (from NSScreen) to Quartz frame (for Accessibility API)
    func cocoaFrameToQuartz(_ cocoaFrame: CGRect) -> CGRect {
        return CGRect(
            x: cocoaFrame.origin.x,
            y: cocoaToQuartzY(cocoaFrame.origin.y, height: cocoaFrame.height),
            width: cocoaFrame.width,
            height: cocoaFrame.height
        )
    }

    // MARK: - Get Frontmost Window

    func getFrontmostWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

        guard result == .success else { return nil }
        return (focusedWindow as! AXUIElement)
    }

    // MARK: - Get Window Position

    func getWindowPosition(_ window: AXUIElement) -> CGPoint? {
        var positionValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)

        guard result == .success,
              let value = positionValue,
              CFGetTypeID(value) == AXValueGetTypeID() else { return nil }

        var position = CGPoint.zero
        AXValueGetValue(value as! AXValue, .cgPoint, &position)
        return position
    }

    // MARK: - Get Window Size

    func getWindowSize(_ window: AXUIElement) -> CGSize? {
        var sizeValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)

        guard result == .success,
              let value = sizeValue,
              CFGetTypeID(value) == AXValueGetTypeID() else { return nil }

        var size = CGSize.zero
        AXValueGetValue(value as! AXValue, .cgSize, &size)
        return size
    }

    // MARK: - Get Window Frame

    func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        guard let position = getWindowPosition(window),
              let size = getWindowSize(window) else { return nil }
        return CGRect(origin: position, size: size)
    }

    // MARK: - Set Window Position

    func setWindowPosition(_ window: AXUIElement, position: CGPoint) -> Bool {
        var pos = position
        guard let value = AXValueCreate(.cgPoint, &pos) else { return false }

        let result = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
        return result == .success
    }

    // MARK: - Set Window Size

    func setWindowSize(_ window: AXUIElement, size: CGSize) -> Bool {
        var sz = size
        guard let value = AXValueCreate(.cgSize, &sz) else { return false }

        let result = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
        return result == .success
    }

    // MARK: - Set Window Frame (Position + Size)
    // Following Rectangle's pattern: size, then position, then size again for multi-display handling
    // IMPORTANT: Input frame should be in Cocoa coordinates (from NSScreen)
    // We convert to Quartz coordinates for the Accessibility API

    func setWindowFrame(_ window: AXUIElement, frame: CGRect) -> Bool {
        // Convert Cocoa coordinates (NSScreen) to Quartz coordinates (Accessibility API)
        let quartzFrame = cocoaFrameToQuartz(frame)

        print("[AccessibilityManager] Setting window frame:")
        print("  Cocoa frame: \(frame)")
        print("  Quartz frame: \(quartzFrame)")

        // First pass: set size
        _ = setWindowSize(window, size: quartzFrame.size)

        // Set position (in Quartz coordinates)
        _ = setWindowPosition(window, position: quartzFrame.origin)

        // Second pass: set size again (handles display boundary issues)
        _ = setWindowSize(window, size: quartzFrame.size)

        return true
    }

    // MARK: - Get All Windows

    func getAllWindows() -> [AXUIElement] {
        var windows: [AXUIElement] = []

        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            guard app.activationPolicy == .regular else { continue }

            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var windowList: AnyObject?
            let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)

            if result == .success, let appWindows = windowList as? [AXUIElement] {
                windows.append(contentsOf: appWindows)
            }
        }

        return windows
    }

    // MARK: - Get Window Title

    func getWindowTitle(_ window: AXUIElement) -> String? {
        var titleValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)

        guard result == .success else { return nil }
        return titleValue as? String
    }

    // MARK: - Get Window's Application

    func getWindowApp(_ window: AXUIElement) -> NSRunningApplication? {
        var pid: pid_t = 0
        AXUIElementGetPid(window, &pid)
        return NSRunningApplication(processIdentifier: pid)
    }
}

// MARK: - WindowManaging Protocol Conformance
extension AccessibilityManager: WindowManaging {
    func setWindowFrame(_ element: AXUIElement, to frame: CGRect) -> Bool {
        return setWindowFrame(element, frame: frame)
    }
}