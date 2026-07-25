import SpriteKit
import UIKit

/// The Brinkball playfield. One scene, one ball, authored peg waves, and the
/// flip-strip greed economy: deeper flip = harder launch + bigger multiplier.
final class GameScene: SKScene, SKPhysicsContactDelegate {
    // Physics categories
    private enum Category {
        static let ball: UInt32 = 1 << 0
        static let peg: UInt32 = 1 << 1
        static let wall: UInt32 = 1 << 2
    }

    // Injected by GameView
    var session: GameSession?

    private var engine = ScoreEngine()
    private var runStartDate = Date()
    private var hasStarted = false
    /// One fever-meter tick per strip visit — resets when the ball climbs back
    /// above the strip, so multi-tapping inside the brink band can't farm Fever.
    private var canBankBrink = true
    /// While the player has paused, refuse SpriteKit's auto-unpause on
    /// app activation (it would run the game behind the PAUSED overlay).
    private var pauseHeld = false

    // First-ever-run tutorial. Grace fires only on failure signals so an
    // expert ignoring it never sees it.
    private var tutorialActive = false
    private var tutorialFlips = 0
    private var tutorialHoldingBall = false
    /// One free re-serve on the first-ever run's first drain.
    private var rekindleAvailable = false
    private var deeperHintShown = false

    // Mid-run NEW BEST moment.
    private var bestAtRunStart = 0
    private var newBestShown = false

    // Fever world state.
    private var feverOverlay: SKSpriteNode?
    private var feverEndDate: Date?
    private var ballTrail: SKEmitterNode?

    // Last-ball danger glow.
    private var dangerGlow: SKSpriteNode?

    override var isPaused: Bool {
        get { super.isPaused }
        set { super.isPaused = pauseHeld ? true : newValue }
    }

    func setUserPaused(_ paused: Bool) {
        pauseHeld = paused
        super.isPaused = paused
    }

    // Nodes
    private var ball: SKSpriteNode?
    private let pegLayer = SKNode()
    private let bandLayer = SKNode()
    private var bandNodes: [FlipBand: SKSpriteNode] = [:]
    private var pegsRemaining = 0

    // Textures (built once per scene)
    private var emberTexture: SKTexture!
    private var pegTextures: [SKTexture] = []
    private var armoredTexture: SKTexture!
    private var sparkTexture: SKTexture!

