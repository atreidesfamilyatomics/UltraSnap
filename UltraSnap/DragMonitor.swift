import Cocoa
import os.log

/// Monitors global mouse events to detect window dragging and trigger zone snapping
///
/// DragMonitor sets up both global and local event monitors to track mouse down, drag,
/// and mouse up events. When a drag is detected and the cursor enters a zone's trigger
/// region at the top of the screen, it shows a preview overlay and prepares to snap
/// the window when the mouse is released.
///
/// ## Event Flow
/// 1. Mouse down: Record start position
/// 2. Mouse dragged: If moved > threshold, mark as dragging; check for zone entry
/// 3. Zone entered: Show preview overlay
/// 4. Mouse up in zone: Snap window to zone
/// 5. Mouse up outside zone: Cancel snap, hide preview
///
/// ## Architecture
/// - Uses `NSEvent.addGlobalMonitorForEvents` for system-wide tracking
/// - Uses `NSEvent.addLocalMonitorForEvents` when UltraSnap is focused
/// - Coordinates with `SnapEngine` for zone detection and window snapping
/// - Coordinates with `PreviewOverlay` for visual feedback
///
/// ## Threading
/// All event handlers run on the main thread. Window snapping includes a small
/// delay (0.05s) to ensure the dragged window has finished its native drag operation.
class DragMonitor {

    // MARK: - Constants

    /// Minimum distance in points the mouse must move to be considered a drag
    private let dragThreshold: CGFloat = 10.0

    // MARK: - Dependencies

    private let snapEngine: SnapEngine
    private let previewOverlay: PreviewOverlay

    // MARK: - State

    private var globalMonitor: Any?
    private var localMonitor: Any?

    private var isDragging = false
    private var currentZone: Int?  // Zone index (0, 1, 2, ...)
    private var dragStartLocation: CGPoint?

    // Track if mouse button is down
    private var isMouseDown = false

    init(snapEngine: SnapEngine, previewOverlay: PreviewOverlay) {
        self.snapEngine = snapEngine
        self.previewOverlay = previewOverlay
    }

    // MARK: - Start Monitoring

    func startMonitoring() {
        // Monitor for global mouse events (works even when app isn't focused)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseUp, .leftMouseDragged]
        ) { [weak self] event in
            self?.handleGlobalEvent(event)
        }

        // Monitor for local mouse events (when app is focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseUp, .leftMouseDragged]
        ) { [weak self] event in
            self?.handleLocalEvent(event)
            return event
        }

        AppLogger.dragMonitor.info("Drag monitoring started")
    }

    // MARK: - Stop Monitoring

    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }

        AppLogger.dragMonitor.info("Drag monitoring stopped")
    }

    // MARK: - Handle Global Events

    private func handleGlobalEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            handleMouseDown(event)
        case .leftMouseUp:
            handleMouseUp(event)
        case .leftMouseDragged:
            handleMouseDragged(event)
        default:
            break
        }
    }

    // MARK: - Handle Local Events

    private func handleLocalEvent(_ event: NSEvent) {
        // Same handling as global
        handleGlobalEvent(event)
    }

    // MARK: - Mouse Down

    private func handleMouseDown(_ event: NSEvent) {
        isMouseDown = true
        dragStartLocation = NSEvent.mouseLocation
    }

    // MARK: - Mouse Up

    private func handleMouseUp(_ event: NSEvent) {
        isMouseDown = false

        if isDragging, let zoneIndex = currentZone {
            // User released in a zone - snap the window
            performSnap(to: zoneIndex)
        }

        // Reset state
        isDragging = false
        currentZone = nil
        dragStartLocation = nil

        // Hide preview
        previewOverlay.hide()
    }

    // MARK: - Mouse Dragged

    private func handleMouseDragged(_ event: NSEvent) {
        guard isMouseDown else { return }

        let mouseLocation = NSEvent.mouseLocation

        // Check if we're near a drag start (indicates window being dragged)
        if let startLocation = dragStartLocation {
            let distance = hypot(mouseLocation.x - startLocation.x, mouseLocation.y - startLocation.y)
            if distance > dragThreshold && !isDragging {
                isDragging = true
                AppLogger.dragMonitor.debug("Drag started at \(mouseLocation.debugDescription)")
            }
        }

        guard isDragging else { return }

        // Check which zone the mouse is in
        let detectedZoneIndex = snapEngine.zoneIndexForMousePosition(mouseLocation)

        if detectedZoneIndex != currentZone {
            currentZone = detectedZoneIndex

            if let zoneIndex = detectedZoneIndex {
                // Show preview for this zone
                let frame = snapEngine.frameForZone(at: zoneIndex)
                AppLogger.dragMonitor.debug("Entered zone \(zoneIndex) at \(mouseLocation.debugDescription)")
                AppLogger.dragMonitor.debug("Zone frame: \(frame.debugDescription)")
                previewOverlay.show(zoneIndex: zoneIndex, frame: frame)
            } else {
                // Not in any zone, hide preview
                previewOverlay.hide()
            }
        }
    }

    // MARK: - Perform Snap

    private func performSnap(to zoneIndex: Int) {
        AppLogger.dragMonitor.debug("performSnap called for zone: \(zoneIndex)")
        // Small delay to ensure the window has finished its drag
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            AppLogger.dragMonitor.debug("Executing snap to zone \(zoneIndex)")
            let result = self?.snapEngine.snapFrontmostWindowToZone(at: zoneIndex) ?? false
            AppLogger.dragMonitor.debug("Snap result: \(result ? "SUCCESS" : "FAILED")")
        }
    }
}
