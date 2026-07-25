import Foundation
import CoreGraphics

/// Which flip band the ball occupies, from its height fraction above the scene bottom.
enum FlipBand: Equatable {
    case none      // above the strip — tap does nothing
    case x1
    case x2
    case brink
    case drained   // below the drain line

    var multiplier: Int {
        switch self {
        case .x1: 1
        case .x2: 2
        case .brink: 4
        case .none, .drained: 0
        }
    }

    var flipSpeed: CGFloat {
        switch self {
        case .x1: GameConfig.flipSpeedX1
        case .x2: GameConfig.flipSpeedX2
        case .brink: GameConfig.flipSpeedBrink
        case .none, .drained: 0
        }
    }
}

/// Pure scoring/run state machine — no SpriteKit, fully unit-testable.
struct ScoreEngine {
    private(set) var score = 0
    private(set) var wave = 1
    private(set) var ballsLeft = GameConfig.ballsPerRun
    private(set) var multiplier = 1
    private(set) var combo = 0            // consecutive peg hits this flight
    private(set) var feverActive = false
    private(set) var brinkMeter = 0       // brink flips banked toward fever
    // Run stats
    private(set) var pegsPopped = 0
    private(set) var bestCombo = 0
    private(set) var brinkFlips = 0
    private(set) var feversIgnited = 0

    static func band(atHeightFraction f: CGFloat) -> FlipBand {
        if f < GameConfig.drainY { return .drained }
        if f < GameConfig.brinkTop { return .brink }
        if f < GameConfig.x2Top { return .x2 }
        if f < GameConfig.stripTop { return .x1 }
        return .none
    }

    /// Player flipped from `band`. `bankBrink` is false when this strip visit
    /// already banked a fever tick (anti multi-tap farming).
    /// Returns true if this flip ignited fever.
    @discardableResult
    mutating func flip(from band: FlipBand, bankBrink: Bool = true) -> Bool {
        guard band.multiplier > 0 else { return false }
        multiplier = band.multiplier
        combo = 0
        guard band == .brink else { return false }
        brinkFlips += 1
        guard !feverActive, bankBrink else { return false }
        brinkMeter += 1
        if brinkMeter >= GameConfig.brinkFlipsToFever {
            brinkMeter = 0
            feverActive = true
            feversIgnited += 1
            return true
        }
        return false
    }

    /// A peg was destroyed. Returns the points awarded.
    @discardableResult
    mutating func pegHit() -> Int {
        combo += 1
        bestCombo = max(bestCombo, combo)
        pegsPopped += 1
        let points = GameConfig.pegBaseScore * multiplier * (feverActive ? GameConfig.feverScoreFactor : 1)
        score += points
        return points
    }

    /// Current wave cleared. Returns the bonus awarded; advances to the next wave.
    @discardableResult
    mutating func waveCleared() -> Int {
        let bonus = GameConfig.waveBonus(wave: wave) * (feverActive ? GameConfig.feverScoreFactor : 1)
        score += bonus
        wave += 1
        return bonus
    }

    mutating func feverEnded() { feverActive = false }

    /// Ball drained. Returns true if the run is over.
    mutating func ballDrained() -> Bool {
        ballsLeft -= 1
        multiplier = 1
        combo = 0
        return ballsLeft <= 0
    }

    /// Gravity for the current wave (ramp capped).
    var gravity: CGFloat {
        GameConfig.baseGravity + GameConfig.gravityPerWave * CGFloat(min(wave, GameConfig.rampCapWave) - 1)
    }
}

/// Immutable summary of a finished run.
struct RunStats {
    let score: Int
    let waves: Int
    let pegs: Int
    let bestCombo: Int
    let brinkFlips: Int
    let fevers: Int
    let duration: TimeInterval

    init(engine: ScoreEngine, duration: TimeInterval) {
        score = engine.score
        waves = engine.wave
        pegs = engine.pegsPopped
        bestCombo = engine.bestCombo
        brinkFlips = engine.brinkFlips
        fevers = engine.feversIgnited
        self.duration = duration
    }
}
