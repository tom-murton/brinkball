# Intervention Log — Round 3 · run folder `20260716-claude-fable-5-ultra` · 2026-07-25

> **Model note:** round 3 (this write-up) ran on **Claude Sonnet 5**, per an explicit operator
> `/model` switch mid-session — not a safety fallback like round 2's Fable-5 → Opus-4.8 switch.
> Round 1 = Claude Fable 5. Round 2 = Claude Opus 4.8. Round 3 = Claude Sonnet 5. All three are
> disclosed in the published article. See the article's "The honest part" section for the full
> account, including a fourth episode (the GitHub secret-exposure and repo merge) that happened
> in this same long-running session, under Sonnet 5, between round 2's close and this round's
> formal start — and is disclosed in full in the article even though it predates this round's
> brief and is therefore not counted in the tally below.

## Scored interventions
| # | Time | Phase | Type | Severity | What happened | Artifact / file |
|---|------|-------|------|----------|---------------|-----------------|

**None.** Round 3 (reading the source logs, recomputing every score field from primary sources,
checking live App Store Connect / App Store state, writing the article, and verifying the build)
required no human help. The operator's messages in this round were the original task brief only.

## What "recompute, don't trust" actually found
- **Round 1 tally**: recounted the scored-interventions table in `INTERVENTION_LOG.md` row by
  row — 2 rows, both nudges, 0 fixes, 0 rescues. Matches the file's own Tally line and matches
  what was already published in `benchmarks.ts`. Confirmed, not corrected.
- **Round 2 tally**: recounted the scored-interventions table in `INTERVENTION_LOG_R2.md` — 0
  rows. Matches the file's own Tally line and matches what was already published. Confirmed, not
  corrected.
- **Apple review state**: the published entry said `"in-review"`. Live `asc status` +
  `asc review history --app 6791686352` right now show exactly one review submission, outcome
  `"approved"`, version state `READY_FOR_DISTRIBUTION`, and the public App Store page at
  `https://apps.apple.com/gb/app/brinkball/id6791686352` actually renders the live v1.1 listing.
  **This was stale and has been corrected** to `appleReview.outcome: "approved-first-pass"`,
  `status: "shipped"`, `statusLabel: "Live on the App Store"`.
- **`playUrl`**: the published entry set `playUrl` to the GitHub Pages support/privacy site. The
  page component labels that field "Play the web build" — Brinkball has no web build, so that
  was a real (if minor) inaccuracy in the UI text. Replaced with a generic `links` entry labelled
  honestly ("Source + support site on GitHub"), pointing at the same merged repo.
- **`price`**: not previously set. Confirmed live via `asc pricing current` for both US and GB
  territories: $1.99 / £1.99.
- **`buildStats.hours` / `costUsd`**: left unset. Round 1's timestamps span ~14.5 hours but ~13
  of those are the model idle waiting on the operator's app-record creation (an expected
  human-only step, not build time); reporting the wall-clock span would misrepresent someone
  else's wait as build time. Neither round recorded token spend or generation-credit cost. This
  mirrors the sibling Ringbloom entry's same reasoning and same choice to leave the fields unset
  rather than estimate.
- **`quality` / `reception`**: not touched, per the rule that the model that built the game never
  self-scores these.

## Verification
- `npm run build` in `personal-cv`: passed clean, no type errors (vite build + route-html
  generation both succeeded).
- `npx eslint src/content/benchmarks.ts`: no errors.
- `npm run dev` + live render check at `http://localhost:8080/projects/ship-a-game/brinkball`:
  confirmed every scoreboard field (autonomy 90/100, round 2 100/100, round 3 100/100, status,
  Apple outcome, price, links) and the full article body (all `h2`/paragraph/`quote` blocks,
  including the closing quote) render correctly. Also checked the hub page at
  `/projects/ship-a-game` to confirm the scoreboard row picks up the same data.
- Dev server stopped after verification.

## Tally
nudges: 0  fixes: 0  rescues: 0

Round 3 is a one-shot: 100/100. The `BenchmarkGame` entry for `brinkball` in
`src/content/benchmarks.ts` is complete, `reviewPending` has been removed, and the build/render
are verified. Left uncommitted in the `personal-cv` repo for Tom to review and push.
