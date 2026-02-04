<div align="center">

# 🪟 UltraSnap

**Window management reimagined for ultrawide displays**

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-active-success.svg)](https://github.com)

*Snap windows into perfect zones. Drag to arrange. Keyboard shortcuts for power users. Built for macOS.*

</div>

---

## ✨ Features

### 🎯 **Smart Zone Snapping**
- **Drag-to-snap**: Drag any window to the top of your screen to see zone previews
- **Keyboard shortcuts**: Instantly snap windows with customizable hotkeys
- **Visual feedback**: See exactly where your window will snap before you release

### 📐 **Flexible Layout Presets**
Choose from 8 built-in zone layouts optimized for different workflows:

- **Equal Thirds** (33/33/33) - Classic ultrawide layout
- **Halves** (50/50) - Simple left/right split
- **Quarters** (2×2 grid) - Four-zone multitasking
- **Wide Left** (40/30/30) - Perfect for IDE + browser
- **Wide Center** (30/40/30) - Browser-focused workflow
- **Vertical Halves** - Top/bottom split for vertical monitors
- **Vertical Thirds** - Three horizontal rows
- **Grid (2×3)** - Six-zone maximum organization

### 🖥️ **Multi-Monitor Support**
- **Per-display configuration**: Different layouts for each monitor
- **Stable display identification**: Remembers your setup even after reconnecting
- **Automatic detection**: Handles display changes gracefully

### ⚙️ **Customizable & Persistent**
- **Settings UI**: Native macOS preferences window
- **Per-monitor presets**: Save different layouts for each display
- **Keyboard shortcut customization**: Rebind any shortcut to your preference
- **Configuration persistence**: Your settings survive app restarts

### 🚀 **Lightweight & Native**
- **Menu bar app**: Lives quietly in your menu bar
- **Zero bloat**: Built with Swift and AppKit
- **Accessibility API**: Uses macOS native window management
- **Low overhead**: Minimal resource usage

---

## 🎬 Quick Start

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/UltraSnap.git
   cd UltraSnap
   ```

2. **Build with Xcode**
   ```bash
   xcodebuild build -project UltraSnap.xcodeproj -scheme UltraSnap -configuration Release
   ```

3. **Install to Applications**
   ```bash
   cp -r ~/Library/Developer/Xcode/DerivedData/UltraSnap-*/Build/Products/Release/UltraSnap.app ~/Applications/
   ```

4. **Grant Accessibility Permission**
   - Open **System Settings** → **Privacy & Security** → **Accessibility**
   - Enable **UltraSnap** (you'll be prompted on first launch)

5. **Launch UltraSnap**
   - Open from `~/Applications/UltraSnap.app`
   - Look for the menu bar icon (three-column symbol)

### First Use

1. **Drag a window** to the top of your screen
2. **See the preview** showing where it will snap
3. **Release** to snap into place
4. **Or use keyboard shortcuts**: `Ctrl+Option+1/2/3` (default)

---

## 📖 Usage Guide

### Drag-to-Snap

1. **Start dragging** any window
2. **Move to the top** of your screen (within ~100pt)
3. **Preview appears** showing available zones
4. **Drag into a zone** and release

### Keyboard Shortcuts

Default shortcuts (customizable in Settings):

| Shortcut | Action |
|----------|--------|
| `Ctrl+Option+1` | Snap to left zone |
| `Ctrl+Option+2` | Snap to center zone |
| `Ctrl+Option+3` | Snap to right zone |

*Note: Zone numbers depend on your selected preset (e.g., Quarters has 4 zones)*

### Menu Bar Actions

Click the menu bar icon for quick access:

- **Snap to Zone 1/2/3** - Instant snapping
- **Settings...** - Open preferences window
- **Quit UltraSnap** - Exit the app

---

## ⚙️ Configuration

### Settings Window

Open Settings from the menu bar or use `Cmd+,` when Settings is focused.

#### Zone Presets Tab
- **Select Display**: Choose which monitor to configure
- **Choose Preset**: Pick from 8 built-in layouts
- **Live Preview**: See zone layout before applying
- **Auto-save**: Changes apply immediately

#### Keyboard Tab
- **Customize Shortcuts**: Click recorders to set new shortcuts
- **Reset to Defaults**: Restore original shortcuts
- **Conflict Detection**: Warns about system shortcuts

#### General Tab
- **Show Zone Preview**: Toggle drag preview overlay
- **Launch at Login**: *(Coming in v2.0)*
- **About**: Version and app info

### Configuration Storage

Settings are stored at:
```
~/Library/Application Support/UltraSnap/display-config.json
```

You can manually edit this JSON file for advanced configuration.

---

## 🏗️ Architecture

UltraSnap is built with a clean, modular architecture:

```
┌─────────────────────────────────────┐
│         AppDelegate                  │
│  (Lifecycle & Initialization)       │
└──────────────┬──────────────────────┘
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
┌─────────┐ ┌─────────┐ ┌─────────────┐
│ MenuBar  │ │  Drag   │ │  Shortcut   │
│Controller│ │ Monitor │ │  Manager    │
└─────────┘ └────┬─────┘ └─────────────┘
                 │
                 ▼
          ┌─────────────┐
          │  SnapEngine │
          │  (Core Logic)│
          └──────┬──────┘
                 │
        ┌────────┼────────┐
        ▼        ▼        ▼
  ┌─────────┐ ┌──────┐ ┌──────────────┐
  │ Screen  │ │ AX   │ │ Preview      │
  │ Manager │ │ API  │ │ Overlay      │
  └─────────┘ └──────┘ └──────────────┘
```

### Key Components

- **SnapEngine**: Calculates zones and coordinates window snapping
- **DragMonitor**: Tracks mouse events for drag-to-snap
- **AccessibilityManager**: Wrapper around macOS Accessibility API
- **ScreenManager**: Caches display information for performance
- **ConfigurationManager**: Persists settings per display
- **PreviewOverlay**: Visual feedback during drag operations

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed documentation.

---

## 🧪 Development

### Requirements

- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+**
- **Swift 5.9+**

### Dependencies

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - Global hotkey registration (SPM)

### Building

```bash
# Debug build
xcodebuild build -project UltraSnap.xcodeproj -scheme UltraSnap -configuration Debug

# Release build
xcodebuild build -project UltraSnap.xcodeproj -scheme UltraSnap -configuration Release

# Run tests
xcodebuild test -project UltraSnap.xcodeproj -scheme UltraSnap

# Archive for distribution
xcodebuild archive -project UltraSnap.xcodeproj -scheme UltraSnap \
  -archivePath build/UltraSnap.xcarchive
```

### Project Structure

```
UltraSnap/
├── UltraSnap/                    # Main app target
│   ├── AppDelegate.swift         # Entry point
│   ├── SnapEngine.swift          # Zone calculation
│   ├── DragMonitor.swift         # Mouse tracking
│   ├── PreviewOverlay.swift      # Visual feedback
│   ├── MenuBarController.swift   # Status bar menu
│   ├── Managers/                 # Configuration & shortcuts
│   ├── Models/                   # Data models
│   ├── Views/                    # Settings UI
│   ├── Controllers/              # Window controllers
│   └── Utilities/                # Helpers & logging
├── UltraSnapTests/               # Test suite
├── ARCHITECTURE.md               # Architecture docs
└── NEXT_STEPS.md                 # Roadmap
```

### Logging

UltraSnap uses unified logging (`os.Logger`). View logs in Console.app:

1. Open **Console.app**
2. Filter for subsystem: `com.michaelgrady.UltraSnap`
3. Categories: `snapEngine`, `dragMonitor`, `accessibility`, `screenManager`, `settings`

---

## 🗺️ Roadmap

### ✅ v1.0 (Complete)
- [x] Drag-to-snap window management
- [x] Three-zone layout (thirds)
- [x] Menu bar integration
- [x] Custom app icon
- [x] Multi-monitor support
- [x] Settings UI
- [x] Keyboard shortcuts
- [x] Configuration persistence

### 🚧 v2.0 (Planned)
- [ ] Custom zone ratios
- [ ] Launch at login
- [ ] SwiftUI migration
- [ ] Additional layout presets (sixths, eighths)
- [ ] Zone gap configuration
- [ ] Animation customization
- [ ] Per-application settings

See [NEXT_STEPS.md](NEXT_STEPS.md) for the full roadmap.

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Add tests** for new functionality
5. **Commit your changes** (`git commit -m 'Add amazing feature'`)
6. **Push to the branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

### Development Guidelines

- Follow Swift API Design Guidelines
- Write tests for new features
- Update documentation as needed
- Use `AppLogger` for all logging
- Keep the architecture modular

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

Inspired by:
- [Rectangle](https://github.com/rxhanson/Rectangle) - Open source macOS window manager
- [Magnet](https://apps.apple.com/app/magnet/id441258766) - Commercial window manager
- [Spectacle](https://github.com/eczarny/spectacle) - Classic macOS window manager

Built with:
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus
- Apple's Accessibility API
- Swift and AppKit

---

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/UltraSnap/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/UltraSnap/discussions)

---

<div align="center">

**Made with ❤️ for ultrawide display users**

[⬆ Back to Top](#-ultrasnap)

</div>
