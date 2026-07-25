import SwiftUI
import SpriteKit
import StoreKit

struct GameView: View {
    @Binding var route: RootView.Route
    @State private var session = GameSession()
    @State private var scene: GameScene?
    @State private var paused = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let scene {
                    SpriteView(scene: scene, preferredFramesPerSecond: 120)
                        .ignoresSafeArea()
                        .accessibilityLabel("Brinkball playfield. Direct touch area: with VoiceOver, double-tap to start interacting, then tap the screen to flip the ball whenever it is in the coloured strip near the bottom. The lower the ball, the stronger the launch and the higher the multiplier.")
                        .accessibilityDirectTouch(options: .requiresActivation)
                }

                hud

                if paused { pauseOverlay }
                if session.phase == .gameOver { gameOverOverlay }
            }
            .onAppear {
                if scene == nil {
                    let s = GameScene(size: geo.size)
                    s.session = session
                    scene = s
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, session.phase == .playing {
                setPaused(true)
            } else if phase == .active, paused {
                // SpriteKit auto-unpauses scenes on activation; re-assert.
                scene?.setUserPaused(true)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        // The flip strip lives in the home-indicator zone; don't let a frantic
        // late flip become an app-switcher swipe.
        .defersSystemGestures(on: .bottom)
        .animation(.spring(duration: 0.35), value: session.phase == .gameOver)
    }

    // MARK: HUD

    private var hud: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(session.score)")
                        .font(.bungee(30))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.25), value: session.score)
                    if PlayerStore.shared.bestScore > 0 {
                        Text("BEST \(PlayerStore.shared.bestScore)")
                            .font(.poppinsBold(11))
                            .foregroundStyle(Color.glassTeal.opacity(0.85))
                    }
                    HStack(spacing: 8) {
                        MultiplierChip(multiplier: session.multiplier)
                        Text("WAVE \(session.wave)")
                            .font(.poppinsBold(12))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Score \(session.score), multiplier times \(session.multiplier), wave \(session.wave)")

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 5) {
                        ForEach(0..<GameConfig.ballsPerRun, id: \.self) { i in
                            Circle()
                                .fill(i < session.ballsLeft ? Color.emberOrange : Color.white.opacity(0.15))
                                .frame(width: 10, height: 10)
                                .scaleEffect(i < session.ballsLeft ? 1 : 0.7)
                                .animation(.spring(duration: 0.4), value: session.ballsLeft)
                        }
                    }
                    .accessibilityLabel("\(session.ballsLeft) balls left")

                    feverIndicator

                    Button {
                        setPaused(true)
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.white.opacity(0.1)))
                    }
                    .accessibilityLabel("Pause")
                }
            }
            .padding(.horizontal, 18)
            Spacer()
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // HUD is a fixed layout; cap growth
        .allowsHitTesting(session.phase == .playing)
    }

    /// Toward fever: three pips that bank per BRINK flip. During fever: a
    /// draining 10-second bar. The economy is glanceable from the first serve.
    @ViewBuilder
    private var feverIndicator: some View {
        if session.feverActive {
            VStack(alignment: .trailing, spacing: 2) {
                Text("FEVER ×2")
                    .font(.bungee(14))
                    .foregroundStyle(Color.feverPink)
                ProgressView(value: session.feverProgress)
                    .tint(Color.feverPink)
                    .frame(width: 64)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Fever active, double score")
        } else {
            HStack(spacing: 5) {
                ForEach(0..<GameConfig.brinkFlipsToFever, id: \.self) { i in
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(i < session.brinkPips ? Color.feverPink : Color.white.opacity(0.18))
                        .scaleEffect(i < session.brinkPips ? 1 : 0.85)
                        .animation(.spring(duration: 0.35), value: session.brinkPips)
                }
            }
            .accessibilityLabel("Fever meter: \(session.brinkPips) of \(GameConfig.brinkFlipsToFever) brink flips")
        }
    }

    // MARK: Overlays

    private var pauseOverlay: some View {
        overlayCard {
            Text("PAUSED")
                .font(.bungee(32))
                .foregroundStyle(.white)
            quickToggles
            VStack(spacing: 12) {
                MenuButton(title: "RESUME", prominent: true) { setPaused(false) }
                MenuButton(title: "RESTART") {
                    setPaused(false)
                    scene?.startRun(isReplay: true)
                }
                MenuButton(title: "HOME") {
                    setPaused(false)
                    route = .home
                }
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    /// Sound / music / haptics without leaving the run.
    private var quickToggles: some View {
        HStack(spacing: 14) {
            quickToggle(icon: "speaker.wave.2.fill", offIcon: "speaker.slash.fill",
                        label: "Sound effects", isOn: Binding(
                            get: { PlayerStore.shared.soundOn },
                            set: { PlayerStore.shared.soundOn = $0 }))
            quickToggle(icon: "music.note", offIcon: "music.note.list",
                        label: "Music", isOn: Binding(
                            get: { PlayerStore.shared.musicOn },
                            set: { PlayerStore.shared.musicOn = $0 }))
            quickToggle(icon: "iphone.gen3.radiowaves.left.and.right", offIcon: "iphone.gen3.slash",
                        label: "Haptics", isOn: Binding(
                            get: { PlayerStore.shared.hapticsOn },
                            set: { PlayerStore.shared.hapticsOn = $0 }))
        }
    }

    private func quickToggle(icon: String, offIcon: String, label: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Image(systemName: isOn.wrappedValue ? icon : offIcon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isOn.wrappedValue ? Color.emberOrange : .white.opacity(0.35))
                .frame(width: 52, height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.07)))
        }
        .accessibilityLabel(label)
        .accessibilityValue(isOn.wrappedValue ? "on" : "off")
    }

    private var gameOverOverlay: some View {
        GameOverCard(session: session,
                     replay: { scene?.startRun(isReplay: true) },
                     home: { route = .home },
                     requestReviewIfEarned: {
                         if PlayerStore.shared.shouldRequestReview(newBest: session.isNewBest) {
                             requestReview()
                         }
                     })
        .accessibilityAddTraits(.isModal)
    }

    private func overlayCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18, content: content)
                    .padding(28)
                    .frame(maxWidth: 360)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.inkBackground.opacity(0.95))
                            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.15)))
                    )
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
            }
        }
        .transition(.opacity)
    }

    private func setPaused(_ value: Bool) {
        paused = value
        scene?.setUserPaused(value)
    }
}

