import Testing
import Foundation
import CoreGraphics
@testable import Brinkball

@Suite("Wave library")
struct WaveLibraryTests {
    /// Reference iPhone layout for spacing checks.
    private let refWidth: CGFloat = 390
    private let refHeight: CGFloat = 844

    @Test func everyWaveIsPlayable() {
        for wave in 1...24 {
            let pegs = WaveLibrary.pegs(forWave: wave)
            #expect(pegs.count >= 4, "wave \(wave) too sparse")
            #expect(pegs.count <= 40, "wave \(wave) too dense")
        }
    }

    @Test func pegsStayInsideThePlayfield() {
        for wave in 1...24 {
            for peg in WaveLibrary.pegs(forWave: wave) {
                #expect(peg.x >= 0.08 && peg.x <= 0.92, "wave \(wave) x=\(peg.x) out of bounds")
                #expect(peg.y >= 0.40 && peg.y <= 0.93, "wave \(wave) y=\(peg.y) above strip and below ceiling")
            }
        }
    }

    @Test func pegsNeverOverlap() {
        for wave in 1...16 {
            let pegs = WaveLibrary.pegs(forWave: wave)
            for i in 0..<pegs.count {
                for j in (i + 1)..<pegs.count {
                    let dx = (pegs[i].x - pegs[j].x) * refWidth
                    let dy = (pegs[i].y - pegs[j].y) * refHeight
                    let dist = (dx * dx + dy * dy).squareRoot()
                    #expect(dist >= GameConfig.pegRadius * 2 + 2,
                            "wave \(wave): pegs \(i) and \(j) only \(dist)pt apart")
                }
            }
        }
    }

    @Test func armoredPegsOnlyFromConfiguredWave() {
        for wave in 1..<GameConfig.armoredFromWave {
            #expect(WaveLibrary.pegs(forWave: wave).allSatisfy { !$0.armored })
        }
        let later = WaveLibrary.pegs(forWave: GameConfig.armoredFromWave + 1)
        #expect(later.contains { $0.armored })
    }

    @Test func wavesBeyondLibraryCycle() {
        let count = WaveLibrary.patterns.count
        let a = WaveLibrary.pegs(forWave: count + 1)
        let b = WaveLibrary.pegs(forWave: count + 5)
        #expect(a == b)   // same pattern & same armored promotion
    }
}
