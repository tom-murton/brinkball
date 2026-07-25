import AVFoundation

/// AVAudioEngine-backed SFX with per-voice pitch (for rising combo dings) plus looped music.
final class AudioPlayer {
    static let shared = AudioPlayer()

    var soundOn = true
    var musicOn = true {
        didSet { musicOn ? startMusic() : stopMusic() }
    }

    private var engine = AVAudioEngine()
    private struct Voice {
        let player = AVAudioPlayerNode()
        let pitch = AVAudioUnitTimePitch()
    }
    private var voices: [Voice] = []
    private var nextVoice = 0
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var started = false

    private init() {}

    func start() {
        guard !started else { return }
        started = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            NSLog("AudioPlayer: session error \(error)")
        }
        buildEngine()
        if buffers.isEmpty {
            for name in ["ding", "flip1", "flip2", "brink", "drain", "waveclear", "fever", "gameover",
                         "whiff", "pip", "newbest"] {
                buffers[name] = loadBuffer(name: name)
            }
        }
        do {
            try engine.start()
        } catch {
            NSLog("AudioPlayer: engine start error \(error)")
        }
        observeSessionNotifications()
        if musicOn { startMusic() }
    }

    private func buildEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        voices.removeAll()
        for _ in 0..<8 {
            let v = Voice()
            engine.attach(v.player)
            engine.attach(v.pitch)
            engine.connect(v.player, to: v.pitch, format: format)
            engine.connect(v.pitch, to: engine.mainMixerNode, format: format)
            voices.append(v)
        }
    }

    private var observersInstalled = false

    private func observeSessionNotifications() {
        guard !observersInstalled else { return }
        observersInstalled = true
        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let self,
                  let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            self.recoverEngine()
            if self.musicOn { self.musicPlayer?.play() }
        }
        nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: nil, queue: .main) { [weak self] _ in
            self?.recoverEngine()
        }
        nc.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            // All audio objects are invalid after a media-services reset: rebuild from scratch.
            self.musicPlayer = nil
            self.engine = AVAudioEngine()
            self.started = false
            self.start()
        }
    }

    private func recoverEngine() {
        guard started, !engine.isRunning else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        do {
            try engine.start()
        } catch {
            NSLog("AudioPlayer: engine recover failed \(error)")
        }
    }

    /// Play a one-shot. `pitch` is a rate multiplier (1.0 = as recorded).
    func play(_ name: String, pitch: Float = 1.0, volume: Float = 1.0) {
        guard soundOn, started, let buffer = buffers[name] else { return }
        if !engine.isRunning {
            recoverEngine()
            guard engine.isRunning else { return }
        }
        let v = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        v.pitch.pitch = 1200 * log2(pitch)   // convert rate multiplier to cents
        v.player.volume = volume
        v.player.stop()
        v.player.scheduleBuffer(buffer, at: nil)
        v.player.play()
    }

    /// Sidechain-style duck: drop the music under a big confirm, then recover.
    /// Volume fades only — no engine/graph changes on a shipped audio stack.
    func duckMusic() {
        guard musicOn, let musicPlayer, musicPlayer.isPlaying else { return }
        musicPlayer.setVolume(0.18, fadeDuration: 0.06)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
            guard let self, self.musicOn, let player = self.musicPlayer else { return }
            player.setVolume(0.55, fadeDuration: 0.5)
        }
    }

    private func startMusic() {
        // Courtesy: don't lay our loop over the player's own audio.
        guard !AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint else { return }
        guard started, musicPlayer == nil,
              let url = Bundle.main.url(forResource: "music", withExtension: "mp3") else { return }
        musicPlayer = try? AVAudioPlayer(contentsOf: url)
        musicPlayer?.numberOfLoops = -1
        musicPlayer?.volume = 0.55
        musicPlayer?.play()
    }

    private func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    private func loadBuffer(name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
              let file = try? AVAudioFile(forReading: url) else {
            NSLog("AudioPlayer: missing \(name).mp3")
            return nil
        }
        let processing = file.processingFormat
        guard let raw = AVAudioPCMBuffer(pcmFormat: processing, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: raw)) != nil else { return nil }
        // Convert to the engine's standard format so every voice can play every buffer.
        guard let target = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2),
              let converter = AVAudioConverter(from: processing, to: target) else { return raw }
        let capacity = AVAudioFrameCount(Double(raw.frameLength) * (44100.0 / processing.sampleRate)) + 1024
        guard let out = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return raw }
        var fed = false
        converter.convert(to: out, error: nil) { _, status in
            if fed {
                status.pointee = .endOfStream
                return nil
            }
            fed = true
            status.pointee = .haveData
            return raw
        }
        return out
    }
}
