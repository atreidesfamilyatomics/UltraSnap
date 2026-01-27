import Cocoa

// MARK: - Drag Monitor
// Monitors global mouse events to detect window dragging

class DragMonitor {

    private let snapEngine: SnapEngine
    private let previewOverlay: PreviewOverlay

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

        print("Drag monitoring started")
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

        print("Drag monitoring stopped")
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
        // We consider it a drag if mouse has moved more than 10 pixels
        if let startLocation = dragStartLocation {
            let distance = hypot(mouseLocation.x - startLocation.x, mouseLocation.y - startLocation.y)
            if distance > 10 && !isDragging {
                isDragging = true
                print("[DragMonitor] Drag started at \(mouseLocation)")
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
                print("[DragMonitor] Entered zone \(zoneIndex) at \(mouseLocation)")
                print("[DragMonitor] Zone frame: \(frame)")
                previewOverlay.show(zoneIndex: zoneIndex, frame: frame)
            } else {
                // Not in any zone, hide preview
                previewOverlay.hide()
            }
        }
    }

    // MARK: - Perform Snap

    private func performSnap(to zoneIndex: Int) {
        print("[DragMonitor] performSnap called for zone: \(zoneIndex)")
        // Small delay to ensure the window has finished its drag
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            print("[DragMonitor] Executing snap to zone \(zoneIndex)")
            let result = self?.snapEngine.snapFrontmostWindowToZone(at: zoneIndex) ?? false
            print("[DragMonitor] Snap result: \(result ? "SUCCESS" : "FAILED")")
        }
    }
}
