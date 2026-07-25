# Store Plan — prep notes (gathered during research phase)

## Account facts (verified live)
- Team ID: `5R8P82H779` · Apple Distribution cert in keychain `04C86CDBD9F8833B408645D0E09CC59384EA23BC`, ASC cert `2KXKSHHY36` (DISTRIBUTION, expires 2026-11-09). Signing healthy.
- Bundle ID convention: `com.tommurton.<game>` (SKU = same), primary locale `en-GB`.
- Review contact (account-owned, from Ringbloom/Warden): Tom Murton · +447957357194 · shopping@tommurton.com.
- Firebase project `ship-a-game-benchmark` visible to authed `firebase` CLI (14.22.0).
- Benchmark site live: https://shipagame.weevolve.app/ (200). Prior run used a GitHub Pages support+privacy site — `gh` CLI authed as tom-murton; same pattern planned.

## Known traps (from prior run's logs)
1. `whatsNew` is invalid for a first version — do not set it.
2. `PrivacyInfo.xcprivacy` required-reason manifest needed (UserDefaults → `CA92.1`). Firebase SDK ships its own manifests; mine must cover my own API use.
3. Screenshots: 1284×2778 (APP_IPHONE_65) validated clean last run; validate with `asc screenshots validate` before upload.
4. XcodeGen traps: (a) explicit `INFOPLIST_FILE` must stay owned or launch plist gets replaced → letterboxing; (b) resources must be in target sources list or icon/audio get dropped from the bundle. Audit the built IPA payload.
5. First-version blockers seen last run: review contact phone (solved above), **initial territory availability** and **App Privacy publication** — both web-session-only.

## Web-only risk + self-unblock plan
- `asc web auth status` → NOT authenticated (2026-07-16 preflight).
- Plan A: drive the user's real Chrome (existing logged-in ASC session) for the two web-only steps — no credentials entered by me.
- Plan B: `asc web privacy plan/apply` + `asc web apps availability create` if a web session becomes available.
- Plan C (last resort): log a `nudge` intervention like the prior run.
- App Privacy content (per METRICS-SPEC, Firebase Analytics + Crashlytics): declare **Usage Data** + **Identifiers**, purpose Analytics/App Functionality, NOT linked to identity, NOT used for tracking. No IDFA/ATT.

## Pricing
- Paid upfront US $1.99 (benchmark default), manual release, copyright `2026 Tom Murton`.

## State (2026-07-16 evening)
- ✅ Bundle ID `FTZ8NMVLP4` + GAME_CENTER capability; profile `4583CLX8MV` (Brinkball App Store) created + installed.
- ✅ Firebase app `1:466650279130:ios:245a2d192053f2a1e449e3`; events verified uploading (204).
- ✅ Signed IPA at `build/export/Brinkball.ipa` (6.5 MB, arm64, strict codesign OK, payload audited: 9 SFX, 3 fonts, Assets.car, GSI plist, privacy manifest, encryption=false, GC entitlement).
- ✅ 6 screenshots at 1320×2868 in `screenshots/final/`.
- ✅ Metadata drafted in `metadata/` (app-info + version 1.0 + privacy.json).
- ⏳ App record: spec emitted; polling `asc apps list`.
- ⏳ Support site: files ready in scratchpad/brinkball-site; `gh repo create --public` blocked by harness permission — operator to create repo `brinkball` (or approve) then I push + enable Pages.

## Game Center config (run the moment the app record exists; APP_ID = new app's ASC id)
```
asc game-center enable --app APP_ID   # or detail create — check `asc game-center --help`
# Leaderboard: id brinkball.best, name "Brinkball — Best Score", INTEGER, best=highest
# Achievements (100pts split, all visible):
#   brinkball.ach.firstbrink "On the Brink"      — first ×4 BRINK flip
#   brinkball.ach.wave5      "Wave Rider"        — reach wave 5
#   brinkball.ach.wave10     "Deep Descent"      — reach wave 10
#   brinkball.ach.pegs100    "Century Popper"    — 100 orbs in one run
#   brinkball.ach.fever      "Fever Pitch"       — ignite Fever
#   brinkball.ach.score25k   "Quarter Legend"    — score 25,000
```

## Remaining store checklist (post-record)
1. Push metadata (`asc metadata apply` or localizations update) — NO whatsNew on v1.0.
2. Upload icon? (in binary via asset catalog — not needed separately)
3. `asc screenshots upload` from screenshots/final (validate first).
4. Pricing $1.99 US base (`asc pricing schedule create`), availability: needs web/bootstrap — try `asc web apps availability create`, else Chrome-session route, else nudge.
5. Age rating: all "none" questionnaire.
6. Review details: contact Tom Murton +447957357194 shopping@tommurton.com; notes incl. native SpriteKit build + Game Center + how to play; demo account: none needed.
7. App Privacy publish (web-only — same fallback ladder as availability).
8. Game Center leaderboard+achievements config + attach to version.
9. `asc builds upload` the IPA, wait VALID, attach to version 1.0.
10. `asc validate` / `asc review doctor` → clear blockers → stage submission → READY_FOR_REVIEW state, stop before Submit.
