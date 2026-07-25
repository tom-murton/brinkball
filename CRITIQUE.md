# CRITIQUE — Brinkball v1.0, reviewed cold (Round 2, 2026-07-17)

Reviewed as a stranger: fresh install on iPhone 17 Pro sim (iOS 26.4), played blind
(no code knowledge assumed), then confirmed against the code. Evidence in
`screenshots/r2-play/`.

## Verdict in one line
A mechanically sound, honest little arcade game with a genuinely clever greed economy —
that **never teaches you it exists**, keeps its own core stat invisible, and plays its
biggest moments (Fever, wave clear, new best) with almost no ceremony. It feels like the
strong beta of a good game, not the good game.

## 1 · First 60 seconds — FAIL, and it's the biggest problem
- **Reproduced live:** installed fresh, tapped PLAY, then watched as a confused new
  player would. The run ENDED (~15 s, score 40, all 3 balls) before I did anything
  meaningful. No hint ever appeared. (`03-open.png` — a "NEW BEST! 40" over a game I
  never understood.)
- There is **zero onboarding**: no first-serve "TAP TO FLIP" cue, no strip highlight, no
  arrow, nothing. The tutorial lives behind a menu button ("HOW TO PLAY") that a store
  buyer will not tap first — and it's three paragraphs of text (show-don't-tell is the
  genre convention; nobody reads).
- Tapping while the ball is high gives a whiff ring so faint (`04-masher-mid.png`,
  centre) it reads as a rendering artifact, not as "not yet — wait for the strip."
  A new player's first 5 taps feel *ignored*.
- The do-nothing path is brutal: serve → drain is ~4 s; three drains in ~15 s. Fine for
  Flappy-class games that restart instantly and TEACH via death — but Brinkball's death
  screen doesn't tell you what you did wrong either.

## 2 · Core-economy legibility — the multiplier is invisible
- The entire game is "which band did you flip from" — yet **the current multiplier is
  displayed nowhere**. HUD shows score / wave / balls / (post-first-brink) fever bar.
  You cannot see that your ×4 is armed, or that it reset to ×1 after re-entering the strip.
- Fever meter is invisible until the first brink flip banks a tick (`feverProgress > 0`
  gate), so the mechanic that structures expert play doesn't exist for beginners.
- Band labels ×1/×2/×4 are dim static wallpaper at mid-right; nothing pulses when the
  ball is actually falling toward them, so the "how deep dare I go" tension — the pitch
  of the whole game — has no visual heartbeat.

## 3 · Game feel ("juice") — competent floor, missing ceiling
Good: peg-pop particles + rising-pitch dings + tiered haptics + brink slow-mo/flash are
all real and working. The ember trail sells the ball.
Missing, in impact order:
- **Fever is a non-event visually.** 10 s of double score and the playfield looks
  *identical* (R1's own store screenshot proves it: `final/3-fever-strip.png` needed a
  HUD badge to be identifiable at all). No bloom, no background shift, no particle rain,
  no music layer change.
- **Wave clear = one floating label.** Design doc promised confetti; there is none. The
  single most repeatable milestone in the loop has no celebration arc.
- **Flip has no body.** No launch shockwave, no squash/stretch on the ball, no
  band-coloured burst at the flip point. ×1 flip and ×4 flip differ only in sound +
  slow-mo; the launch itself looks the same.
- **No hit-stop.** Armored-peg thunk and brink flip would land far harder with 30-60 ms
  of freeze.
- **Score is static.** Game-over score just *appears* (no count-up); HUD score has
  numericText transition but milestone deltas (wave bonus +1400) fly by as one label.
- **Combo is audio-only.** The rising pitch is lovely but there's no visible streak
  counter; at combo 5+ a tiny "+points" label appears, which undersells cascades.
- **New best** gets a teal title on the card — no moment, no haptic celebration, and
  "NEW BEST! 40" on a first bumbling run is unearned bathos.

## 4 · Difficulty curve
- Wave 1 is 9 pegs, sparse, high up — a *mash-tester* (48 taps) earned 70 points in
  ~40 s of wave 1 (`04-masher-*.png`). The first minute is the emptiest, slowest,
  lowest-scoring part of the game. Exactly backwards for retention.
- Early-wave sparseness also means few peg bounces per flight → long boring flights up
  and back. Density (and therefore cascade feedback) only arrives around wave 4+.
- Deep game (autopilot, waves 4-10+) is genuinely engaging: armored orbs, tighter
  patterns, strip-speed ramp. The game's fun is real — it's just gated behind a first
  minute that sheds players.
- 3 balls with zero grace for the true first run is harsh; dying with no understanding
  converts nobody.

## 5 · UI/UX
- Home: clean but inert — bottom half of the screen is empty (`02-home-clean.png`); no
  nebula, no motion, nothing of the game's character. It looks like a settings app.
- Menu buttons shift vertically once a best score exists (layout jump between visits).
- HOW TO PLAY's "GOT IT" returns to Home instead of offering PLAY — friction exactly
  where motivation peaks.
- Game-over card blocks the entire playfield instantly at 0.45 s; you never see the
  board state that killed you.
- Pause/resume, background auto-pause, settings toggles, VoiceOver labels, Dynamic Type
  caps: all present and working (R1 did this well).
- Pause menu has no sound/haptics access — you must quit to Home → Settings mid-run to
  mute (`09-pause.png`).
- The ball can fly behind the HUD cluster (pause button / ball dots) at the top right
  (`06-auto-40s.png`) — cosmetic, but reads as sloppiness in the one corner the eye visits.
- No safe-area issues found on 17 Pro; portrait-only correctly declared.

## 6 · Retention hooks
- Present: best score + lifetime stats, Game Center board + 6 achievements, instant replay.
- Missing: **score share** (spec even reserves a `share` event; zero social surface
  exists), any near-miss framing ("142 from your best"), and any reason to come back
  tomorrow beyond self-motivation. For a premium no-manipulation game, share + delta-to-best
  are the ethical hooks — and both are cheap.

## 7 · Store presence
- Screenshots are 6 raw captures, no captions, no framing; the "action" hero is mostly
  empty dark nebula (`final/1-action-waveclear.png`). A browser learns nothing in 2
  screenshots (the ones that matter).
- Icon: strong. Metadata copy: genuinely good. Subtitle fine.

## 8 · Stability
- No crashes, hitches, or memory growth observed across ~10 minutes of mixed
  play/mash/autopilot. 120 fps SpriteView holds. R1's interruption/auto-unpause
  hardening appears solid. Not the problem.

## Priority list (what would actually move a player's experience)
1. **Teach the game in-game** (first-run cues; show-don't-tell; death-screen hint).
2. **Make the economy visible** (multiplier in HUD; band pulse under falling ball;
   fever meter always present).
3. **Pay off the moments** (fever state change, wave-clear celebration, flip launch
   feedback per band, brink hit-stop, game-over count-up + near-miss line).
4. **Fix the first minute's pacing** (denser wave 1-2, first-run grace ball).
5. **Add the share hook** (game-over share + `share` event).
6. **Sell it** (captioned screenshots, hero moments staged).
