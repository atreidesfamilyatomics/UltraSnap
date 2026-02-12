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
        case .leftHalfRightQuarters:
            return calculateLeftHalfRightQuarters(in: frame)
        case .rightHalfLeftQuarters:
            return calculateRightHalfLeftQuarters(in: frame)
        case .topHalfBottomQuarters:
            return calculateTopHalfBottomQuarters(in: frame)
        case .bottomHalfTopQuarters:
            return calculateBottomHalfTopQuarters(in: frame)
        case .leftTwoThirdsRightQuarters:
            return calculateLeftTwoThirdsRightQuarters(in: frame)
        case .rightTwoThirdsLeftQuarters:
            return calculateRightTwoThirdsLeftQuarters(in: frame)
        case .leftThirdRightSixths:
            return calculateLeftThirdRightSixths(in: frame)
        case .rightThirdLeftSixths:
            return calculateRightThirdLeftSixths(in: frame)
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

    // MARK: - Asymmetric Layouts

    // Left Half + Right 2×2: Left 50% one zone; right 50% quarters
    // Zone layout (5 zones):
    // ┌──────────────┬──────┬──────┐
    // │              │  1   │  2   │
    // │      0       ├──────┼──────┤
    // │              │  3   │  4   │
    // └──────────────┴──────┴──────┘
    // Zone order: 0 = left full; 1 = top-right, 2 = top-left (right half), 3 = bottom-right, 4 = bottom-left (right half)
    private static func calculateLeftHalfRightQuarters(in frame: CGRect) -> [CGRect] {
        let halfWidth = frame.width / 2
        let quarterHeight = frame.height / 2
        let quarterWidth = frame.width / 4

        return [
            // Zone 0: Left full height
            CGRect(x: frame.minX, y: frame.minY, width: halfWidth, height: frame.height),
            // Zone 1: Top-right (of right half)
            CGRect(x: frame.minX + halfWidth, y: frame.minY + quarterHeight, width: quarterWidth, height: quarterHeight),
            // Zone 2: Top-left (of right half)
            CGRect(x: frame.minX + halfWidth + quarterWidth, y: frame.minY + quarterHeight, width: quarterWidth, height: quarterHeight),
            // Zone 3: Bottom-right (of right half)
            CGRect(x: frame.minX + halfWidth, y: frame.minY, width: quarterWidth, height: quarterHeight),
            // Zone 4: Bottom-left (of right half)
            CGRect(x: frame.minX + halfWidth + quarterWidth, y: frame.minY, width: quarterWidth, height: quarterHeight)
        ]
    }

    // Right Half + Left 2×2: Right 50% one zone; left 50% quarters
    // Zone layout (5 zones):
    // ┌──────┬──────┬──────────────┐
    // │  0   │  1   │              │
    // ├──────┼──────┤      4       │
    // │  2   │  3   │              │
    // └──────┴──────┴──────────────┘
    // Zone order: 0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right; 4 = right full
    private static func calculateRightHalfLeftQuarters(in frame: CGRect) -> [CGRect] {
        let halfWidth = frame.width / 2
        let quarterHeight = frame.height / 2
        let quarterWidth = frame.width / 4

        return [
            // Zone 0: Top-left
            CGRect(x: frame.minX, y: frame.minY + quarterHeight, width: quarterWidth, height: quarterHeight),
            // Zone 1: Top-right (of left half)
            CGRect(x: frame.minX + quarterWidth, y: frame.minY + quarterHeight, width: quarterWidth, height: quarterHeight),
            // Zone 2: Bottom-left
            CGRect(x: frame.minX, y: frame.minY, width: quarterWidth, height: quarterHeight),
            // Zone 3: Bottom-right (of left half)
            CGRect(x: frame.minX + quarterWidth, y: frame.minY, width: quarterWidth, height: quarterHeight),
            // Zone 4: Right full height
            CGRect(x: frame.minX + halfWidth, y: frame.minY, width: halfWidth, height: frame.height)
        ]
    }

    // Top Half + Bottom 2×2: Top 50% one zone; bottom 50% quarters
    // Zone layout (5 zones):
    // ┌─────────────────────────────┐
    // │              0              │
    // ├──────────────┬──────────────┤
    // │      1       │      2       │
    // ├──────────────┼──────────────┤
    // │      3       │      4       │
    // └──────────────┴──────────────┘
    // Zone order: 0 = top full; 1 = bottom-left top, 2 = bottom-right top, 3 = bottom-left bottom, 4 = bottom-right bottom
    private static func calculateTopHalfBottomQuarters(in frame: CGRect) -> [CGRect] {
        let halfHeight = frame.height / 2
        let quarterHeight = frame.height / 4
        let halfWidth = frame.width / 2

        return [
            // Zone 0: Top full width
            CGRect(x: frame.minX, y: frame.minY + halfHeight, width: frame.width, height: halfHeight),
            // Zone 1: Bottom half, top-left
            CGRect(x: frame.minX, y: frame.minY + quarterHeight, width: halfWidth, height: quarterHeight),
            // Zone 2: Bottom half, top-right
            CGRect(x: frame.minX + halfWidth, y: frame.minY + quarterHeight, width: halfWidth, height: quarterHeight),
            // Zone 3: Bottom half, bottom-left
            CGRect(x: frame.minX, y: frame.minY, width: halfWidth, height: quarterHeight),
            // Zone 4: Bottom half, bottom-right
            CGRect(x: frame.minX + halfWidth, y: frame.minY, width: halfWidth, height: quarterHeight)
        ]
    }

    // Bottom Half + Top 2×2: Bottom 50% one zone; top 50% quarters
    // Zone layout (5 zones):
    // ┌──────────────┬──────────────┐
    // │      0       │      1       │
    // ├──────────────┼──────────────┤
    // │      2       │      3       │
    // ├─────────────────────────────┤
    // │              4              │
    // └─────────────────────────────┘
    // Zone order: 0 = top-left, 1 = top-right, 2 = middle-left, 3 = middle-right; 4 = bottom full
    private static func calculateBottomHalfTopQuarters(in frame: CGRect) -> [CGRect] {
        let halfHeight = frame.height / 2
        let quarterHeight = frame.height / 4
        let halfWidth = frame.width / 2

        return [
            // Zone 0: Top half, top-left
            CGRect(x: frame.minX, y: frame.minY + halfHeight + quarterHeight, width: halfWidth, height: quarterHeight),
            // Zone 1: Top half, top-right
            CGRect(x: frame.minX + halfWidth, y: frame.minY + halfHeight + quarterHeight, width: halfWidth, height: quarterHeight),
            // Zone 2: Top half, bottom-left
            CGRect(x: frame.minX, y: frame.minY + halfHeight, width: halfWidth, height: quarterHeight),
            // Zone 3: Top half, bottom-right
            CGRect(x: frame.minX + halfWidth, y: frame.minY + halfHeight, width: halfWidth, height: quarterHeight),
            // Zone 4: Bottom full width
            CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: halfHeight)
        ]
    }

    // Left 2/3 + Right 2×2: Left 2/3 one zone; right 1/3 as 2×2
    // Zone layout (5 zones):
    // ┌────────────────────┬─────┬─────┐
    // │                    │  1  │  2  │
    // │         0          ├─────┼─────┤
    // │                    │  3  │  4  │
    // └────────────────────┴─────┴─────┘
    // Zone order: 0 = left 2/3 full; 1–4 = four small quads on right
    private static func calculateLeftTwoThirdsRightQuarters(in frame: CGRect) -> [CGRect] {
        let twoThirdsWidth = frame.width * 2 / 3
        let halfHeight = frame.height / 2
        
        // Calculate right 1/3 start position and width
        let rightStartX = frame.minX + twoThirdsWidth
        let rightWidth = frame.maxX - rightStartX
        let rightHalfWidth = rightWidth / 2

        return [
            // Zone 0: Left 2/3 full height
            CGRect(x: frame.minX, y: frame.minY, width: twoThirdsWidth, height: frame.height),
            // Zone 1: Right 1/3, top-left
            CGRect(x: rightStartX, y: frame.minY + halfHeight, width: rightHalfWidth, height: halfHeight),
            // Zone 2: Right 1/3, top-right
            CGRect(x: rightStartX + rightHalfWidth, y: frame.minY + halfHeight, width: rightWidth - rightHalfWidth, height: halfHeight),
            // Zone 3: Right 1/3, bottom-left
            CGRect(x: rightStartX, y: frame.minY, width: rightHalfWidth, height: halfHeight),
            // Zone 4: Right 1/3, bottom-right
            CGRect(x: rightStartX + rightHalfWidth, y: frame.minY, width: rightWidth - rightHalfWidth, height: halfHeight)
        ]
    }

    // Right 2/3 + Left 2×2: Right 2/3 one zone; left 1/3 as 2×2
    // Zone layout (5 zones):
    // ┌─────┬─────┬────────────────────┐
    // │  0  │  1  │                    │
    // ├─────┼─────┤         4          │
    // │  2  │  3  │                    │
    // └─────┴─────┴────────────────────┘
    // Zone order: 0–3 = left 2×2; 4 = right 2/3 full
    private static func calculateRightTwoThirdsLeftQuarters(in frame: CGRect) -> [CGRect] {
        let oneThirdWidth = frame.width / 3
        let halfHeight = frame.height / 2
        
        // Calculate left 1/3 width
        let leftWidth = oneThirdWidth
        let leftHalfWidth = leftWidth / 2
        
        // Calculate right 2/3 start position and width
        let rightStartX = frame.minX + oneThirdWidth
        let rightWidth = frame.maxX - rightStartX

        return [
            // Zone 0: Left 1/3, top-left
            CGRect(x: frame.minX, y: frame.minY + halfHeight, width: leftHalfWidth, height: halfHeight),
            // Zone 1: Left 1/3, top-right
            CGRect(x: frame.minX + leftHalfWidth, y: frame.minY + halfHeight, width: leftWidth - leftHalfWidth, height: halfHeight),
            // Zone 2: Left 1/3, bottom-left
            CGRect(x: frame.minX, y: frame.minY, width: leftHalfWidth, height: halfHeight),
            // Zone 3: Left 1/3, bottom-right
            CGRect(x: frame.minX + leftHalfWidth, y: frame.minY, width: leftWidth - leftHalfWidth, height: halfHeight),
            // Zone 4: Right 2/3 full height
            CGRect(x: rightStartX, y: frame.minY, width: rightWidth, height: frame.height)
        ]
    }

    // Left 1/3 + Right 2×3: Left 1/3 one zone; right 2/3 as sixths
    // Zone layout (7 zones):
    // ┌──────────┬─────┬─────┬─────┐
    // │          │  1  │  2  │  3  │
    // │    0     ├─────┼─────┼─────┤
    // │          │  4  │  5  │  6  │
    // └──────────┴─────┴─────┴─────┘
    // Zone order: 0 = left 1/3 full; 1–6 = sixths in right 2/3
    private static func calculateLeftThirdRightSixths(in frame: CGRect) -> [CGRect] {
        let oneThirdWidth = frame.width / 3
        let halfHeight = frame.height / 2
        
        // Calculate right 2/3 start position and width
        let rightStartX = frame.minX + oneThirdWidth
        let rightWidth = frame.maxX - rightStartX
        let rightColWidth = rightWidth / 3

        return [
            // Zone 0: Left 1/3 full height
            CGRect(x: frame.minX, y: frame.minY, width: oneThirdWidth, height: frame.height),
            // Right 2/3 as 2×3 grid (top row, left to right)
            // Zone 1: Top-left
            CGRect(x: rightStartX, y: frame.minY + halfHeight, width: rightColWidth, height: halfHeight),
            // Zone 2: Top-center
            CGRect(x: rightStartX + rightColWidth, y: frame.minY + halfHeight, width: rightColWidth, height: halfHeight),
            // Zone 3: Top-right
            CGRect(x: rightStartX + rightColWidth * 2, y: frame.minY + halfHeight, width: rightWidth - rightColWidth * 2, height: halfHeight),
            // Right 2/3 as 2×3 grid (bottom row, left to right)
            // Zone 4: Bottom-left
            CGRect(x: rightStartX, y: frame.minY, width: rightColWidth, height: halfHeight),
            // Zone 5: Bottom-center
            CGRect(x: rightStartX + rightColWidth, y: frame.minY, width: rightColWidth, height: halfHeight),
            // Zone 6: Bottom-right
            CGRect(x: rightStartX + rightColWidth * 2, y: frame.minY, width: rightWidth - rightColWidth * 2, height: halfHeight)
        ]
    }

    // Right 1/3 + Left 2×3: Right 1/3 one zone; left 2/3 as sixths
    // Zone layout (7 zones):
    // ┌─────┬─────┬─────┬──────────┐
    // │  0  │  1  │  2  │          │
    // ├─────┼─────┼─────┤    6     │
    // │  3  │  4  │  5  │          │
    // └─────┴─────┴─────┴──────────┘
    // Zone order: 0–5 = sixths in left 2/3; 6 = right 1/3 full
    private static func calculateRightThirdLeftSixths(in frame: CGRect) -> [CGRect] {
        let twoThirdsWidth = frame.width * 2 / 3
        let halfHeight = frame.height / 2
        
        // Calculate left 2/3 width and column width
        let leftWidth = twoThirdsWidth
        let leftColWidth = leftWidth / 3
        
        // Calculate right 1/3 start position and width
        let rightStartX = frame.minX + twoThirdsWidth
        let rightWidth = frame.maxX - rightStartX

        return [
            // Left 2/3 as 2×3 grid (top row, left to right)
            // Zone 0: Top-left
            CGRect(x: frame.minX, y: frame.minY + halfHeight, width: leftColWidth, height: halfHeight),
            // Zone 1: Top-center
            CGRect(x: frame.minX + leftColWidth, y: frame.minY + halfHeight, width: leftColWidth, height: halfHeight),
            // Zone 2: Top-right
            CGRect(x: frame.minX + leftColWidth * 2, y: frame.minY + halfHeight, width: leftWidth - leftColWidth * 2, height: halfHeight),
            // Left 2/3 as 2×3 grid (bottom row, left to right)
            // Zone 3: Bottom-left
            CGRect(x: frame.minX, y: frame.minY, width: leftColWidth, height: halfHeight),
            // Zone 4: Bottom-center
            CGRect(x: frame.minX + leftColWidth, y: frame.minY, width: leftColWidth, height: halfHeight),
            // Zone 5: Bottom-right
            CGRect(x: frame.minX + leftColWidth * 2, y: frame.minY, width: leftWidth - leftColWidth * 2, height: halfHeight),
            // Zone 6: Right 1/3 full height
            CGRect(x: rightStartX, y: frame.minY, width: rightWidth, height: frame.height)
        ]
    }
}