    private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    // Layout helpers
    private var playWidth: CGFloat { size.width }
    private func yAt(_ fraction: CGFloat) -> CGFloat { size.height * fraction }

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1)
        physicsWorld.contactDelegate = self
        scaleMode = .resizeFill

        emberTexture = Textures.ember(diameter: GameConfig.ballRadius * 2)
        pegTextures = [
            Textures.orb(diameter: GameConfig.pegRadius * 2, color: UIColor(red: 0.22, green: 0.90, blue: 0.83, alpha: 1)),
            Textures.orb(diameter: GameConfig.pegRadius * 2, color: UIColor(red: 0.54, green: 0.48, blue: 1.0, alpha: 1)),
        ]
        armoredTexture = Textures.orb(diameter: GameConfig.pegRadius * 2, color: UIColor(red: 0.55, green: 0.62, blue: 0.72, alpha: 1))
        sparkTexture = Textures.glowDot(diameter: 24)

        addBackground()
        addWalls()
        addBands()
        addChild(pegLayer)
        addChild(bandLayer)
        addStateOverlays()

        if !hasStarted {
            hasStarted = true
            startRun(isReplay: false)
        }
    }

    /// Fever tint + last-ball danger glow, both invisible until their state hits.
    private func addStateOverlays() {
        let fever = SKSpriteNode(color: SKColor(red: 1, green: 0.32, blue: 0.15, alpha: 1), size: size)
        fever.position = CGPoint(x: size.width / 2, y: size.height / 2)
        fever.zPosition = -10   // above background, below pegs
        fever.alpha = 0
        fever.blendMode = .add
        addChild(fever)
        feverOverlay = fever

        let glow = SKSpriteNode(texture: Textures.bottomGlow(width: size.width, height: size.height * 0.22))
        glow.anchorPoint = CGPoint(x: 0.5, y: 0)
        glow.position = CGPoint(x: size.width / 2, y: 0)
        glow.zPosition = -5
        glow.alpha = 0
        addChild(glow)
        dangerGlow = glow
    }

    private func addBackground() {
        if let image = UIImage(named: "bg-nebula") {
            let bg = SKSpriteNode(texture: SKTexture(image: image))
            bg.size = size
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
            bg.zPosition = -20
            bg.alpha = 0.85
            addChild(bg)
        }
    }

    private func addWalls() {
        // Side walls + ceiling as one edge path; two funnel deflectors guide
        // descents back over the strip so every fall is saveable.
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: size.width, y: 0))
        let border = SKNode()
        border.physicsBody = SKPhysicsBody(edgeChainFrom: path)
        border.physicsBody?.categoryBitMask = Category.wall
        border.physicsBody?.friction = 0
        border.physicsBody?.restitution = 0.5
        addChild(border)

        for isLeft in [true, false] {
            let deflector = SKNode()
            let p = CGMutablePath()
            let x0: CGFloat = isLeft ? 0 : size.width
            let x1: CGFloat = isLeft ? size.width * 0.10 : size.width * 0.90
            p.move(to: CGPoint(x: x0, y: yAt(0.34)))
            p.addLine(to: CGPoint(x: x1, y: yAt(0.10)))
            deflector.physicsBody = SKPhysicsBody(edgeChainFrom: p)
            deflector.physicsBody?.categoryBitMask = Category.wall
            deflector.physicsBody?.friction = 0
            deflector.physicsBody?.restitution = 0.4
            addChild(deflector)

            let visual = SKShapeNode(path: p)
            visual.strokeColor = SKColor(white: 0.65, alpha: 0.35)
            visual.lineWidth = 2
            visual.glowWidth = 1.5
            visual.zPosition = -4
            addChild(visual)
        }
    }

    private func addBands() {
        let bands: [(FlipBand, ClosedRange<CGFloat>, SKColor, String)] = [
            (.x1, GameConfig.x2Top...GameConfig.stripTop, SKColor(red: 0.25, green: 0.55, blue: 1, alpha: 1), "×1"),
            (.x2, GameConfig.brinkTop...GameConfig.x2Top, SKColor(red: 1, green: 0.72, blue: 0.15, alpha: 1), "×2"),
            (.brink, GameConfig.drainY...GameConfig.brinkTop, SKColor(red: 1, green: 0.18, blue: 0.22, alpha: 1), "×4"),
        ]
        for (band, range, color, label) in bands {
            let height = yAt(range.upperBound) - yAt(range.lowerBound)
            let node = SKSpriteNode(color: color.withAlphaComponent(0.11), size: CGSize(width: size.width, height: height))
            node.position = CGPoint(x: size.width / 2, y: yAt(range.lowerBound) + height / 2)
            node.zPosition = -6
            bandLayer.addChild(node)
            bandNodes[band] = node

            let text = SKLabelNode(fontNamed: "Bungee-Regular")
            text.text = label
            text.fontSize = band == .brink ? 20 : 26
            text.fontColor = color.withAlphaComponent(0.55)
            text.verticalAlignmentMode = .center
            text.horizontalAlignmentMode = .right
            text.position = CGPoint(x: size.width / 2 - 24, y: 0)
            node.addChild(text)

            let line = SKSpriteNode(color: color.withAlphaComponent(0.5), size: CGSize(width: size.width, height: 1.5))
            line.position = CGPoint(x: 0, y: height / 2)
            node.addChild(line)
        }
    }

    // MARK: - Run lifecycle

    func startRun(isReplay: Bool) {
        removeAction(forKey: "fever")
        removeAction(forKey: "fevertick")
        removeAction(forKey: "serve")
        removeAction(forKey: "endrun")
        removeAction(forKey: "slowmo")
        removeAction(forKey: "wavespawn")
        canBankBrink = true
        engine = ScoreEngine()
        runStartDate = Date()
        physicsWorld.speed = 1
        pegLayer.removeAllChildren()
        ball?.removeFromParent()
        ball = nil
        childNode(withName: "tutorialTap")?.removeFromParent()
        feverOverlay?.removeAllActions()
        feverOverlay?.alpha = 0
        feverEndDate = nil
        dangerGlow?.removeAllActions()
        dangerGlow?.alpha = 0
        tutorialActive = !PlayerStore.shared.tutorialSeen
        tutorialFlips = 0
        tutorialHoldingBall = false
        rekindleAvailable = tutorialActive
        deeperHintShown = false
        bestAtRunStart = PlayerStore.shared.bestScore
        newBestShown = false
        spawnWave(engine.wave)
        applyGravity()
        pushHUD()
        session?.runStarted(isReplay: isReplay)
        scheduleServe(after: 0.35)
    }

    private func applyGravity() {
        physicsWorld.gravity = CGVector(dx: 0, dy: engine.gravity)
    }

    private func scheduleServe(after delay: TimeInterval) {
        run(.sequence([.wait(forDuration: delay), .run { [weak self] in
            self?.serveBall()
        }]), withKey: "serve")
    }

    private func serveBall() {
        guard ball == nil, engine.ballsLeft > 0 else { return }
        let node = SKSpriteNode(texture: emberTexture)
        node.size = CGSize(width: GameConfig.ballRadius * 2, height: GameConfig.ballRadius * 2)
        node.position = CGPoint(x: size.width / 2, y: yAt(0.33))
        node.zPosition = 5
        let body = SKPhysicsBody(circleOfRadius: GameConfig.ballRadius)
        body.categoryBitMask = Category.ball
        body.contactTestBitMask = Category.peg
        body.collisionBitMask = Category.peg | Category.wall
        body.restitution = GameConfig.ballRestitution
        body.friction = 0.05
        body.linearDamping = 0.05
        body.angularDamping = 0.4
        body.allowsRotation = true
        body.usesPreciseCollisionDetection = true
        node.physicsBody = body
        addChild(node)
        ball = node

        // Ember trail
        let trail = SKEmitterNode()
        trail.particleTexture = sparkTexture
        trail.particleBirthRate = 90
        trail.particleLifetime = 0.35
        trail.particleAlpha = 0.5
        trail.particleAlphaSpeed = -1.4
        trail.particleScale = 0.5
        trail.particleScaleSpeed = -1.2
        trail.particleColor = UIColor(red: 1, green: 0.6, blue: 0.15, alpha: 1)
        trail.particleColorBlendFactor = 1
        trail.particleBlendMode = .add
        trail.targetNode = self
        node.addChild(trail)
        ballTrail = trail
        if feverEndDate != nil { trail.particleBirthRate = 220 }

        let jitter = CGFloat.random(in: -140...140)
        body.velocity = CGVector(dx: jitter, dy: GameConfig.serveSpeed * heightScale)
        AudioPlayer.shared.play("flip1", pitch: 0.9, volume: 0.7)
    }

    private var heightScale: CGFloat { size.height / 844 }

    // MARK: - Waves

    private func spawnWave(_ wave: Int) {
        let specs = WaveLibrary.pegs(forWave: wave)
        pegsRemaining = specs.count
        for (i, spec) in specs.enumerated() {
            let armored = spec.armored
            let texture = armored ? armoredTexture! : pegTextures[i % pegTextures.count]
            let peg = SKSpriteNode(texture: texture)
            peg.size = CGSize(width: GameConfig.pegRadius * 2, height: GameConfig.pegRadius * 2)
            peg.position = CGPoint(x: spec.x * playWidth, y: yAt(spec.y))
            peg.zPosition = 2
            peg.userData = ["hits": armored ? GameConfig.armoredPegHits : 1]
            let body = SKPhysicsBody(circleOfRadius: GameConfig.pegRadius)
            body.isDynamic = false
            body.categoryBitMask = Category.peg
            body.restitution = 0.55
            body.friction = 0
            peg.physicsBody = body
            peg.alpha = 0
            peg.setScale(0.4)
            pegLayer.addChild(peg)
            peg.run(.group([
                .fadeIn(withDuration: 0.25),
                .scale(to: 1, duration: 0.25),
            ]))
        }
        session?.waveReached(wave)
    }

    private func waveCleared() {
        let clearedWave = engine.wave
        let bonus = engine.waveCleared()
        applyGravity()
        pushHUD()
        checkNewBest()
        AudioPlayer.shared.play("waveclear")
        Haptics.shared.waveClear()

        // Settlement beat: brief slow-mo breath + confetti + a banner that
        // arrives with intent — the loop's most repeatable milestone gets a
        // real celebration arc.
        if action(forKey: "slowmo") == nil {
            hitStop(0, then: 0.35, holdFor: 0.35)
        }
        banner("WAVE \(clearedWave) CLEAR", sub: "+\(bonus)")
        if !reduceMotion {
            confetti(at: CGPoint(x: size.width / 2, y: size.height * 0.62))
        }
        run(.sequence([.wait(forDuration: 0.9), .run { [weak self] in
            guard let self else { return }
            self.spawnWave(self.engine.wave)
        }]), withKey: "wavespawn")
    }

    /// Full-width celebration banner that scales in with a back-ease, holds,
    /// and fades — replaces the drive-by float label for milestone moments.
    private func banner(_ text: String, sub: String? = nil) {
        let group = SKNode()
        group.position = CGPoint(x: size.width / 2, y: size.height * 0.56)
        group.zPosition = 24

        let title = SKLabelNode(fontNamed: "Bungee-Regular")
        title.text = text
        title.fontSize = 34
        title.fontColor = UIColor(red: 0.35, green: 1, blue: 0.75, alpha: 1)
        title.verticalAlignmentMode = .center
        group.addChild(title)

        if let sub {
            let bonus = SKLabelNode(fontNamed: "Bungee-Regular")
            bonus.text = sub
            bonus.fontSize = 24
            bonus.fontColor = .white
            bonus.verticalAlignmentMode = .center
            bonus.position = CGPoint(x: 0, y: -36)
            group.addChild(bonus)
        }
        addChild(group)

        if reduceMotion {
            group.alpha = 0
            group.run(.sequence([.fadeIn(withDuration: 0.15), .wait(forDuration: 0.9),
                                 .fadeOut(withDuration: 0.3), .removeFromParent()]))
        } else {
            group.setScale(0.1)
            group.alpha = 0
            let pop = SKAction.group([.fadeIn(withDuration: 0.12), .scale(to: 1.08, duration: 0.18)])
            pop.timingMode = .easeOut
            group.run(.sequence([pop, .scale(to: 1.0, duration: 0.10), .wait(forDuration: 0.8),
                                 .group([.fadeOut(withDuration: 0.3), .moveBy(x: 0, y: 30, duration: 0.3)]),
                                 .removeFromParent()]))
        }
    }

    /// One-shot multicolour celebration burst with gravity so debris falls.
    private func confetti(at point: CGPoint) {
        for color in [UIColor(red: 0.35, green: 1, blue: 0.75, alpha: 1),
                      UIColor(red: 1, green: 0.72, blue: 0.15, alpha: 1),
                      UIColor(red: 0.54, green: 0.48, blue: 1, alpha: 1),
                      UIColor(red: 1, green: 0.5, blue: 0.9, alpha: 1)] {
            let e = SKEmitterNode()
            e.particleTexture = sparkTexture
            e.numParticlesToEmit = 16
            e.particleBirthRate = 300
            e.particleLifetime = 1.1
            e.particleSpeed = 320
            e.particleSpeedRange = 160
            e.emissionAngle = .pi / 2
            e.emissionAngleRange = .pi * 0.9
            e.yAcceleration = -700
            e.particleAlpha = 0.95
            e.particleAlphaSpeed = -0.8
            e.particleScale = 0.6
            e.particleScaleRange = 0.25
            e.particleScaleSpeed = -0.3
            e.particleColor = color
            e.particleColorBlendFactor = 1
            e.particleBlendMode = .add
            e.position = point
            e.zPosition = 22
            addChild(e)
            e.run(.sequence([.wait(forDuration: 1.4), .removeFromParent()]))
        }
    }

    /// Fires the one-shot mid-run NEW BEST moment the frame the run crosses it.
    private func checkNewBest() {
        guard !newBestShown, bestAtRunStart > 0, engine.score > bestAtRunStart else { return }
        newBestShown = true
        AudioPlayer.shared.play("newbest", volume: 0.9)
        Haptics.shared.newBest()
        banner("NEW BEST!")
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, session?.phase == .playing, !isPaused else { return }
        attemptFlip(toward: touch.location(in: self))
    }

    private func attemptFlip(toward tap: CGPoint) {
        guard let ball, let body = ball.physicsBody else { return }
        let band = ScoreEngine.band(atHeightFraction: ball.position.y / size.height)
        guard band.multiplier > 0 else {
            whiffFeedback(at: tap)
            return
        }

        // Direction: toward the tap, clamped to an upward cone.
        let dx = tap.x - ball.position.x
        let dy = max(tap.y - ball.position.y, 40)   // never launch downward or flat
        var angle = atan2(dx, dy)   // 0 = straight up
        angle = max(-GameConfig.maxLaunchAngle, min(GameConfig.maxLaunchAngle, angle))
        let speed = band.flipSpeed * heightScale
        body.velocity = CGVector(dx: speed * sin(angle), dy: speed * cos(angle))

        if tutorialHoldingBall { endTutorialBeat() }
        let bankedBefore = engine.brinkMeter
        let ignitedFever = engine.flip(from: band, bankBrink: canBankBrink)
        let banked = band == .brink && engine.brinkMeter == bankedBefore + 1
        if band == .brink { canBankBrink = false }
        pushHUD()

        launchJuice(on: ball, band: band, angle: angle)

        if ignitedFever {
            igniteFever()
        } else {
            switch band {
            case .x1:
                AudioPlayer.shared.play("flip1")
                Haptics.shared.flip()
            case .x2:
                AudioPlayer.shared.play("flip2")
                Haptics.shared.flip()
            case .brink:
                brinkEffects()
                if banked {
                    AudioPlayer.shared.play("pip", pitch: engine.brinkMeter == 1 ? 1.0 : 1.26)
                    floatLabel("FEVER \(engine.brinkMeter)/\(GameConfig.brinkFlipsToFever)",
                               at: CGPoint(x: size.width / 2, y: yAt(0.36)),
                               color: UIColor(red: 1, green: 0.5, blue: 0.9, alpha: 1), size: 22)
                }
            default:
                break
            }
        }

        if tutorialActive {
            tutorialFlips += 1
            if !deeperHintShown, tutorialFlips == 1 {
                deeperHintShown = true
                run(.sequence([.wait(forDuration: 1.0), .run { [weak self] in
                    guard let self, self.tutorialActive else { return }
                    self.floatLabel("DEEPER = BIGGER ×", at: CGPoint(x: self.size.width / 2, y: self.yAt(0.22)),
                                    color: UIColor(red: 1, green: 0.72, blue: 0.15, alpha: 1), size: 24)
                }]))
            }
            if tutorialFlips >= GameConfig.tutorialFlipsToComplete {
                tutorialActive = false
                PlayerStore.shared.completeTutorial()
            }
        }
    }

    /// A tap while the ball is outside the strip: visible + audible + felt cost
    /// signal so the miss teaches the timing window instead of feeling ignored.
    private func whiffFeedback(at tap: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: 14)
        ring.position = tap
        ring.strokeColor = SKColor(white: 1, alpha: 0.45)
        ring.lineWidth = 2
        ring.zPosition = 10
        addChild(ring)
        ring.run(.sequence([.group([.scale(to: 2, duration: 0.25), .fadeOut(withDuration: 0.25)]), .removeFromParent()]))
        // Flash the strip so the eye learns WHERE taps work.
        bandLayer.removeAction(forKey: "stripflash")
        bandLayer.run(.sequence([.fadeAlpha(to: 1.8, duration: 0.05), .fadeAlpha(to: 1.0, duration: 0.20)]), withKey: "stripflash")
        AudioPlayer.shared.play("whiff", volume: 0.6)
        Haptics.shared.whiff()
        if tutorialActive {
            floatLabel("WAIT FOR THE STRIP", at: CGPoint(x: size.width / 2, y: yAt(0.36)),
                       color: UIColor(white: 1, alpha: 0.85), size: 20)
        }
    }

    /// Squash & stretch along the launch vector + a band-coloured shockwave —
    /// the single player verb carries the top of the juice budget.
    private func launchJuice(on ball: SKSpriteNode, band: FlipBand, angle: CGFloat) {
        let stretch = GameConfig.flipStretch(for: band)
        ball.removeAction(forKey: "stretch")
        ball.zRotation = -angle
        ball.run(.sequence([
            .group([.scaleX(to: 2 - stretch, duration: 0.06), .scaleY(to: stretch, duration: 0.06)]),
            .scale(to: 1, duration: 0.14),
            .rotate(toAngle: 0, duration: 0.05),
        ]), withKey: "stretch")

        let color: SKColor = switch band {
        case .x2: SKColor(red: 1, green: 0.72, blue: 0.15, alpha: 1)
        case .brink: SKColor(red: 1, green: 0.20, blue: 0.24, alpha: 1)
        default: SKColor(red: 0.35, green: 0.62, blue: 1, alpha: 1)
        }
        let wave = SKShapeNode(circleOfRadius: 18)
        wave.position = ball.position
        wave.strokeColor = color
        wave.lineWidth = 3
        wave.glowWidth = 4
        wave.zPosition = 4
        addChild(wave)
        let scale: CGFloat = band == .brink ? 4.5 : (band == .x2 ? 3.4 : 2.6)
        wave.run(.sequence([.group([.scale(to: scale, duration: 0.32), .fadeOut(withDuration: 0.32)]), .removeFromParent()]))
    }

    /// Briefly zero the simulation so the biggest confirms carry weight.
    private func hitStop(_ duration: TimeInterval, then speed: CGFloat = 1, holdFor hold: TimeInterval = 0) {
        removeAction(forKey: "slowmo")
        physicsWorld.speed = 0
        var steps: [SKAction] = [.wait(forDuration: duration), .run { [weak self] in
            self?.physicsWorld.speed = speed
        }]
        if speed != 1 {
            steps.append(.wait(forDuration: hold))
            steps.append(.run { [weak self] in self?.physicsWorld.speed = 1 })
        }
        run(.sequence(steps), withKey: "slowmo")
    }

    private func brinkEffects() {
        AudioPlayer.shared.play("brink")
        AudioPlayer.shared.duckMusic()
        Haptics.shared.brink()
        floatLabel("BRINK!", at: CGPoint(x: size.width / 2, y: yAt(0.22)),
                   color: UIColor(red: 1, green: 0.25, blue: 0.28, alpha: 1), size: 40)
        if reduceMotion {
            // No flash/shake — the hit-stop + slow-mo time change still reads.
            hitStop(GameConfig.hitStopBrink, then: GameConfig.brinkSlowmoSpeed, holdFor: GameConfig.brinkSlowmoDuration)
            return
        }
        hitStop(GameConfig.hitStopBrink, then: GameConfig.brinkSlowmoSpeed, holdFor: GameConfig.brinkSlowmoDuration)
        let flash = SKSpriteNode(color: SKColor(red: 1, green: 0.3, blue: 0.3, alpha: 1), size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 50
        flash.alpha = 0
        addChild(flash)
        flash.run(.sequence([.fadeAlpha(to: 0.22, duration: 0.05), .fadeOut(withDuration: 0.3), .removeFromParent()]))
        shake(intensity: 10)
    }

    /// The Peggle moment: heavy stop, slow-mo, and the whole world turns ember
    /// for ten seconds — fever must be felt in peripheral vision, not read.
    private func igniteFever() {
        AudioPlayer.shared.play("pip", pitch: 1.5)
        AudioPlayer.shared.play("fever")
        AudioPlayer.shared.duckMusic()
        Haptics.shared.feverIgnite()
        floatLabel("FEVER ×2", at: CGPoint(x: size.width / 2, y: size.height * 0.5),
                   color: UIColor(red: 1, green: 0.5, blue: 0.9, alpha: 1), size: 38)
        hitStop(GameConfig.hitStopFever, then: 0.3, holdFor: 0.4)
        feverEndDate = Date().addingTimeInterval(GameConfig.feverDuration)
        feverOverlay?.removeAllActions()
        feverOverlay?.run(.fadeAlpha(to: 0.16, duration: 0.35))
        ballTrail?.particleBirthRate = 220
        if !reduceMotion { shake(intensity: 8) }
        pushHUD()
        // Countdown so the 10 s is legible on the HUD bar.
        run(.repeatForever(.sequence([.wait(forDuration: 0.1), .run { [weak self] in
            self?.pushHUD()
        }])), withKey: "fevertick")
        run(.sequence([.wait(forDuration: GameConfig.feverDuration), .run { [weak self] in
            self?.endFeverState()
        }]), withKey: "fever")
    }

    private func endFeverState() {
        engine.feverEnded()
        feverEndDate = nil
        removeAction(forKey: "fevertick")
        feverOverlay?.run(.fadeOut(withDuration: 0.5))
        ballTrail?.particleBirthRate = 90
        pushHUD()
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let pegNode: SKNode? = contact.bodyA.categoryBitMask == Category.peg ? contact.bodyA.node
            : (contact.bodyB.categoryBitMask == Category.peg ? contact.bodyB.node : nil)
        guard let peg = pegNode as? SKSpriteNode else { return }
        var hits = (peg.userData?["hits"] as? Int) ?? 1
        hits -= 1
        if hits > 0 {
            peg.userData?["hits"] = hits
            peg.run(.sequence([.scale(to: 0.82, duration: 0.05), .scale(to: 1.0, duration: 0.08)]))
            peg.texture = pegTextures[0]
            AudioPlayer.shared.play("ding", pitch: 0.7, volume: 0.8)
            Haptics.shared.peg()
            return
        }
        popPeg(peg, at: contact.contactPoint)
    }

    private func popPeg(_ peg: SKSpriteNode, at point: CGPoint) {
        peg.physicsBody = nil
        let points = engine.pegHit()
        pegsRemaining -= 1
        pushHUD()
        checkNewBest()

        // ±3% random detune on top of the combo ramp so grinding never fatigues.
        let pitch = min(1.0 + GameConfig.comboPitchStep * Float(engine.combo - 1), GameConfig.comboPitchCap)
            * Float.random(in: 0.97...1.03)
        AudioPlayer.shared.play("ding", pitch: pitch)
        Haptics.shared.peg()

        burst(at: point, color: peg.texture === armoredTexture ? .lightGray : UIColor(red: 0.4, green: 0.95, blue: 0.9, alpha: 1))
        if engine.combo >= 5 || points >= 80 {
            floatLabel("+\(points)", at: peg.position, color: .white, size: 18)
        }
        peg.run(.sequence([
            .group([.scale(to: 1.6, duration: 0.10), .fadeOut(withDuration: 0.10)]),
            .removeFromParent(),
        ]))
        if pegsRemaining <= 0 {
            waveCleared()
        }
    }

    private func burst(at point: CGPoint, color: UIColor) {
        let emitter = SKEmitterNode()
        emitter.particleTexture = sparkTexture
        emitter.numParticlesToEmit = 12
        emitter.particleBirthRate = 400
        emitter.particleLifetime = 0.45
        emitter.particleSpeed = 160
        emitter.particleSpeedRange = 90
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -2
        emitter.particleScale = 0.55
        emitter.particleScaleSpeed = -1
        emitter.yAcceleration = -500   // shards fall — the world remembers the hit
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        emitter.position = point
        emitter.zPosition = 8
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 0.6), .removeFromParent()]))
    }

    // MARK: - Frame update

    override func didSimulatePhysics() {
        autopilotTick()
        guard let ball, let body = ball.physicsBody else { return }

        // Clamp runaway speed (protects against tunneling).
        var v = body.velocity
        let speed = hypot(v.dx, v.dy)
        let maxSpeed: CGFloat = 2000 * heightScale
        if speed > maxSpeed {
            v = CGVector(dx: v.dx / speed * maxSpeed, dy: v.dy / speed * maxSpeed)
            body.velocity = v
        }

        // The air thickens inside the strip: cap fall speed so the greed
        // window stays humanly playable early, then tightens per wave so
        // every run eventually ends.
        if v.dy < 0, ball.position.y < yAt(GameConfig.stripTop) {
            let cap = GameConfig.stripFallCap(wave: engine.wave) * heightScale
            if -v.dy > cap {
                body.velocity = CGVector(dx: v.dx, dy: -cap)
            }
        }

        // Re-arm the fever meter once the ball climbs back above the strip.
        if ball.position.y > yAt(GameConfig.stripTop) {
            canBankBrink = true
        }

        // First-run tutorial: the moment the ball first sinks into the strip,
        // hold time nearly still and ask for the one verb. Resumes on flip.
        if tutorialActive, !tutorialHoldingBall, v.dy < 0,
           ball.position.y < yAt(GameConfig.stripTop), ball.position.y > yAt(GameConfig.drainY + 0.02),
           action(forKey: "slowmo") == nil {
            tutorialHoldingBall = true
            if tutorialFlips == 0, rekindleAvailable {
                // Very first strip entry: hold time almost still (the ball
                // stays in the safe band for the whole hold) so the first
                // flip can't be fumbled, then ease into slow-mo rather than
                // soft-locking a distracted player forever.
                physicsWorld.speed = 0.02
                run(.sequence([.wait(forDuration: 4), .run { [weak self] in
                    guard let self, self.tutorialHoldingBall else { return }
                    self.physicsWorld.speed = GameConfig.tutorialSlowmo
                }]), withKey: "tutrelease")
            } else {
                physicsWorld.speed = GameConfig.tutorialSlowmo
            }
            let tap = SKLabelNode(fontNamed: "Bungee-Regular")
            tap.name = "tutorialTap"
            tap.text = "TAP!"
            tap.fontSize = 44
            tap.fontColor = .white
            tap.position = CGPoint(x: size.width / 2, y: yAt(0.40))
            tap.zPosition = 30
            addChild(tap)
            if !reduceMotion {
                tap.run(.repeatForever(.sequence([.scale(to: 1.15, duration: 0.35), .scale(to: 1.0, duration: 0.35)])))
            }
            bandLayer.removeAction(forKey: "stripflash")
            bandLayer.run(.repeatForever(.sequence([.fadeAlpha(to: 1.7, duration: 0.4), .fadeAlpha(to: 1.0, duration: 0.4)])), withKey: "stripflash")
        }

        // Band highlight while the ball is in the strip.
        let band = ScoreEngine.band(atHeightFraction: ball.position.y / size.height)
        for (b, node) in bandNodes {
            node.alpha = b == band ? 1.9 : 1.0
        }

        // Drain
        if ball.position.y < yAt(GameConfig.drainY) || ball.position.y < -20 {
            drainBall()
        }

        // Stuck watchdog: resting somewhere above the strip → nudge.
        if speed < 15, ball.position.y > yAt(GameConfig.stripTop) {
            stuckFrames += 1
            if stuckFrames > 100 {
                stuckFrames = 0
                body.applyImpulse(CGVector(dx: CGFloat.random(in: -8...8), dy: -6))
            }
        } else {
            stuckFrames = 0
        }
    }

    private var stuckFrames = 0

    // MARK: - Test autopilot (inert unless launched with BRINK_AUTOPILOT=1)

    private lazy var autopilot = ProcessInfo.processInfo.environment["BRINK_AUTOPILOT"] == "1"
    private var autopilotWantsBrink = false

    private func autopilotTick() {
        guard autopilot, let ball, let body = ball.physicsBody, session?.phase == .playing, !isPaused else { return }
        guard body.velocity.dy < 0 else { return }
        let band = ScoreEngine.band(atHeightFraction: ball.position.y / size.height)
        let shouldFlip: Bool
        switch band {
        case .brink: shouldFlip = true
        case .x2: shouldFlip = !autopilotWantsBrink
        default: shouldFlip = false
        }
        guard shouldFlip else { return }
        autopilotWantsBrink = Bool.random()
        let target = CGPoint(x: CGFloat.random(in: size.width * 0.2...size.width * 0.8), y: size.height * 0.8)
        attemptFlip(toward: target)
    }

    private func drainBall() {
        guard let ball else { return }
        let drainPoint = CGPoint(x: min(max(ball.position.x, 30), size.width - 30), y: yAt(0.03))
        self.ball = nil
        ballTrail = nil
        removeAction(forKey: "slowmo")
        physicsWorld.speed = 1
        endTutorialBeat()
        ball.physicsBody = nil
        ball.run(.sequence([.group([.fadeOut(withDuration: 0.2), .scale(to: 0.3, duration: 0.2)]), .removeFromParent()]))

        // First-ever run only: the first drain is a lesson, not a loss.
        if tutorialActive, rekindleAvailable {
            rekindleAvailable = false
            AudioPlayer.shared.play("drain", volume: 0.6)
            Haptics.shared.whiff()
            drainFlash(at: drainPoint)
            floatLabel("REKINDLED — TAP INSIDE THE STRIP", at: CGPoint(x: size.width / 2, y: yAt(0.36)),
                       color: UIColor(red: 1, green: 0.62, blue: 0.18, alpha: 1), size: 19)
            scheduleServe(after: 0.9)
            return
        }

        AudioPlayer.shared.play("drain")
        Haptics.shared.drain()
        if !reduceMotion { shake(intensity: 6) }
        drainFlash(at: drainPoint)
        if tutorialActive {
            floatLabel("MISSED THE STRIP", at: CGPoint(x: size.width / 2, y: yAt(0.36)),
                       color: UIColor(white: 1, alpha: 0.8), size: 19)
        }

        let over = engine.ballDrained()
        pushHUD()
        if over {
            endRun()
        } else {
            if engine.ballsLeft == 1 { startDangerGlow() }
            scheduleServe(after: 0.7)
        }
    }

    /// Red flash where the ball slipped past — every failure is diagnosable.
    private func drainFlash(at point: CGPoint) {
        let flash = SKSpriteNode(texture: sparkTexture)
        flash.position = point
        flash.color = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
        flash.colorBlendFactor = 1
        flash.setScale(2.2)
        flash.alpha = 0.9
        flash.zPosition = 12
        addChild(flash)
        flash.run(.sequence([.group([.scale(to: 5, duration: 0.35), .fadeOut(withDuration: 0.35)]), .removeFromParent()]))
    }

    /// Last ball: slow red pulse concentrated at the drain edge.
    private func startDangerGlow() {
        guard let dangerGlow else { return }
        dangerGlow.removeAllActions()
        if reduceMotion {
            dangerGlow.run(.fadeAlpha(to: 0.30, duration: 0.4))   // static, no pulse
        } else {
            dangerGlow.alpha = 0.18
            dangerGlow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.42, duration: 0.9),
                .fadeAlpha(to: 0.18, duration: 0.9),
            ])))
        }
    }

    private func endRun() {
        removeAction(forKey: "fever")
        endFeverState()
        dangerGlow?.removeAllActions()
        dangerGlow?.run(.fadeOut(withDuration: 0.3))
        AudioPlayer.shared.play("gameover")
        AudioPlayer.shared.duckMusic()
        Haptics.shared.gameOver()
        // A beat of stillness before the card: the loss lands, then the card slides in.
        hitStop(GameConfig.hitStopFinalDrain)
        let stats = RunStats(engine: engine, duration: Date().timeIntervalSince(runStartDate))
        run(.sequence([.wait(forDuration: 0.55), .run { [weak self] in
            self?.session?.runEnded(stats)
        }]), withKey: "endrun")
    }

    // MARK: - Bits

    /// Ends the tutorial "TAP!" hold and restores time.
    private func endTutorialBeat() {
        tutorialHoldingBall = false
        removeAction(forKey: "tutrelease")
        childNode(withName: "tutorialTap")?.removeFromParent()
        bandLayer.removeAction(forKey: "stripflash")
        bandLayer.alpha = 1
        if action(forKey: "slowmo") == nil {
            physicsWorld.speed = 1
        }
    }

    private func pushHUD() {
        guard let session else { return }
        session.score = engine.score
        session.ballsLeft = engine.ballsLeft
        session.wave = engine.wave
        session.multiplier = engine.multiplier
        session.feverActive = engine.feverActive
        session.brinkPips = engine.brinkMeter
        if engine.feverActive, let end = feverEndDate {
            // Counts down 1 → 0 so the HUD bar drains through the 10 s.
            session.feverProgress = max(0, min(1, end.timeIntervalSinceNow / GameConfig.feverDuration))
        } else {
            session.feverProgress = Double(engine.brinkMeter) / Double(GameConfig.brinkFlipsToFever)
        }
    }

    private func floatLabel(_ text: String, at point: CGPoint, color: UIColor, size fontSize: CGFloat) {
        let label = SKLabelNode(fontNamed: "Bungee-Regular")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.position = point
        label.zPosition = 20
        label.setScale(0.6)
        addChild(label)
        label.run(.sequence([
            .group([.scale(to: 1, duration: 0.12), .moveBy(x: 0, y: 40, duration: 0.9), .sequence([.wait(forDuration: 0.45), .fadeOut(withDuration: 0.45)])]),
            .removeFromParent(),
        ]))
    }

    private func shake(intensity: CGFloat) {
        guard !reduceMotion else { return }
        let amounts: [CGFloat] = [intensity, -intensity * 0.7, intensity * 0.4, -intensity * 0.2]
        var actions: [SKAction] = []
        for a in amounts {
            actions.append(.moveBy(x: a, y: a * 0.6, duration: 0.04))
            actions.append(.moveBy(x: -a, y: -a * 0.6, duration: 0.04))
        }
        pegLayer.run(.sequence(actions))
    }
}
