import Foundation
import CoreGraphics

/// One peg in a wave pattern. Coordinates are normalized: x 0…1 across the
/// playfield width, y 0…1 of scene height (patterns live in 0.38…0.92).
struct PegSpec: Equatable {
    let x: CGFloat
    let y: CGFloat
    let armored: Bool

    init(_ x: CGFloat, _ y: CGFloat, armored: Bool = false) {
        self.x = x
        self.y = y
        self.armored = armored
    }
}

/// Hand-authored wave patterns. Waves past the library cycle its final four.
enum WaveLibrary {
    static func pegs(forWave wave: Int) -> [PegSpec] {
        let idx: Int
        if wave <= patterns.count {
            idx = wave - 1
        } else {
            idx = patterns.count - 4 + (wave - patterns.count - 1) % 4
        }
        var specs = patterns[idx]
        if wave >= GameConfig.armoredFromWave {
            // Promote every 5th peg to armored, deterministically.
            specs = specs.enumerated().map { i, p in
                i % 5 == 4 ? PegSpec(p.x, p.y, armored: true) : p
            }
        }
        return specs
    }

    // MARK: pattern builders

    private static func row(y: CGFloat, count: Int, inset: CGFloat = 0.12) -> [PegSpec] {
        guard count > 1 else { return [PegSpec(0.5, y)] }
        let span = 1 - 2 * inset
        return (0..<count).map { i in
            PegSpec(inset + span * CGFloat(i) / CGFloat(count - 1), y)
        }
    }

    private static func arc(centerY: CGFloat, amplitude: CGFloat, count: Int, inset: CGFloat = 0.12) -> [PegSpec] {
        let span = 1 - 2 * inset
        return (0..<count).map { i in
            let t = CGFloat(i) / CGFloat(count - 1)
            let y = centerY + amplitude * sin(t * .pi)
            return PegSpec(inset + span * t, y)
        }
    }

    private static func diamond(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> [PegSpec] {
        [PegSpec(cx, cy + ry), PegSpec(cx + rx, cy), PegSpec(cx, cy - ry), PegSpec(cx - rx, cy)]
    }

    private static func ring(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, count: Int) -> [PegSpec] {
        (0..<count).map { i in
            let a = 2 * .pi * CGFloat(i) / CGFloat(count)
            return PegSpec(cx + rx * cos(a), cy + ry * sin(a))
        }
    }

    private static func zigzag(rows: Int, perRow: Int, top: CGFloat, bottom: CGFloat) -> [PegSpec] {
        (0..<rows).flatMap { r -> [PegSpec] in
            let y = top - (top - bottom) * CGFloat(r) / CGFloat(max(rows - 1, 1))
            let inset: CGFloat = r % 2 == 0 ? 0.12 : 0.20
            return row(y: y, count: perRow, inset: inset)
        }
    }

    // MARK: the authored waves

    static let patterns: [[PegSpec]] = [
        // 1 — a generous welcome: three rows, low centre of mass so the first
        // flip cracks several orbs inside 10 seconds (R2: was 9 sparse pegs —
        // the emptiest minute of the game was the first one).
        row(y: 0.54, count: 5) + row(y: 0.66, count: 4, inset: 0.22) + row(y: 0.78, count: 5),
        // 2 — smile arc with a low chin row
        arc(centerY: 0.55, amplitude: 0.22, count: 9) + row(y: 0.48, count: 3, inset: 0.32),
        // 3 — twin diamonds
        diamond(cx: 0.30, cy: 0.62, rx: 0.13, ry: 0.09) + diamond(cx: 0.70, cy: 0.62, rx: 0.13, ry: 0.09)
            + row(y: 0.84, count: 3, inset: 0.30),
        // 4 — the grid tightens (armored appears)
        zigzag(rows: 3, perRow: 5, top: 0.80, bottom: 0.52),
        // 5 — big ring with a heart
        ring(cx: 0.5, cy: 0.65, rx: 0.30, ry: 0.16, count: 10) + [PegSpec(0.5, 0.65)],
        // 6 — double arc canopy
        arc(centerY: 0.50, amplitude: 0.18, count: 8) + arc(centerY: 0.66, amplitude: 0.18, count: 7, inset: 0.18),
        // 7 — chevrons
        [PegSpec(0.20, 0.80), PegSpec(0.30, 0.72), PegSpec(0.40, 0.64), PegSpec(0.50, 0.56),
         PegSpec(0.60, 0.64), PegSpec(0.70, 0.72), PegSpec(0.80, 0.80),
         PegSpec(0.35, 0.86), PegSpec(0.50, 0.90), PegSpec(0.65, 0.86)],
        // 8 — dense zigzag
        zigzag(rows: 4, perRow: 5, top: 0.86, bottom: 0.48),
        // 9 — orbitals
        ring(cx: 0.32, cy: 0.58, rx: 0.15, ry: 0.10, count: 6) + ring(cx: 0.68, cy: 0.76, rx: 0.15, ry: 0.10, count: 6)
            + [PegSpec(0.5, 0.44)],
        // 10 — the wall
        zigzag(rows: 3, perRow: 6, top: 0.78, bottom: 0.56) + row(y: 0.90, count: 3, inset: 0.30),
        // 11 — cathedral
        arc(centerY: 0.48, amplitude: 0.30, count: 9) + diamond(cx: 0.5, cy: 0.60, rx: 0.14, ry: 0.10),
        // 12 — the gauntlet
        zigzag(rows: 4, perRow: 6, top: 0.88, bottom: 0.50),
    ]
}
