import Cocoa

struct DefaultLayouts {

    // Calculate zones for a given preset
    static func zones(for preset: ZonePreset, on screen: NSScreen) -> [CGRect] {
        let frame = screen.visibleFrame

        switch preset {
        case .off:
            return []  // No zones - snapping disabled
        case .thirds:
            return calculateThirds(in: frame)
        case .halves:
            return calculateHalves(in: frame)
        case .quarters:
            return calculateQuarters(in: frame)
        case .sixths:
            return calculateSixths(in: frame)
        case .eighths:
            return calculateEighths(in: frame)
        case .wideLeft:
            return calculateWideLeft(in: frame)
        case .wideCenter:
            return calculateWideCenter(in: frame)
        case .verticalHalves:
            return calculateVerticalHalves(in: frame)
        case .verticalThirds:
            return calculateVerticalThirds(in: frame)
        case .grid:
            return calculateGrid(in: frame)
        }
    }

    // MARK: - Preset Calculations

    private static func calculateThirds(in frame: CGRect) -> [CGRect] {
        let width = frame.width / 3

        return [
            CGRect(x: frame.minX, y: frame.minY, width: width, height: frame.height),
            CGRect(x: frame.minX + width, y: frame.minY, width: width, height: frame.height),
            CGRect(x: frame.minX + (width * 2), y: frame.minY, width: width, height: frame.height)
        ]
    }

    private static func calculateHalves(in frame: CGRect) -> [CGRect] {
        let width = frame.width / 2

        return [
            CGRect(x: frame.minX, y: frame.minY, width: width, height: frame.height),
            CGRect(x: frame.minX + width, y: frame.minY, width: width, height: frame.height)
        ]
    }

    private static func calculateQuarters(in frame: CGRect) -> [CGRect] {
        let width = frame.width / 2
        let height = frame.height / 2

        return [
            CGRect(x: frame.minX, y: frame.minY + height, width: width, height: height),           // Top-left
            CGRect(x: frame.minX + width, y: frame.minY + height, width: width, height: height),   // Top-right
            CGRect(x: frame.minX, y: frame.minY, width: width, height: height),                     // Bottom-left
            CGRect(x: frame.minX + width, y: frame.minY, width: width, height: height)             // Bottom-right
        ]
    }

    private static func calculateWideLeft(in frame: CGRect) -> [CGRect] {
        let leftWidth = frame.width * 0.4
        let otherWidth = frame.width * 0.3

        return [
            CGRect(x: frame.minX, y: frame.minY, width: leftWidth, height: frame.height),
            CGRect(x: frame.minX + leftWidth, y: frame.minY, width: otherWidth, height: frame.height),
            CGRect(x: frame.minX + leftWidth + otherWidth, y: frame.minY, width: otherWidth, height: frame.height)
        ]
    }

    private static func calculateWideCenter(in frame: CGRect) -> [CGRect] {
        let sideWidth = frame.width * 0.3
        let centerWidth = frame.width * 0.4

        return [
            CGRect(x: frame.minX, y: frame.minY, width: sideWidth, height: frame.height),
            CGRect(x: frame.minX + sideWidth, y: frame.minY, width: centerWidth, height: frame.height),
            CGRect(x: frame.minX + sideWidth + centerWidth, y: frame.minY, width: sideWidth, height: frame.height)
        ]
    }

    private static func calculateVerticalHalves(in frame: CGRect) -> [CGRect] {
        let halfHeight = frame.height / 2

        return [
            CGRect(x: frame.minX, y: frame.minY + halfHeight, width: frame.width, height: halfHeight),  // Top
            CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: halfHeight)  // Bottom
        ]
    }

    private static func calculateVerticalThirds(in frame: CGRect) -> [CGRect] {
        let rowHeight = frame.height / 3

        return [
            CGRect(x: frame.minX, y: frame.minY + rowHeight * 2, width: frame.width, height: rowHeight),  // Top
            CGRect(x: frame.minX, y: frame.minY + rowHeight, width: frame.width, height: rowHeight),      // Middle
            CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: rowHeight)                    // Bottom
        ]
    }

    private static func calculateGrid(in frame: CGRect) -> [CGRect] {
        let colWidth = frame.width / 2
        let rowHeight = frame.height / 3

        return [
            // Top row
            CGRect(x: frame.minX, y: frame.minY + rowHeight * 2, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth, y: frame.minY + rowHeight * 2, width: colWidth, height: rowHeight),
            // Middle row
            CGRect(x: frame.minX, y: frame.minY + rowHeight, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth, y: frame.minY + rowHeight, width: colWidth, height: rowHeight),
            // Bottom row
            CGRect(x: frame.minX, y: frame.minY, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth, y: frame.minY, width: colWidth, height: rowHeight)
        ]
    }

    // Sixths: 2 rows × 3 columns (6 zones)
    // Zone layout:
    // ┌─────────┬─────────┬─────────┐
    // │ Zone 0  │ Zone 1  │ Zone 2  │
    // ├─────────┼─────────┼─────────┤
    // │ Zone 3  │ Zone 4  │ Zone 5  │
    // └─────────┴─────────┴─────────┘
    private static func calculateSixths(in frame: CGRect) -> [CGRect] {
        let colWidth = frame.width / 3
        let rowHeight = frame.height / 2

        return [
            // Top row (left to right)
            CGRect(x: frame.minX, y: frame.minY + rowHeight, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth, y: frame.minY + rowHeight, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth * 2, y: frame.minY + rowHeight, width: colWidth, height: rowHeight),
            // Bottom row (left to right)
            CGRect(x: frame.minX, y: frame.minY, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth, y: frame.minY, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth * 2, y: frame.minY, width: colWidth, height: rowHeight)
        ]
    }

    // Eighths: 2 rows × 4 columns (8 zones)
    // Zone layout:
    // ┌──────┬──────┬──────┬──────┐
    // │  0   │  1   │  2   │  3   │
    // ├──────┼──────┼──────┼──────┤
    // │  4   │  5   │  6   │  7   │
    // └──────┴──────┴──────┴──────┘
    private static func calculateEighths(in frame: CGRect) -> [CGRect] {
        let colWidth = frame.width / 4
        let rowHeight = frame.height / 2

        return [
            // Top row (left to right)
            CGRect(x: frame.minX, y: frame.minY + rowHeight, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth, y: frame.minY + rowHeight, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth * 2, y: frame.minY + rowHeight, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth * 3, y: frame.minY + rowHeight, width: colWidth, height: rowHeight),
            // Bottom row (left to right)
            CGRect(x: frame.minX, y: frame.minY, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth, y: frame.minY, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth * 2, y: frame.minY, width: colWidth, height: rowHeight),
            CGRect(x: frame.minX + colWidth * 3, y: frame.minY, width: colWidth, height: rowHeight)
        ]
    }
}
