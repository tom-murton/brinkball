# Game Design — Brinkball

## Product
- **Name:** Brinkball (App Store title: game name only; model attribution in subtitle/description)
- **Genre:** one-thumb physics arcade / score-attack ("single-flipper pinball tower" with a risk-timing economy)
- **Audience:** premium-arcade score-chasers; sessions 1–4 minutes, infinitely replayable
- **Platform:** iPhone only, portrait only, iOS 17+
- **Business model:** paid upfront US $1.99 · no ads · no IAP · no tracking · offline

## Core loop (one sentence)
Tap to swat the ever-falling ember ball up through fields of glass pegs — the deeper you dare to let it fall into the brink bands, the harder it launches and the bigger your multiplier — pop pegs, clear waves, survive three drains, chase your best score.

## Rules
1. The ball falls under gravity through a portrait shaft. Angled side walls keep every descent recoverable.
2. The bottom ~30% of the screen is the **flip strip**, in three visible bands: **×1** (cool blue, top), **×2** (amber), **×4 BRINK** (thin red strip just above the drain).
3. **Tap = flip.** If the ball is inside the strip when you tap, it launches **toward your tap point** (clamped to an upward cone) — the tap carries WHERE; the band the ball occupied carries POWER and sets the **multiplier** for all peg hits until the ball next re-enters the strip. A BRINK flip triggers 0.3 s slow-mo, a flash, and a heavy haptic.
4. Tapping while the ball is above the strip does nothing (no penalty, subtle shimmer feedback). The ball falling past the drain loses one of **3 balls**; the next ball serves after a beat.
5. **Pegs** pop on one hit (armored pegs from wave 4 take two) and score `10 × multiplier`, with a per-flight combo that raises the ding pitch per consecutive hit. Clearing a wave pays a bonus (`250 + 50×wave`) and the next, denser hand-authored pattern descends. Gravity and serve speed ramp gently per wave, capped at wave 12.
6. **Fever:** every BRINK flip fills a third of the fever meter; a full meter ignites 10 s of Fever — all scoring ×2, bloom visuals, its own audio layer.
7. Run ends after three drains → score, best score, run stats (waves, pegs, best combo, BRINK flips), one-tap replay (< 1 s to a new run).

## Minimum feature set that makes it fun
- The **greed economy** (multiplier bands + slow-mo BRINK saves) — this IS the game; largest tuning budget.
- Juice: peg-pop particles, ball ember trail, rising-pitch combo dings (AVAudioEngine time-pitch), screen shake tiers, haptic tiers, wave-clear confetti.
- Progression + retention (Apple 4.2 armor): wave ramp, persistent best score + stats, **Game Center: 1 leaderboard ("Best Score") + 6 achievements** (First Brink · Wave 5 · Wave 10 · 100 pegs in a run · Fever ignited · 25,000 points).
- Completeness shell: Home (Play · How to Play · Settings · Game Center), pause/auto-pause on background, settings (sound / music / haptics toggles), 3-panel how-to, VoiceOver on all menus, Dynamic Type, reduce-motion honored (no slow-mo flash bursts), color-independent readability (bands differ by position + label, pegs by brightness).

## Deliberately cut (scope is a feature)
- Daily seeded mode + share grid (R2 candidate), ball/palette skin unlocks, iPad layout, landscape, cloud save, localization beyond English, alternate modes, second leaderboard, tvOS/widgets. No procgen — waves are authored arrays.

## Art direction
"Neon glass arcade": near-black ink background with a faint AI-generated nebula; pegs = luminous glass orbs (programmatic Core Graphics radial-gradient textures — crisp, tintable, no alpha-extraction risk); ball = hot ember with particle wake; flip strip bands as translucent color fields with big multiplier glyphs; chunky retro-future score type. Fonts: **Bungee** (display) + **Poppins** (UI), both OFL from the local asset library.

## Audio direction
AI-generated (gen-audio/ElevenLabs): glass peg ding (single sample, live pitch-shifted per combo), 3 flip whooshes by power tier, BRINK slam, drain thud, wave-clear chime, fever ignition, game-over sting, ~70 s ambient synthwave loop. Mixed via AVAudioEngine (SFX bus with time-pitch + music bus).

## Tech + services
- **Engine:** native Swift — SpriteKit (game scene) + SwiftUI (shell/menus). See DECISION_LOG for rationale.
- **Game Center:** yes (leaderboard + achievements via `asc game-center`), no accounts of our own.
- **Backend:** none. Offline-first.
- **Metrics (required):** Firebase Analytics + Crashlytics per `rig/METRICS-SPEC.md` — user properties `built_by_model=claude-fable-5-ultra`, `game=brinkball`, `engine=native`, `benchmark_version=1.0`; events `game_start`, `game_over{score,duration_seconds,result}`, `replay`, `level_reached{level=wave}`, `settings_opened`. App Privacy: Usage Data + Identifiers, analytics only, no tracking, no IDFA/ATT.
- **Bundle ID:** `com.tommurton.brinkball` · SKU `com.tommurton.brinkball` · primary locale `en-GB`.
