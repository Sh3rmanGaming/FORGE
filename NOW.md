# NOW — Forge

_Overwritten at the end of every session by `journal-session`. History lives in `journal/`._

## State (31 Oct 2026)
- Roadmap runs in broad test rounds with no freezing. Round 1 = PF.005 retest + PF.006 (notification banners, toasts, sounds, tap-to-open). Round 2 = PF.007-PF.009 (not authorised). Round 3 = M4.
- PF.005 badge mirror and PF.006 core behaviour seen working in the game. Fixes from that test are built and deployed as verification package `PF.006b` (Back after a tap, app-name label, 10 s banners, toast position, sound fallbacks, Ctrl+N guided test run, Ctrl+M test message).
- `PF.006b` has not been run by the user yet. The PF.006 work (about 41 files, 16 new) is uncommitted; last commit is `a9999b7`. Nothing pushed since.

## Next step
User runs `PF.006b` (Ctrl+N once, listen to the five sounds, save/quit/reload, screenshot Phone home). Then read log and screenshots, write `docs/reviews/PF.006RuntimeVerification.md`, ask for acceptance.

## Open questions
- Does the game have a usable screenshot call for the guided run (falls back to prompting)?
- Which base-game sounds per severity (the log lists what exists).
- Keep the dev-only input actions out of the operational `modDesc.xml`?
- Commit the PF.006 work: one commit proposed, ask first; no push until told.
- Older process docs still say "frozen"; `M2M3PresentationFoundationImplementationPlan.md` needs aligning to the rounds; empty `assets/`, `campaigns/`, `sdk/`, `themes/` folders: keep or remove.

Latest journal: `journal/2026-10-31-1305-forge-onboarding-and-pf006-test-round.md`