/// The always-on economy chip: ×1 blue / ×2 amber / ×4 red — the HUD is the
/// strip legend, and it punches on every change.
struct MultiplierChip: View {
    let multiplier: Int
    @State private var punch = false

    private var color: Color {
        switch multiplier {
        case 4: .brinkRed
        case 2: .emberOrange
        default: Color(red: 0.35, green: 0.62, blue: 1)
        }
    }

    var body: some View {
        Text("×\(multiplier)")
            .font(.bungee(15))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.16)))
            .overlay(Capsule().strokeBorder(color.opacity(0.5), lineWidth: 1))
            .scaleEffect(punch ? 1.35 : 1)
            .onChange(of: multiplier) { _, _ in
                withAnimation(.spring(duration: 0.18)) { punch = true }
                withAnimation(.spring(duration: 0.3).delay(0.12)) { punch = false }
            }
            .accessibilityHidden(true)   // combined into the score element's label
    }
}

/// Game-over card: slides up, counts the score in, answers "how close was I?",
/// staggers the stats, and keeps REPLAY under the thumb.
struct GameOverCard: View {
    let session: GameSession
    let replay: () -> Void
    let home: () -> Void
    let requestReviewIfEarned: () -> Void

    @State private var displayScore = 0
    @State private var rowsShown = false
    @State private var pulseReplay = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var finalScore: Int { session.lastRun?.score ?? 0 }
    private var best: Int { PlayerStore.shared.bestScore }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text(session.isNewBest ? "NEW BEST!" : "RUN OVER")
                        .font(.bungee(30))
                        .foregroundStyle(session.isNewBest ? Color.glassTeal : Color.white)

