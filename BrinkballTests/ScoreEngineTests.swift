import Testing
import Foundation
@testable import Brinkball

@Suite("Flip bands")
struct BandTests {
    @Test func bandBoundaries() {
        #expect(ScoreEngine.band(atHeightFraction: 0.50) == .none)
        #expect(ScoreEngine.band(atHeightFraction: 0.31) == .none)
        #expect(ScoreEngine.band(atHeightFraction: 0.29) == .x1)
        #expect(ScoreEngine.band(atHeightFraction: 0.18) == .x1)
        #expect(ScoreEngine.band(atHeightFraction: 0.17) == .x2)
        #expect(ScoreEngine.band(atHeightFraction: 0.10) == .x2)
        #expect(ScoreEngine.band(atHeightFraction: 0.09) == .brink)
        #expect(ScoreEngine.band(atHeightFraction: 0.02) == .brink)
        #expect(ScoreEngine.band(atHeightFraction: 0.01) == .drained)
        // Boundaries derive from config so the strip can be retuned in one place.
        #expect(ScoreEngine.band(atHeightFraction: GameConfig.brinkTop - 0.001) == .brink)
        #expect(ScoreEngine.band(atHeightFraction: GameConfig.x2Top - 0.001) == .x2)
    }

    @Test func bandProperties() {
        #expect(FlipBand.x1.multiplier == 1)
        #expect(FlipBand.x2.multiplier == 2)
        #expect(FlipBand.brink.multiplier == 4)
        #expect(FlipBand.none.multiplier == 0)
        #expect(FlipBand.brink.flipSpeed > FlipBand.x2.flipSpeed)
        #expect(FlipBand.x2.flipSpeed > FlipBand.x1.flipSpeed)
    }
}

@Suite("Score engine")
struct ScoreEngineTests {
    @Test func flipSetsMultiplierAndScoring() {
        var engine = ScoreEngine()
        engine.flip(from: .x2)
        #expect(engine.multiplier == 2)
        let points = engine.pegHit()
        #expect(points == GameConfig.pegBaseScore * 2)
        #expect(engine.score == points)
    }

    @Test func brinkFlipsIgniteFeverAtThreshold() {
        var engine = ScoreEngine()
        #expect(engine.flip(from: .brink) == false)
        #expect(engine.flip(from: .brink) == false)
        #expect(engine.flip(from: .brink) == true)
        #expect(engine.feverActive)
        #expect(engine.brinkFlips == 3)
        // Fever doubles peg points on top of the band multiplier.
        let points = engine.pegHit()
        #expect(points == GameConfig.pegBaseScore * 4 * GameConfig.feverScoreFactor)
        // Brink flips during fever don't re-bank the meter.
        #expect(engine.flip(from: .brink) == false)
        engine.feverEnded()
        #expect(!engine.feverActive)
    }

    @Test func unbankedBrinkFlipsDontFarmFever() {
        var engine = ScoreEngine()
        #expect(engine.flip(from: .brink, bankBrink: true) == false)
        // Multi-taps in the same strip visit: full ×4 multiplier, no meter tick.
        #expect(engine.flip(from: .brink, bankBrink: false) == false)
        #expect(engine.flip(from: .brink, bankBrink: false) == false)
        #expect(engine.multiplier == 4)
        #expect(!engine.feverActive)
        #expect(engine.flip(from: .brink, bankBrink: true) == false)
        #expect(engine.flip(from: .brink, bankBrink: true) == true)   // 3rd banked tick ignites
    }

    @Test func comboTracksConsecutiveHitsPerFlight() {
        var engine = ScoreEngine()
        engine.flip(from: .x1)
        engine.pegHit()
        engine.pegHit()
        engine.pegHit()
        #expect(engine.combo == 3)
        #expect(engine.bestCombo == 3)
        engine.flip(from: .x1)
        #expect(engine.combo == 0)
        #expect(engine.bestCombo == 3)
    }

    @Test func waveClearAdvancesAndPays() {
        var engine = ScoreEngine()
        let bonus = engine.waveCleared()
        #expect(bonus == GameConfig.waveBonus(wave: 1))
        #expect(engine.wave == 2)
        #expect(engine.score == bonus)
    }

    @Test func drainingThreeBallsEndsRun() {
        var engine = ScoreEngine()
        engine.flip(from: .brink)
        #expect(engine.ballDrained() == false)
        #expect(engine.multiplier == 1)   // multiplier resets on drain
        #expect(engine.ballDrained() == false)
        #expect(engine.ballDrained() == true)
        #expect(engine.ballsLeft == 0)
    }

    @Test func stripFallCapTightensAndCeilings() {
        #expect(GameConfig.stripFallCap(wave: 1) == GameConfig.stripFallSpeedCap)
        #expect(GameConfig.stripFallCap(wave: 8) > GameConfig.stripFallCap(wave: 2))
        #expect(GameConfig.stripFallCap(wave: 500) == GameConfig.stripFallSpeedCeiling)
    }

    @Test func gravityRampsAndCaps() {
        var engine = ScoreEngine()
        let g1 = engine.gravity
        for _ in 1..<GameConfig.rampCapWave { engine.waveCleared() }
        let gCap = engine.gravity
        #expect(gCap < g1)   // more negative = faster
        for _ in 0..<5 { engine.waveCleared() }
        #expect(engine.gravity == gCap)   // capped
    }

    @Test func runStatsSnapshotsEngine() {
        var engine = ScoreEngine()
        engine.flip(from: .brink)
        engine.pegHit()
        engine.waveCleared()
        let stats = RunStats(engine: engine, duration: 42)
        #expect(stats.score == engine.score)
        #expect(stats.waves == 2)
        #expect(stats.pegs == 1)
        #expect(stats.brinkFlips == 1)
        #expect(stats.duration == 42)
    }
}
