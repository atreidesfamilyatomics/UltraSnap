import Cocoa
import ApplicationServices
import os.log

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
        // Try primaryScreen first, then mainScreen, then first screen
        let screen = ScreenManager.shared.primaryScreen
            ?? ScreenManager.shared.mainScreen
            ?? ScreenManager.shared.screens.first

        guard let targetScreen = screen else {
            AppLogger.accessibility.warning("No screen available for coordinate conversion, using 1080p fallback")
            // Fallback: assume standard 1080p height if no screens
            return 1080 - cocoaY - height
        }

        // In Quartz: y = primaryScreenHeight - cocoaY - windowHeight
        return targetScreen.frame.height - cocoaY - height
    }

    /// Convert Quartz Y coordinate to Cocoa Y coordinate
    func quartzToCocoaY(_ quartzY: CGFloat, height: CGFloat) -> CGFloat {
        let screen = ScreenManager.shared.primaryScreen
            ?? ScreenManager.shared.mainScreen
            ?? ScreenManager.shared.screens.first

        guard let targetScreen = screen else {
            AppLogger.accessibility.warning("No screen available for coordinate conversion, using 1080p fallback")
            return 1080 - quartzY - height
        }

        return targetScreen.frame.height - quartzY - height
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

        guard result == .success else {
            let errorCode = result.rawValue
            AppLogger.accessibility.debug("Failed to get focused window: AXError \(errorCode)")
            return nil
        }

        // focusedWindow is guaranteed to be AXUIElement when result == .success
        // swiftlint:disable:next force_cast
        return (focusedWindow as! AXUIElement)
    }

    // MARK: - Get Window Position

    func getWindowPosition(_ window: AXUIElement) -> CGPoint? {
        var positionValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)

        guard result == .success else {
            let errorCode = result.rawValue
            AppLogger.accessibility.debug("Failed to get window position: AXError \(errorCode)")
            return nil
        }

        guard let value = positionValue,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            AppLogger.accessibility.error("Window position value is not AXValue type")
            return nil
        }

        var position = CGPoint.zero
        // Type is verified by CFGetTypeID check above
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(value as! AXValue, .cgPoint, &position) else {
            AppLogger.accessibility.error("Failed to extract CGPoint from AXValue")
            return nil
        }

        return position
    }

    // MARK: - Get Window Size

    func getWindowSize(_ window: AXUIElement) -> CGSize? {
        var sizeValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)

        guard result == .success else {
            let errorCode = result.rawValue
            AppLogger.accessibility.debug("Failed to get window size: AXError \(errorCode)")
            return nil
        }

        guard let value = sizeValue,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            AppLogger.accessibility.error("Window size value is not AXValue type")
            return nil
        }

        var size = CGSize.zero
        // Type is verified by CFGetTypeID check above
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(value as! AXValue, .cgSize, &size) else {
            AppLogger.accessibility.error("Failed to extract CGSize from AXValue")
            return nil
        }

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
        guard let value = AXValueCreate(.cgPoint, &pos) else {
            AppLogger.accessibility.error("Failed to create AXValue for position")
            return false
        }

        let result = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
        if result != .success {
            let errorCode = result.rawValue
            AppLogger.accessibility.debug("Failed to set window position: AXError \(errorCode)")
        }
        return result == .success
    }

    // MARK: - Set Window Size

    func setWindowSize(_ window: AXUIElement, size: CGSize) -> Bool {
        var sz = size
        guard let value = AXValueCreate(.cgSize, &sz) else {
            AppLogger.accessibility.error("Failed to create AXValue for size")
            return false
        }

        let result = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
        if result != .success {
            let errorCode = result.rawValue
            AppLogger.accessibility.debug("Failed to set window size: AXError \(errorCode)")
        }
        return result == .success
    }

    // MARK: - Set Window Frame (Position + Size)
    // Following Rectangle's pattern: size, then position, then size again for multi-display handling
    // IMPORTANT: Input frame should be in Cocoa coordinates (from NSScreen)
    // We convert to Quartz coordinates for the Accessibility API

    func setWindowFrame(_ window: AXUIElement, frame: CGRect) -> Bool {
        // Convert Cocoa coordinates (NSScreen) to Quartz coordinates (Accessibility API)
        let quartzFrame = cocoaFrameToQuartz(frame)

        AppLogger.accessibility.debug("Setting window frame:")
        AppLogger.accessibility.debug("  Cocoa frame: \(frame.debugDescription)")
        AppLogger.accessibility.debug("  Quartz frame: \(quartzFrame.debugDescription)")

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

        guard result == .success else {
            let errorCode = result.rawValue
            AppLogger.accessibility.debug("Failed to get window title: AXError \(errorCode)")
            return nil
        }
        return titleValue as? String
    }

    // MARK: - Get Window's Application

    func getWindowApp(_ window: AXUIElement) -> NSRunningApplication? {
        var pid: pid_t = 0
        let result = AXUIElementGetPid(window, &pid)
        if result != .success {
            let errorCode = result.rawValue
            AppLogger.accessibility.debug("Failed to get window PID: AXError \(errorCode)")
            return nil
        }
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            AppLogger.accessibility.debug("No running application found for PID \(pid)")
            return nil
        }
        return app
    }
}

// MARK: - WindowManaging Protocol Conformance
extension AccessibilityManager: WindowManaging {
    func setWindowFrame(_ element: AXUIElement, to frame: CGRect) -> Bool {
        return setWindowFrame(element, frame: frame)
    }
}