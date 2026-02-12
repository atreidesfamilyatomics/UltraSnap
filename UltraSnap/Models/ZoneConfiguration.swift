import Foundation
import Cocoa

// MARK: - Zone Preset Types

enum ZonePreset: String, Codable, CaseIterable {
    case off = "Off"
    case thirds = "Equal Thirds"
    case halves = "Halves"
    case quarters = "Quarters"
    case sixths = "Sixths (2x3)"
    case eighths = "Eighths (2x4)"
    case wideLeft = "Wide Left (40/30/30)"
    case wideCenter = "Wide Center (30/40/30)"
    case verticalHalves = "Vertical Halves"
    case verticalThirds = "Vertical Thirds"
    case grid = "Grid (2x3)"
    
    // Asymmetric presets
    case leftHalfRightQuarters = "Left Half + Right 2×2"
    case rightHalfLeftQuarters = "Right Half + Left 2×2"
    case topHalfBottomQuarters = "Top Half + Bottom 2×2"
    case bottomHalfTopQuarters = "Bottom Half + Top 2×2"
    case leftTwoThirdsRightQuarters = "Left 2/3 + Right 2×2"
    case rightTwoThirdsLeftQuarters = "Right 2/3 + Left 2×2"
    case leftThirdRightSixths = "Left 1/3 + Right 2×3"
    case rightThirdLeftSixths = "Right 1/3 + Left 2×3"

    var description: String {
        return self.rawValue
    }

    var zoneCount: Int {
        switch self {
        case .off: return 0
        case .thirds: return 3
        case .halves: return 2
        case .quarters: return 4
        case .sixths: return 6
        case .eighths: return 8
        case .wideLeft: return 3
        case .wideCenter: return 3
        case .verticalHalves: return 2
        case .verticalThirds: return 3
        case .grid: return 6
        case .leftHalfRightQuarters, .rightHalfLeftQuarters,
             .topHalfBottomQuarters, .bottomHalfTopQuarters,
             .leftTwoThirdsRightQuarters, .rightTwoThirdsLeftQuarters:
            return 5
        case .leftThirdRightSixths, .rightThirdLeftSixths:
            return 7
        }
    }

    /// Grid shape (columns, rows) for presets with uniform grids.
    /// Returns nil for presets without a simple grid structure or when disabled.
    /// Used by edge/corner trigger detection to map cursor position to zone index.
    var gridShape: (columns: Int, rows: Int)? {
        switch self {
        case .off:
            return nil
        case .thirds:
            return (3, 1)
        case .halves:
            return (2, 1)
        case .quarters:
            return (2, 2)
        case .sixths:
            return (3, 2)
        case .eighths:
            return (4, 2)
        case .wideLeft, .wideCenter:
            // These have variable-width columns, only support top triggers
            return nil
        case .verticalHalves:
            return (1, 2)
        case .verticalThirds:
            return (1, 3)
        case .grid:
            return (2, 3)
        case .leftHalfRightQuarters, .rightHalfLeftQuarters,
             .topHalfBottomQuarters, .bottomHalfTopQuarters,
             .leftTwoThirdsRightQuarters, .rightTwoThirdsLeftQuarters,
             .leftThirdRightSixths, .rightThirdLeftSixths:
            // Asymmetric presets don't have uniform grids, only support top triggers
            return nil
        }
    }
}

// MARK: - Display Configuration

struct DisplayConfiguration: Codable, Equatable {
    let displayIdentifier: DisplayIdentifier
    let preset: ZonePreset

    init(displayIdentifier: DisplayIdentifier, preset: ZonePreset = .thirds) {
        self.displayIdentifier = displayIdentifier
        self.preset = preset
    }
}

// MARK: - Zone Configuration

struct ZoneConfiguration: Codable, Equatable {
    let version: Int
    let displays: [DisplayConfiguration]

    init(version: Int = 1, displays: [DisplayConfiguration]) {
        self.version = version
        self.displays = displays
    }

    // Factory method for default configuration
    static func defaultConfiguration(for screens: [NSScreen]) -> ZoneConfiguration {
        let displayConfigs = screens.map { screen in
            let identifier = DisplayIdentifier(from: screen)
            return DisplayConfiguration(displayIdentifier: identifier, preset: .thirds)
        }
        return ZoneConfiguration(version: 1, displays: displayConfigs)
    }

    // Get preset for a specific display
    func preset(for displayIdentifier: DisplayIdentifier) -> ZonePreset? {
        return displays.first { $0.displayIdentifier == displayIdentifier }?.preset
    }

    // Update preset for a display
    func updatingPreset(for displayIdentifier: DisplayIdentifier, to preset: ZonePreset) -> ZoneConfiguration {
        var updatedDisplays = displays

        if let index = updatedDisplays.firstIndex(where: { $0.displayIdentifier == displayIdentifier }) {
            updatedDisplays[index] = DisplayConfiguration(displayIdentifier: displayIdentifier, preset: preset)
        } else {
            // Add new display configuration
            updatedDisplays.append(DisplayConfiguration(displayIdentifier: displayIdentifier, preset: preset))
        }

        return ZoneConfiguration(version: version, displays: updatedDisplays)
    }
}
