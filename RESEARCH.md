# Research — why Brinkball, and why now

*Produced by a 16-agent research workflow: 4 parallel market researchers (premium charts · viral hooks · solo-shippable archetypes · review risk) → 3 independent concept designers (arcade-first · novelty-first · depth-first) → 9 judge votes (fun / shippable / original per concept). 2026-07-16.*

## Market signals (sourced, July 2026)

1. **Premium mobile is in a real renaissance.** Premium releases jumped 77% in 2025 (~750 titles). Balatro did $21.3M on mobile; the July 2026 US top-paid iPhone chart is owned by run-based score-chasers and "satisfying" arcade titles: Balatro, CloverPit ($4.99), Voidloop ($1.99), Scritchy Scratchy ($6.99), After Inc., with decade-old Geometry Dash still charting — premium arcade has an evergreen tail.
2. **The winning template is precise:** portrait-first, one-thumb, 1–5 minute interruptible runs, "one more run" loop, heavy tactile juice (particles/haptics/rising audio), lo-fi distinctive art, **"pay once, no ads, offline" worn as a badge** — r/iosgaming's most consistent request across 700+ threads.
3. **Portrait-first is a documented gap.** Balatro's single most-requested mobile feature is portrait mode; a "vertical roguelikes" buyer's-guide category now exists. Big premium hits weren't designed vertical; small games that are (Voidloop, Luck be a Landlord) exploit exactly this.
4. **Discovery runs on #oddlysatisfying.** TikTok is the primary channel (60%+ of Gen Z discover games there); what travels is a single 15-second moment with a strong first sound — a peg-cascade with rising pitch is native material.
5. **Apple 4.2 review bar (small games):** rejections hit "demo-feel" apps — one mechanic, no progression, no persistence, no settings/tutorial. What tips a tiny game over: visible progression (waves), persistent best score/stats, **Game Center leaderboard + achievements** (the cheapest credible "lasting entertainment value" signal), a settings screen, how-to-play, pause/resume, and Notes for Review stating the build is native.

## The three concepts and the judge panel

| Concept | Angle | Fun | Shippable | Original | Total |
|---|---|---|---|---|---|
| **Brinkball** — single-flipper pinball-tower, risk-timing multiplier | arcade-first | 7 | **8** | 7 | **22** |
| Counterweight — hanging Calder-mobile balance builder | novelty-first | 7 | 7 | 8 | 22 |
| Pinfall — build-your-own-pachinko peg placement | depth-first | 6 | 8 | 6 | 20 |

**Winner: Brinkball**, on the tie-break against Counterweight:
- **Portfolio differentiation** (a stated goal of this run): Brinkball is real-time arcade action; Counterweight is turn-based calm-chaos — uncomfortably close in *feel* to the prior benchmark game (Ringbloom, a calm puzzle).
- **Physics risk:** Counterweight needs nested SpriteKit pin joints (its own concept flags jitter/explosion risk); Brinkball deliberately avoids jointed bodies — the flipper is a tunable impulse zone, SpriteKit's happiest path.
- **Judge flaw is fixable:** the fun-judge's concern ("player controls only WHEN to flip, never WHERE") is solved in design — the tap point aims the launch (swat toward your thumb), so every tap carries both WHERE (tap position) and WHEN (depth = power + multiplier).

## The bet, in one paragraph

**Brinkball** is a portrait one-thumb arcade score-attack where the scoring multiplier lives in the last inch above the drain: the longer you dare to let the ball fall, the harder it launches and the bigger the multiplier. It sits squarely on the proven mid-2026 template (premium $1.99, no ads/IAP, offline, sub-3-minute runs, juice-forward), fills the documented portrait-first gap, gives TikTok its 15-second slow-mo "BRINK save" moment, and is buildable on SpriteKit physics in one session — with the tuning time going where arcade games earn their money: feel.

**Audience:** score-chasers and premium-arcade buyers (the Downwell/Holedown/Geometry Dash crowd) who want a fair, ad-free skill game for the price of a coffee.

**Why solo-shippable in one session:** one screen, one input verb, no jointed physics, hand-authored wave patterns (not procgen systems), programmatic + AI art, AI SFX; the completeness shell (Game Center, settings, how-to, stats) is boilerplate with known APIs.
