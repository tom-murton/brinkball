import Foundation
import CoreGraphics

/// Every gameplay tuning constant lives here so feel-tuning touches one file.
enum GameConfig {
    // MARK: Strip layout (fractions of scene height, measured from the bottom)
    /// Top of the ×1 band — the flip strip spans from here down to `drainY`.
    static let stripTop: CGFloat = 0.30
    /// Top of the ×2 band.
    static let x2Top: CGFloat = 0.175
    /// Top of the ×4 BRINK band. R2: deepened 0.085 → 0.095 (~+14% flip window,
    /// the ±10% human-hands adjustment R1 flagged as untestable by autopilot).
    static let brinkTop: CGFloat = 0.095
    /// Below this the ball is gone.
    static let drainY: CGFloat = 0.012
    /// Falling speed cap while inside the strip (pt/s at reference height) —
    /// the air "thickens" near the drain so the greed window is humanly playable.
    static let stripFallSpeedCap: CGFloat = 620
    /// The cap loosens per wave so the flip window tightens and runs must end.
    static let stripFallCapGrowth: CGFloat = 1.045
    static let stripFallSpeedCeiling: CGFloat = 2000

    /// Strip fall cap for a wave: starts friendly, grows until it out-runs
    /// human timing — this is the game's difficulty ceiling.
    static func stripFallCap(wave: Int) -> CGFloat {
        min(stripFallSpeedCap * pow(stripFallCapGrowth, CGFloat(wave - 1)), stripFallSpeedCeiling)
    }

    // MARK: Flip
    /// Launch speed (points/s) per band, scaled to scene height / 844.
    static let flipSpeedX1: CGFloat = 1150
    static let flipSpeedX2: CGFloat = 1370
    static let flipSpeedBrink: CGFloat = 1600
    /// Max launch angle away from straight up, in radians (~57°).
    static let maxLaunchAngle: CGFloat = 1.0
    /// Serve speed for a fresh ball.
    static let serveSpeed: CGFloat = 950

    // MARK: Physics
    /// Base gravity dy; ramps slightly per wave.
    static let baseGravity: CGFloat = -5.4
    static let gravityPerWave: CGFloat = -0.12
    /// Waves past this stop ramping and cycle the last patterns.
    static let rampCapWave = 12
    static let ballRadius: CGFloat = 13
    static let pegRadius: CGFloat = 13
    static let ballRestitution: CGFloat = 0.62

    // MARK: Scoring
    static let pegBaseScore = 10
    static func waveBonus(wave: Int) -> Int { 250 + 50 * wave }
    static let brinkSlowmoDuration: TimeInterval = 0.35
    static let brinkSlowmoSpeed: CGFloat = 0.22

    // MARK: Fever
    static let brinkFlipsToFever = 3
    static let feverDuration: TimeInterval = 10
    static let feverScoreFactor = 2

    // MARK: Run
    static let ballsPerRun = 3
    static let armoredPegHits = 2
    /// Waves at or above this may include armored pegs.
    static let armoredFromWave = 4

    // MARK: Audio
    /// Combo ding pitch: 1.0 + step per consecutive hit, capped.
    static let comboPitchStep: Float = 0.07
    static let comboPitchCap: Float = 1.9

    // MARK: Tutorial (first-ever run only; grace fires on failure signals, never on skill)
    /// Successful flips before the tutorial retires.
    static let tutorialFlipsToComplete = 2
    /// Time scale while the "TAP!" beat holds the ball inside the strip.
    static let tutorialSlowmo: CGFloat = 0.22

    // MARK: Hit-stop (reserved for the biggest confirms only)
    static let hitStopBrink: TimeInterval = 0.05
    static let hitStopFever: TimeInterval = 0.08
    static let hitStopFinalDrain: TimeInterval = 0.12

    /// Launch stretch along the flip vector, tiered by band so force is legible.
    static func flipStretch(for band: FlipBand) -> CGFloat {
        switch band {
        case .x1: 1.15
        case .x2: 1.25
        case .brink: 1.4
        case .none, .drained: 1
        }
    }
}
