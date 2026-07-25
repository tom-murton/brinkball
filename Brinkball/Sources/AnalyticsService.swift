import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics

/// Thin wrapper over Firebase Analytics implementing the benchmark's shared
/// metrics contract (rig/METRICS-SPEC.md): fixed user properties + standard events.
enum AnalyticsService {
    static func configure() {
        FirebaseApp.configure()
        Analytics.setUserProperty("claude-fable-5-ultra", forName: "built_by_model")
        Analytics.setUserProperty("brinkball", forName: "game")
        Analytics.setUserProperty("native", forName: "engine")
        Analytics.setUserProperty("1.1", forName: "benchmark_version")
    }

    static func gameStart() {
        Analytics.logEvent("game_start", parameters: ["mode": "endless"])
    }

    static func gameOver(score: Int, duration: TimeInterval) {
        Analytics.logEvent("game_over", parameters: [
            "score": score,
            "duration_seconds": Int(duration),
            "result": "end",
        ])
    }

    static func replay() {
        Analytics.logEvent("replay", parameters: nil)
    }

    static func levelReached(wave: Int) {
        Analytics.logEvent("level_reached", parameters: ["level": wave])
    }

    static func settingsOpened() {
        Analytics.logEvent("settings_opened", parameters: nil)
    }

    static func share() {
        Analytics.logEvent("share", parameters: nil)
    }

    static func tutorialComplete() {
        Analytics.logEvent("tutorial_complete", parameters: nil)
    }
}
