import GameKit
import UIKit

/// Game Center: silent authentication, score + achievement reporting.
/// Everything degrades gracefully when the player declines Game Center.
@MainActor
final class GameCenterManager {
    static let shared = GameCenterManager()
    private(set) var isAuthenticated = false

    static let leaderboardID = "brinkball.best"

    enum Achievement: String, CaseIterable {
        case firstBrink = "brinkball.ach.firstbrink"
        case wave5 = "brinkball.ach.wave5"
        case wave10 = "brinkball.ach.wave10"
        case pegs100 = "brinkball.ach.pegs100"
        case fever = "brinkball.ach.fever"
        case score25k = "brinkball.ach.score25k"
    }

    private var reported = Set<String>()

    private init() {}

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let viewController {
                    Self.topViewController()?.present(viewController, animated: true)
                    return
                }
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if let error { NSLog("GameCenter auth: \(error.localizedDescription)") }
            }
        }
    }

    func submit(score: Int) {
        guard isAuthenticated, score > 0 else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [Self.leaderboardID]) { error in
            if let error { NSLog("GameCenter submit: \(error.localizedDescription)") }
        }
    }

    func report(_ achievement: Achievement) {
        guard isAuthenticated, !reported.contains(achievement.rawValue) else { return }
        reported.insert(achievement.rawValue)
        let a = GKAchievement(identifier: achievement.rawValue)
        a.percentComplete = 100
        a.showsCompletionBanner = true
        GKAchievement.report([a]) { error in
            if let error { NSLog("GameCenter achievement: \(error.localizedDescription)") }
        }
    }

    /// Evaluate a finished run against every achievement.
    func evaluate(stats: RunStats) {
        if stats.brinkFlips >= 1 { report(.firstBrink) }
        if stats.waves >= 5 { report(.wave5) }
        if stats.waves >= 10 { report(.wave10) }
        if stats.pegs >= 100 { report(.pegs100) }
        if stats.fevers >= 1 { report(.fever) }
        if stats.score >= 25_000 { report(.score25k) }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