                    Text("\(displayScore)")
                        .font(.bungee(52))
                        .foregroundStyle(
                            LinearGradient(colors: [.emberOrange, .brinkRed], startPoint: .top, endPoint: .bottom)
                        )
                        .contentTransition(.numericText())
                        .accessibilityLabel("Final score \(finalScore)")

                    closenessLine

                    if let run = session.lastRun {
                        VStack(spacing: 3) {
                            statLine("Waves", "\(run.waves)", index: 0)
                            statLine("Orbs popped", "\(run.pegs)", index: 1)
                            statLine("Best combo", "\(run.bestCombo)", index: 2)
                            statLine("Brink flips", "\(run.brinkFlips)", index: 3)
                            statLine("Best score", "\(best)", index: 4)
                        }
                        .padding(.vertical, 4)
                    }

                    VStack(spacing: 12) {
                        MenuButton(title: "REPLAY", prominent: true) { replay() }
                            .scaleEffect(pulseReplay ? 1.04 : 1)
                        MenuButton(title: "SHARE") { share() }
                        MenuButton(title: "HOME") { home() }
                    }
                }
                .padding(28)
                .frame(maxWidth: 360)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.inkBackground.opacity(0.95))
                        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.15)))
                )
                .padding(24)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            }
        }
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        .onAppear { animateIn() }
    }

    /// Always answer "how close was I?" — the near-miss is the replay engine.
    @ViewBuilder
    private var closenessLine: some View {
        if session.isNewBest {
            Text("You beat your best. Again?")
                .font(.poppins(14))
                .foregroundStyle(.white.opacity(0.75))
        } else if best > 0, finalScore > 0 {
            let pct = Int(Double(finalScore) / Double(best) * 100)
            Text(pct >= 90 ? "SO CLOSE — \(best - finalScore) from your best"
                           : "\(pct)% of your best (\(best))")
                .font(.poppinsBold(14))
                .foregroundStyle(pct >= 90 ? Color.emberOrange : .white.opacity(0.65))
        }
    }

    private func statLine(_ label: String, _ value: String, index: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.poppins(14))
                .foregroundStyle(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text(value)
                .font(.poppinsBold(14))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: 260)
        .accessibilityElement(children: .combine)
        .opacity(rowsShown ? 1 : 0)
        .offset(y: rowsShown ? 0 : 8)
        .animation(.easeOut(duration: 0.3).delay(0.25 + Double(index) * 0.06), value: rowsShown)
    }

    private func animateIn() {
        rowsShown = true
        requestReviewIfEarned()
        // Score count-up with easing; never snap a number at the payoff moment.
        if reduceMotion {
            displayScore = finalScore
        } else {
            let steps = 24
            for i in 1...steps {
                let t = Double(i) / Double(steps)
                let eased = 1 - pow(1 - t, 3)
                DispatchQueue.main.asyncAfter(deadline: .now() + t * 0.7) {
                    displayScore = Int(Double(finalScore) * eased)
                    if i == steps {
                        displayScore = finalScore
                        if session.isNewBest { Haptics.shared.newBest() }
                    } else if i % 4 == 0 {
                        AudioPlayer.shared.play("ding", pitch: 0.8 + Float(t) * 0.5, volume: 0.25)
                    }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseReplay = true
            }
        }
    }

    private func share() {
        guard let run = session.lastRun else { return }
        AnalyticsService.share()
        let text = """
        I scored \(run.score) in Brinkball — wave \(run.waves), \(run.brinkFlips) brink flips.
        Dare the drain: https://apps.apple.com/app/id6791686352
        """
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        topViewController()?.present(controller, animated: true)
    }

    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
