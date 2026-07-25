# Improvement Report — Brinkball (Round 2)

*Round 1 shipped Brinkball v1.0 to "Ready to Submit." This round played that game cold,
researched what would make it genuinely better, rebuilt it, and re-shipped v1.1 (build 2)
back to "Ready to Submit."*

> ## ⚠️ Model attribution — round 2 did NOT run on Fable 5
>
> **Round 2 ran on Claude Opus 4.8, not Claude Fable 5.** During this session Fable 5's
> safeguards flagged a message and the harness fell back to Opus 4.8, which reported:
>
> > *"Fable 5's safeguards flagged this message. The safeguards are intentionally broad right
> > now and may flag safe and routine coding, cybersecurity, or biology work. These measures let
> > us bring you Mythos-level capabilities sooner, and we're working to refine them.
> > **Switched to Opus 4.8.**"*
>
> **What this means for the benchmark:**
> - **Round 1 (build v1.0)** = Claude Fable 5. **Round 2 (build v1.1)** = Claude Opus 4.8.
> - This report's "I" is therefore **Opus 4.8 critiquing Fable 5's work** — a *different*
>   model reviewing another model's game. That is a materially different test from the
>   intended "can a model critique *itself*," and round-2 scores should be read that way.
> - **Honest limitation:** the fallback was observed by the operator from outside the session.
>   From inside, I cannot determine which turns (if any) ran on Fable 5 before the switch —
>   the session identifies itself as `claude-opus-4-8`. The safest reading is that
>   round 2's work is **wholly or predominantly Opus 4.8**.
> - **The public App Store description was corrected** as a result: it had claimed the R2 pass
>   was by "the same model," which is false. It now names Claude Opus 4.8 explicitly (see
>   *Re-ship* below). Shipping a false attribution on a paid listing in a benchmark about
>   honest AI attribution was not acceptable.
> - **`built_by_model` analytics is unchanged** at `claude-fable-5-ultra` — it identifies the
>   game's run/provenance (Fable 5 authored the game that exists) and preserves R1↔R2
>   comparability in the shared dashboard. `benchmark_version=1.1` distinguishes the R2 build.
>   Flagged to the operator as a judgement call rather than decided unilaterally.

## Critique summary
The five biggest problems round-1 me shipped (full detail in [CRITIQUE.md](CRITIQUE.md), evidence in `screenshots/r2-play/`):

1. **No onboarding — a passive new player was dead in ~15 seconds at score 40, with zero idea why.** The tutorial was three paragraphs of text behind a menu button no store-buyer taps. Reproduced live on a fresh install.
2. **The core economy was invisible.** The whole game is "which band did you flip from," yet the current multiplier was displayed *nowhere*, and the Fever meter was hidden until the first brink flip. You could finish a run never understanding the scoring.
3. **Fever — the game's marquee state — was a visual non-event.** Ten seconds of double score looked pixel-identical to normal play. R1's own store screenshot needed a HUD badge just to be identifiable as Fever.
4. **The milestones had no ceremony.** Wave clear was one drive-by label (the design doc promised confetti); the game-over score just appeared; "NEW BEST" got no moment. Flat, tech-demo feel.
5. **The first minute was the worst minute.** Wave 1 was 9 sparse pegs — the emptiest, slowest, lowest-scoring stretch of a game whose deeper waves are genuinely fun. Exactly backwards for retention. Plus: no share hook, invisible whiff feedback, plain home screen.

## What I changed (before → after)
Ranked by player-facing impact. Every item was played and watched working on-sim.

