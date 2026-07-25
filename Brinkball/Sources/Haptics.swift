import UIKit

/// Impact tiers for game feel. Cheap, pre-warmed generators.
@MainActor
final class Haptics {
    static let shared = Haptics()
    var enabled = true

    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notify = UINotificationFeedbackGenerator()

    private init() {
        soft.prepare()
        light.prepare()
        medium.prepare()
        heavy.prepare()
    }

    func peg() { fire(light) }
    func flip() { fire(medium) }
    func brink() { fire(heavy) }
    /// A whiffed tap: felt, but soft — feedback, not punishment.
    func whiff() { fire(soft) }
    /// Fever ignition: heavy double-tap pattern.
    func feverIgnite() {
        guard enabled else { return }
        heavy.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [heavy] in
            heavy.impactOccurred()
            heavy.prepare()
        }
    }
    func newBest() {
        guard enabled else { return }
        notify.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [heavy] in
            heavy.impactOccurred()
            heavy.prepare()
        }
    }
    func drain() {
        guard enabled else { return }
        notify.notificationOccurred(.warning)
    }
    func gameOver() {
        guard enabled else { return }
        notify.notificationOccurred(.error)
    }
    func waveClear() {
        guard enabled else { return }
        notify.notificationOccurred(.success)
    }

    private func fire(_ generator: UIImpactFeedbackGenerator) {
        guard enabled else { return }
        generator.impactOccurred()
        generator.prepare()
    }
}
