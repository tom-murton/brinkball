import Foundation
import Observation

/// UI-facing game state, mirrored from the scene, plus run lifecycle side effects
/// (persistence, Game Center, analytics). SwiftUI observes this.
@Observable
@MainActor
final class GameSession {
    enum Phase { case playing, gameOver }

    var phase: Phase = .playing
    var score = 0
    var ballsLeft = GameConfig.ballsPerRun
    var wave = 1
    var multiplier = 1
    var feverActive = false
    /// Toward fever: 0…1 fill. During fever: 1 → 0 countdown.
    var feverProgress: Double = 0
    /// Banked brink flips (0…3) for the HUD pips.
    var brinkPips = 0
    var lastRun: RunStats?
    var isNewBest = false

    private let store = PlayerStore.shared

    func runStarted(isReplay: Bool) {
        phase = .playing
        isNewBest = false
        lastRun = nil
        if isReplay {
            AnalyticsService.replay()
        }
        AnalyticsService.gameStart()
    }

    func waveReached(_ wave: Int) {
        guard wave > 1 else { return }
        AnalyticsService.levelReached(wave: wave)
    }

    func runEnded(_ stats: RunStats) {
        lastRun = stats
        isNewBest = store.recordRun(stats)
        phase = .gameOver
        AnalyticsService.gameOver(score: stats.score, duration: stats.duration)
        GameCenterManager.shared.submit(score: stats.score)
        GameCenterManager.shared.evaluate(stats: stats)
    }
}

/// UserDefaults-backed persistence for best score, lifetime stats, and settings.
@Observable
@MainActor
final class PlayerStore {
    static let shared = PlayerStore()

    private let defaults = UserDefaults.standard

    var bestScore: Int
    var totalRuns: Int
    var totalPegs: Int
    var bestWave: Int
    private(set) var tutorialSeen: Bool
    private(set) var reviewAsked: Bool

    var soundOn: Bool { didSet { defaults.set(soundOn, forKey: "soundOn"); AudioPlayer.shared.soundOn = soundOn } }
    var musicOn: Bool { didSet { defaults.set(musicOn, forKey: "musicOn"); AudioPlayer.shared.musicOn = musicOn } }
    var hapticsOn: Bool { didSet { defaults.set(hapticsOn, forKey: "hapticsOn"); Haptics.shared.enabled = hapticsOn } }

    private init() {
        bestScore = defaults.integer(forKey: "bestScore")
        totalRuns = defaults.integer(forKey: "totalRuns")
        totalPegs = defaults.integer(forKey: "totalPegs")
        bestWave = defaults.integer(forKey: "bestWave")
        tutorialSeen = defaults.bool(forKey: "tutorialSeen")
        reviewAsked = defaults.bool(forKey: "reviewAsked")
        soundOn = defaults.object(forKey: "soundOn") as? Bool ?? true
        musicOn = defaults.object(forKey: "musicOn") as? Bool ?? true
        hapticsOn = defaults.object(forKey: "hapticsOn") as? Bool ?? true
        AudioPlayer.shared.soundOn = soundOn
        AudioPlayer.shared.musicOn = musicOn
        Haptics.shared.enabled = hapticsOn
    }

    func completeTutorial() {
        guard !tutorialSeen else { return }
        tutorialSeen = true
        defaults.set(true, forKey: "tutorialSeen")
        AnalyticsService.tutorialComplete()
    }

    /// One rating ask, ever, and only at a positive moment (new best, seasoned player).
    func shouldRequestReview(newBest: Bool) -> Bool {
        guard newBest, totalRuns >= 8, !reviewAsked else { return false }
        reviewAsked = true
        defaults.set(true, forKey: "reviewAsked")
        return true
    }

    /// Records a finished run. Returns true when it set a new best score.
    func recordRun(_ stats: RunStats) -> Bool {
        totalRuns += 1
        totalPegs += stats.pegs
        bestWave = max(bestWave, stats.waves)
        defaults.set(totalRuns, forKey: "totalRuns")
        defaults.set(totalPegs, forKey: "totalPegs")
        defaults.set(bestWave, forKey: "bestWave")
        guard stats.score > bestScore else { return false }
        bestScore = stats.score
        defaults.set(bestScore, forKey: "bestScore")
        return true
    }
}
