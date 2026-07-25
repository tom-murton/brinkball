# Intervention Log — Round 2 · run folder `20260716-claude-fable-5-ultra` · 2026-07-17

> **Model note (not an intervention):** round 2 executed on **Claude Opus 4.8**, not Fable 5 —
> Fable 5's safeguards flagged a message and the harness fell back to Opus 4.8. This is a
> platform/model-routing event, not human help, so it is **not scored** here. It does change how
> round 2 should be read (cross-model critique, not self-critique) and it forced a correction to
> the public App Store description. Full detail in IMPROVEMENT_REPORT.md and DECISION_LOG_R2.md.
>
> The operator also surfaced the fallback to me in-session. That is **reporting a fact about the
> harness**, not unblocking a task I was stuck on — no decision, command, or content came from
> the human — so it is likewise not scored. Recorded here for transparency; a stricter reading
> could count it as a nudge, and the operator should feel free to score it as one.

## Scored interventions
| # | Time | Phase | Type | Severity | What happened | Artifact / file |
|---|------|-------|------|----------|---------------|-----------------|

**None.** Round 2 required zero human help.

## Why round 2 needed no interventions (where round 1 needed 2)
Round 1 spent two nudges on structural platform/harness walls:
1. Creating the public support-site GitHub repo (harness auto-mode classifier blocked public-repo creation).
2. The two web-session-only App Store Connect screens — initial territory availability and App Privacy publication — which have no public API.

Both were **one-time bootstraps that persist on the app record**. In round 2:
- The support/privacy site already exists (github.com/tom-murton/brinkball, Pages live) — no repo creation needed.
- Territory availability (all 175) and the App Privacy questionnaire were already published in R1 and carry forward to v1.1 — no web session needed.
- Everything R2 changed — new build upload, version rename 1.0→1.1, build attach, metadata/keywords/subtitle/promo update, screenshot replace, review-item management, validation — is fully covered by the public `asc` CLI / App Store Connect API. No credentials were ever mine to enter, and none were needed.

The only self-unblock that could have looked like a wall — R1's prepared review submission being stuck in a non-cancellable state — was resolved entirely through the public API (`asc review items-remove` to return the version to editable), with no human action.

## Expected human-only steps (NOT scored)
- [x] Accept Apple agreements — none pending (ASC validation clean).
- [x] Banking / tax — in place (account ships paid apps).
- [x] Create the App Store app record — done in R1 (`6791686352`); R2 reuses it.
- [x] Initial territory availability + App Privacy publication — done in R1, carry forward.
- [x] **Final "Submit for Review" tap (round-2 build 1.1 / build 2)** — performed by the human (operator) at 2026-07-17T11:50:57Z. I never ran `submissions-submit`; the human-only boundary was respected.

## Tally
nudges: 0  fixes: 0  rescues: 0

Round-2 definition of done (**"Ready to Submit"**) was reached: App Store version **1.1** (build **2**, VALID, attached) and its review submission both **READY_FOR_REVIEW**, zero blockers. The operator then tapped **Submit for Review** (2026-07-17T11:50:57Z), so the version is now **WAITING_FOR_REVIEW**. The improved build (v1.1/build 2) is what went to review, carrying the corrected model attribution.
