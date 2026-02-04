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
