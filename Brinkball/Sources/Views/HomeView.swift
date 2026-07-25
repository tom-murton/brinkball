import SwiftUI
import GameKit

struct HomeView: View {
    @Binding var route: RootView.Route
    @State private var store = PlayerStore.shared
    @State private var showGameCenterUnavailable = false
    @State private var titleGlow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 60)

                    VStack(spacing: 4) {
                        Text("BRINKBALL")
                            .font(.bungee(44))
                            .foregroundStyle(
                                LinearGradient(colors: [.emberOrange, .brinkRed],
                                               startPoint: .top, endPoint: .bottom)
                            )
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .shadow(color: .emberOrange.opacity(titleGlow ? 0.55 : 0.2), radius: titleGlow ? 22 : 10)
                        Text("Flirt with the drain. Feast on the score.")
                            .font(.poppins(15))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityElement(children: .combine)

                    // Fixed-height slot so the menu never jumps when a best
                    // score appears after the first run.
                    VStack(spacing: 2) {
                        if store.bestScore > 0 {
                            Text("BEST")
                                .font(.poppinsBold(12))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("\(store.bestScore)")
                                .font(.bungee(34))
                                .foregroundStyle(Color.glassTeal)
                            Text("Wave \(store.bestWave) · \(store.totalRuns) runs · \(store.totalPegs) orbs")
                                .font(.poppins(12))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .frame(minHeight: 84)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(store.bestScore > 0
                        ? "Best score \(store.bestScore). Highest wave \(store.bestWave). \(store.totalRuns) runs played."
                        : "")

                    VStack(spacing: 14) {
                        MenuButton(title: "PLAY", prominent: true) { route = .game }
                        MenuButton(title: "HOW TO PLAY") { route = .howTo }
                        MenuButton(title: "SETTINGS") { route = .settings }
                        MenuButton(title: "GAME CENTER") { presentGameCenter() }
                    }
                    .padding(.horizontal, 44)

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.inkBackground)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                titleGlow = true
            }
        }
        .alert("Game Center unavailable", isPresented: $showGameCenterUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Sign in to Game Center in the Settings app to see leaderboards and achievements.")
        }
    }

    /// The game's own nebula plus a few drifting embers — character without
    /// simulating a second live scene behind a menu.
    private var background: some View {
        ZStack {
            Image("bg-nebula")
                .resizable()
                .scaledToFill()
                .opacity(0.55)
                .ignoresSafeArea()
            if !reduceMotion {
                EmberField()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .accessibilityHidden(true)
    }

    private func presentGameCenter() {
        guard GameCenterManager.shared.isAuthenticated else {
            showGameCenterUnavailable = true
            return
        }
        guard !(topViewController() is GKGameCenterViewController) else { return }
        let vc = GKGameCenterViewController(state: .leaderboards)
        vc.gameCenterDelegate = GameCenterDismisser.shared
        topViewController()?.present(vc, animated: true)
    }

    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

/// A handful of soft embers drifting slowly upward. TimelineView-driven,
/// deterministic per-ember phase offsets — cheap and calm.
struct EmberField: View {
    private struct Ember {
        let x: CGFloat        // 0…1 across width
        let size: CGFloat
        let speed: Double     // full climbs per minute
        let phase: Double
        let alpha: Double
    }

    private let embers: [Ember] = [
        .init(x: 0.12, size: 5, speed: 1.6, phase: 0.10, alpha: 0.35),
        .init(x: 0.30, size: 3, speed: 2.3, phase: 0.55, alpha: 0.25),
        .init(x: 0.52, size: 6, speed: 1.2, phase: 0.30, alpha: 0.30),
        .init(x: 0.68, size: 4, speed: 2.0, phase: 0.80, alpha: 0.22),
        .init(x: 0.84, size: 5, speed: 1.4, phase: 0.05, alpha: 0.33),
        .init(x: 0.44, size: 3, speed: 2.6, phase: 0.42, alpha: 0.20),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for ember in embers {
                    let cycle = 60.0 / ember.speed
                    let progress = ((t / cycle) + ember.phase).truncatingRemainder(dividingBy: 1)
                    let y = size.height * (1.05 - 1.1 * progress)
                    let wobble = sin(t * 0.8 + ember.phase * 10) * 12
                    let rect = CGRect(x: size.width * ember.x + wobble - ember.size / 2,
                                      y: y, width: ember.size, height: ember.size)
                    context.fill(Ellipse().path(in: rect),
                                 with: .color(Color.emberOrange.opacity(ember.alpha)))
                }
            }
        }
    }
}

final class GameCenterDismisser: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismisser()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

struct MenuButton: View {
    let title: String
    var prominent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bungee(prominent ? 24 : 17))
                .frame(maxWidth: .infinity)
                .padding(.vertical, prominent ? 18 : 13)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(prominent
                              ? AnyShapeStyle(LinearGradient(colors: [.emberOrange, .brinkRed],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                              : AnyShapeStyle(Color.white.opacity(0.08)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(prominent ? 0.25 : 0.12), lineWidth: 1)
                )
                .foregroundStyle(prominent ? .black : .white)
        }
        .buttonStyle(.plain)
    }
}