1. **Fever is now a whole-screen state (before: identical to normal → after: the world turns ember).** A red overlay crossfades in, the ball's trail thickens, a draining timer bar shows the 10 s, ignition gets a hit-stop + slow-mo "Peggle moment." You *feel* Fever in peripheral vision now. Verified: `screenshots/r2-play/auto-8.png`, `21-rm-game.png`.
2. **The multiplier is always on the HUD (before: invisible → after: a band-coloured ×1/×2/×4 chip that punches on every change), plus three Fever pips that fill toward ignition.** The HUD is now the strip legend — it doubles as passive onboarding. Verified across the deep-run captures.
3. **A wordless first-run tutorial (before: none → after: teach-by-doing).** On the very first strip entry, time nearly freezes with a pulsing "TAP!" and a glowing strip; the first flip can't be fumbled; the first drain is a free REKINDLE instead of a lost ball; a one-time "DEEPER = BIGGER ×" hint fires after the first flip. It retires after two successful flips and never returns (grace keys off failure signals only, so experts never see it). Verified via os_log trace + screenshots `11`–`17`.
4. **The game-over card was rebuilt (before: static, instant → after: a real payoff).** It slides up, the score counts up with rising ticks, and it always answers "how close was I?" — "You beat your best. Again?" on a record, or "N% of your best / SO CLOSE — X from your best" otherwise. Stats cascade in; REPLAY stays under the thumb; a **SHARE** button (new) renders a score card to the iOS share sheet.
5. **Milestone ceremony (before: one label → after: celebration arcs).** Wave clear now plays a slow-mo blip + multicolour confetti + a "WAVE N CLEAR +bonus" banner that scales in with a back-ease; glass orbs shatter into falling shards; a mid-run "NEW BEST!" ribbon fires the frame you cross your best.
6. **Band-tiered flip juice (before: every flip looked the same → after: force is legible).** Squash-and-stretch scaled by band depth (×1 subtle → ×4 dramatic), a band-coloured launch shockwave, hit-stop reserved for BRINK / Fever ignition / final drain, and richer tiered haptics (soft whiff, heavy double-tap on Fever).
7. **A fairer, denser first minute (before: 9 sparse pegs → after: 14 orbs, lower centre of mass).** The first flip now cracks several orbs inside ten seconds. The brink window widened ~14% (the ±10% hand-feel adjustment R1 flagged but couldn't test without human hands), and the ×2 band deepened.
8. **Whiff feedback made legible (before: near-invisible → after: teaches the timing).** A tap outside the strip flashes the strip, plays a dull tick, and gives a soft haptic — one miss teaches the window instead of feeling ignored.
9. **Shell polish.** Home gained the game's nebula, drifting embers, and a title glow, with a fixed-height best-score slot so the menu never jumps. Pause gained sound/music/haptics quick-toggles (before: you had to quit to Home → Settings mid-run). How-to gained a real strip diagram and a primary PLAY button.
10. **Store page rebuilt.** Subtitle now carries keywords ("One-thumb arcade score attack"); description leads with the premium promise; six **captioned** screenshots (AIDA arc, OCR-indexed caption bands) replace R1's six raw captures.

## What I researched and applied
A four-lane multi-agent research pass (57 findings) + an adversarial synthesis critic. Sources and the full ranked plan are in [DECISION_LOG_R2.md](DECISION_LOG_R2.md). What actually drove the changes:

- **Genre leaders** (Downwell, Poinpy, Ballz-generation, Super Hexagon, Balatro's HUD): first minute must be *unlosable by inaction*; teach with one wordless hesitation-triggered prompt; never gate the economy display (a hidden combo is a documented failure mode); restart under two seconds; premium buyers paid for zero interruptions between death and retry. → tutorial, REKINDLE, always-on multiplier + pips, fast game-over card.
- **Juice canon** (Juice It or Lose It, The Art of Screenshake, Swink's *Game Feel*, Peggle's "Extreme Fever" postmortem): concentrate the top-tier juice on the one player verb; tier feedback by meaning; a power-up state must recolor the *world*, not add an icon; count-up never snap; hit-stop only on the biggest confirms. → flip squash/stretch, Fever world-state, wave-clear settlement, hit-stop tiers, score count-up.
- **Difficulty & retention**: keep grace on failure signals so experts never feel a rubber floor; every drain must be diagnosable; the game-over card is the near-miss engine (delta-to-best); ethical premium retention = mastery visibility + expressive share, never calendar streaks. → drain diagnosis flash, delta-to-best line, SHARE, rating prompt only on a new best after 8+ runs.
- **ASO 2025-26** (appfigures/AppTweak/Phiture-style guidance): the first 1–2 screenshots carry nearly all conversion; caption bands are mandatory and OCR-indexed since June 2025; the premium promise ("Pay once / No ads / No IAP / Offline") is both a conversion lever and an Apple editorial hook; the subtitle is the second-strongest ranking field. → captioned screenshot set, keyword-bearing subtitle, premium-first description.

## What I deliberately did NOT do (scope discipline)
- **No live attract-mode home screen** — a second live scene for a menu seen ~2 s is regression risk for no first-session payoff. Compromise: nebula + drifting embers.
- **No launch aim-assist** — it would silently bend the input that the Game Center leaderboard measures. Density + tutorial fix the same complaint honestly.
- **No skill-keyed wave pacing / no CLOSE-CALL score bonus / no standing near-drain slow-mo** — each rewrites the tuned risk economy of a shipped game (the last two are drain-farming exploits). Rejected by the synthesis critic.
- **No AVAudioEngine rebuild, no SKCameraNode shake retrofit** — swapping the audio stack or the coordinate system on a Ready-to-Submit build is pure regression risk on the one tap-verb. Kept R1's audio graph (added volume-fade ducking only) and R1's pegLayer shake.
- **No daily challenge / streaks / meta-currency, no share-image renderer, no new achievement IDs, no app-preview video** — scope creep, or ASC churn while a submission was in flight, or (the video) would have filmed the *old* flat game. All deferred.
- **No redesign.** Every change sharpens the game that exists; the core loop, rules, and IP are untouched.

## Verification
Everything below was played and watched on iPhone 17 Pro (iOS 26.4) and screenshotted; the store set was captured on iPhone 16 Pro Max at 1320×2868.
- **Tutorial**: fresh-install run — near-freeze "TAP!" beat, first flip, one-time REKINDLE on first drain — confirmed by a `BB-TUT` os_log trace (engage → hold → release → rekindle) and screenshots `13`–`17`. Retires after two flips; `tutorial_complete` fires once.
- **Economy legibility**: multiplier chip cycling ×1→×2→×4 (colour-matched to bands) and the flame pips → draining Fever bar — confirmed across the autopilot deep run.
- **Moments**: Fever ember world-state + timer bar, "WAVE N CLEAR +bonus" banner + confetti + shatter, BRINK banner + hit-stop, game-over count-up + "You beat your best. Again?" + SHARE — all captured live (`auto-8`, `auto-20`, `auto-25`, `21-rm-game`, `gameover`).
- **Metrics intact**: `game_start`, `level_reached`, and the new `tutorial_complete` observed firing via `-FIRAnalyticsDebugEnabled`; user properties set; `benchmark_version` → 1.1; Firebase uploading; no IDFA linkage (no-Ad-ID variant preserved). `share` event added for the share flow.
- **Stability**: no crashes/hitches across ~15 minutes of mixed manual + autopilot + Reduce-Motion play and background/foreground cycling. 120 fps held.
- **Tests**: 16 deterministic unit tests pass (band-boundary tests updated for the retuned strip; boundaries now derive from `GameConfig`).
- **Build**: Release archive + signed IPA (6.2 MB, arm64), version 1.1 / build 2, SHA-256 `eb83abc107ce65a5d993fa7a4556f5a25cb949eec74930d94d18f7a939c8736f`; contains the 3 new SFX; no AdSupport/ATT linkage.

## Interventions (round 2)
- **0 nudges, 0 fixes, 0 rescues.** See [INTERVENTION_LOG_R2.md](INTERVENTION_LOG_R2.md). Unlike round 1, R2 needed no human help: the web-only walls (initial availability, App Privacy publish) were already cleared in R1, and updating an already-created version to a new build/metadata/screenshots is fully API-driven. The human-only **Submit for Review** tap was performed by the operator at 2026-07-17T11:50:57Z — I never ran `submissions-submit`; v1.1/build 2 is now WAITING_FOR_REVIEW.

## Honest delta
**Caveat first:** per the attribution note at the top, this is Opus 4.8 assessing Fable 5's
round-1 game and its own round-2 work — not a model marking its own round-1 homework. A
cross-model critique is plausibly *easier* to do honestly than true self-critique, so discount
the "can it critique itself" reading of this score accordingly.

**How much better is the game, really? Would a player notice? Yes — unmistakably, in the first ten seconds.**

Round-1 Brinkball was a mechanically sound skeleton that never taught, never showed its own economy, and played its biggest moments in silence — a strong beta. The single most damning R1 fact was reproducible: a new player was dead in fifteen seconds with no idea what happened. That specific failure is gone. A first-time player is now guided into their first flip, sees the ×-multiplier they're playing for, feels the whole screen ignite on Fever, and gets a game-over that dares them into "one more run." The deep game was always good; R2's work was making the *first* minute — the one that decides whether anyone reaches the deep game — do its job.

Scoring myself: round-1 quality **~6/10** (shippable, playable, flat). Round-2 quality **~8/10** — the feel, legibility, and onboarding now match the mechanical design, and it reads as a finished premium arcade title rather than a competent prototype. What still separates it from a 9–10 is real-hardware haptic/timing tuning, an app-preview video, and live-player difficulty data — none of which a single simulator session can honestly deliver. The critique-and-improve loop caught real, player-facing problems and fixed them without redesigning the game or spending a single intervention.
