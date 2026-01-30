# UltraSnap Architecture

This document describes the current architecture of UltraSnap and provides guidance for future development.

## Overview

UltraSnap is a macOS menu bar application that enables window snapping to predefined zones on ultrawide displays. Users can drag windows to the top of the screen or use keyboard shortcuts to snap windows to zones.

## Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AppDelegate                              │
│  - Application lifecycle                                         │
│  - Component initialization                                      │
│  - Accessibility permission prompts                              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ MenuBarController│    │   DragMonitor    │    │ ShortcutManager │
│ - Status item    │    │ - Mouse events   │    │ - Global hotkeys│
│ - Dropdown menu  │    │ - Drag detection │    │ - Zone triggers │
│ - Quick actions  │    │ - Zone detection │    │                 │
└───────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │     SnapEngine       │
                    │ - Zone calculation   │
                    │ - Frame computation  │
                    │ - Window snapping    │
                    └──────────────────────┘
                        │           │
            ┌───────────┘           └───────────┐
            ▼                                   ▼
┌──────────────────────┐            ┌──────────────────────┐
│  ScreenManager       │            │ AccessibilityManager │
│ - Screen caching     │            │ - AX API wrapper     │
│ - Display detection  │            │ - Window manipulation│
│ - Multi-monitor      │            │ - Coordinate convert │
└──────────────────────┘            └──────────────────────┘
```

## Core Components

### AppDelegate
Entry point for the application. Initializes all components, checks accessibility permissions, and manages application lifecycle.

### SnapEngine
The brain of the snapping system. Responsible for:
- Calculating zone frames based on current preset and screen
- Determining which zone contains the mouse cursor
- Coordinating window snapping via AccessibilityManager

### DragMonitor
Tracks global mouse events to detect window dragging. When a drag enters a trigger zone (top 100pt of screen), it coordinates with PreviewOverlay to show visual feedback.

### ShortcutManager
Manages global keyboard shortcuts using the KeyboardShortcuts library. Allows users to snap windows without dragging.

### MenuBarController
Creates and manages the menu bar status item with dropdown menu for quick access to snapping actions and settings.

### AccessibilityManager
Wrapper around macOS Accessibility API (AXUIElement). Handles:
- Getting/setting window position and size
- Coordinate conversion between Cocoa (NSScreen) and Quartz (AX API)
- Permission checking

### ScreenManager
Singleton that caches NSScreen information to reduce XPC calls to the system. Refreshes automatically when display configuration changes.

### PreviewOverlay
Transparent overlay window that shows where a window will snap when released. Uses click-through so it doesn't interfere with dragging.

## Configuration Components

### ConfigurationManager
Persists per-display zone presets to UserDefaults. Keyed by DisplayIdentifier for consistent mapping even if displays are reconnected.

### DisplayIdentifier
Stable identifier for displays based on CGDirectDisplayID and screen origin. Handles the case of identical monitors by using position.

### DefaultLayouts
Defines preset zone layouts (thirds, halves, quarters, etc.) and calculates frame positions based on screen dimensions.

## Data Flow

### Drag-to-Snap Flow
1. User starts dragging a window
2. DragMonitor detects mouse down + drag distance > threshold
3. DragMonitor queries SnapEngine for zone at cursor position
4. If in trigger region, SnapEngine returns zone index
5. DragMonitor tells PreviewOverlay to show preview
6. User releases mouse in zone
7. DragMonitor calls SnapEngine.snapFrontmostWindowToZone()
8. SnapEngine uses AccessibilityManager to resize/move window

### Keyboard Shortcut Flow
1. User presses Ctrl+Option+1/2/3
2. KeyboardShortcuts triggers ShortcutManager handler
3. ShortcutManager calls SnapEngine.snapFrontmostWindowToZone()
4. SnapEngine uses current screen (based on mouse location)
5. AccessibilityManager moves the window

## Logging

All logging uses the centralized `AppLogger` utility which wraps Apple's unified logging system (`os.Logger`). Categories:
- `snapEngine`: Zone calculation and snapping operations
- `dragMonitor`: Mouse tracking and drag detection
- `accessibility`: Window manipulation via AX API
- `screenManager`: Display configuration and caching
- `settings`: Settings views and configuration changes
- `menuBar`: Menu bar controller operations
- `appDelegate`: Application lifecycle events

View logs in Console.app by filtering for subsystem "com.michaelgrady.UltraSnap".

## Known Technical Debt

1. **Settings Window Layout**: Uses manual frame calculations instead of Auto Layout or SwiftUI. Could be migrated to SwiftUI in v2.0.

2. **Hardcoded Fallback Values**: `getVisibleScreenFrame()` has a hardcoded 1920x1080 fallback. Should handle missing screens more gracefully.

3. **Zone Count Assumptions**: Some UI (menu items, shortcuts) assumes 3 zones. Should dynamically adapt to current preset's zone count.

4. **Test Coverage**: MockSnapEngine exists but test suite needs expansion for edge cases like multi-monitor scenarios.

## v2.0 Refactoring Roadmap

See `NEXT_STEPS.md` for the full feature roadmap. Architecture-relevant items:

### High Priority
- **SwiftUI Migration**: Replace AppKit settings views with SwiftUI for easier maintenance
- **Launch at Login**: Implement using ServiceManagement.SMAppService
- **Custom Keyboard Shortcuts UI**: Allow rebinding via KeyboardShortcuts settings pane

### Medium Priority
- **Zone Customization**: Allow users to define custom zone layouts beyond presets
- **Multi-Monitor Improvements**: Per-monitor zone previews, cross-monitor drag support

### Lower Priority
- **Undo Support**: Remember previous window position for quick undo
- **Animation**: Smooth window transitions when snapping
- **App-Specific Settings**: Different presets for different applications

## Building

```bash
# Build from command line
xcodebuild build -project UltraSnap.xcodeproj -scheme UltraSnap

# Run tests
xcodebuild test -project UltraSnap.xcodeproj -scheme UltraSnap

# Archive for distribution
xcodebuild archive -project UltraSnap.xcodeproj -scheme UltraSnap -archivePath build/UltraSnap.xcarchive
```

## Dependencies

- **KeyboardShortcuts** (SPM): Global hotkey registration
- **macOS 13.0+**: Required for modern APIs used

## File Organization

```
UltraSnap/
├── UltraSnap/
│   ├── AppDelegate.swift       # Entry point
│   ├── main.swift              # App bootstrapping
│   ├── SnapEngine.swift        # Zone calculation & snapping
│   ├── DragMonitor.swift       # Mouse event tracking
│   ├── PreviewOverlay.swift    # Visual feedback overlay
│   ├── MenuBarController.swift # Status bar menu
│   ├── ScreenManager.swift     # Display caching
│   ├── AccessibilityManager.swift  # AX API wrapper
│   ├── DefaultLayouts.swift    # Zone preset definitions
│   ├── Managers/
│   │   ├── ShortcutManager.swift   # Keyboard shortcuts
│   │   └── ConfigurationManager.swift
│   ├── Models/
│   │   ├── DisplayIdentifier.swift
│   │   └── ZonePreset.swift
│   ├── Views/
│   │   ├── GeneralSettingsView.swift
│   │   ├── ZoneSettingsView.swift
│   │   └── ...
│   ├── Controllers/
│   │   └── SettingsWindowController.swift
│   └── Utilities/
│       └── AppLogger.swift     # Centralized logging
├── UltraSnapTests/
│   └── Mocks/
│       └── MockSnapEngine.swift
├── ARCHITECTURE.md             # This file
└── NEXT_STEPS.md               # Feature roadmap
```
