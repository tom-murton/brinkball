# Intervention Log — Claude Fable 5 Ultra · 2026-07-16

## Scored interventions
| # | Time | Phase | Type | Severity | What happened | Artifact / file |
|---|------|-------|------|----------|---------------|-----------------|
| 1 | 2026-07-16 ~19:20 | store | store-config | nudge | The harness's auto-mode permission classifier hard-blocked creating the public GitHub repo for the required support/privacy site (`gh repo create brinkball --public`), including after in-chat approval. The operator enabled bypass-permissions mode; I then created/pushed the repo and enabled Pages myself. No content, commands, or decisions were authored by the human — this was a harness-policy unblock, but it was human help, so it is scored. | scratchpad/brinkball-site → github.com/tom-murton/brinkball |
| 2 | 2026-07-16 ~21:05 | store | store-config | nudge | Initial territory availability + App Privacy publication have no public API (Apple web-session only; prior run hit the same wall). My asc web session was expired and re-login requires the account holder's Apple ID credentials, which are never mine to enter. The operator signed in to appstoreconnect.apple.com in Chrome; I then drove both screens myself through the authenticated session (availability: all 175 territories; App Privacy: 4 data types with purposes/not-linked/no-tracking + Publish). The human performed only the sign-in. | ASC app 6791686352 availability + App Privacy |

## Expected human-only steps (NOT scored)
- [ ] Accept Apple Developer agreements (none pending as far as ASC validation shows)
- [ ] Banking / tax setup (existing paid apps ship on this account; assumed in place)
- [x] **Create the App Store app record — SPEC (emitted 2026-07-16 ~06:40; record `6791686352` appeared ~19:45):**
  - **Name:** `Brinkball`
  - **Bundle ID:** `com.tommurton.brinkball` (already registered: `FTZ8NMVLP4`, Game Center capability enabled)
  - **SKU:** `com.tommurton.brinkball`
  - **Primary language:** English (U.K.)
  - **Price:** paid upfront, US $1.99 base
  - I poll `asc apps list` and continue automatically once the record exists.
- [ ] Final "Submit for Review" tap

## Tally
nudges: 2  fixes: 0  rescues: 0

Final state achieved 2026-07-16 ~21:15: version 1.0 and review submission both READY_FOR_REVIEW; ASC reports "Submit the prepared review submission" as the sole next action — the human-only Submit tap.
