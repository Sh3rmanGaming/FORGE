# NOW — Forge

_Overwritten at the end of every session by `journal-session`. History lives in `journal/`._

## State (31 Oct 2026)
- Roadmap runs in broad test rounds with no freezing. Round 1 = PF.005 retest + PF.006 (notification banners, toasts, sounds, tap-to-open). Round 2 = PF.007-PF.009 (not authorised). Round 3 = M4.
- PF.005 badge mirror and PF.006 core behaviour seen working in the game. First-run fixes are in verification package `PF.006c`, built and deployed (hash verified).
- `PF.006c` code is committed and pushed (`85f2864`). The guided run is now short: 3 screenshots, a sound audition and a per-severity sound step.

## Next step
User runs `PF.006c`: Ctrl+N once, F12 at each yellow prompt (04, 08, 10), note audition sound names, don't press Ctrl+N after "finished", save/quit/reload, F12 on Phone home. Then read log and screenshots, set the sound mapping, write `docs/reviews/PF.006RuntimeVerification.md`, ask for acceptance.

## Open questions
- Which base-game sound per severity (from the audition).
- Keep the dev-only input actions out of the operational `modDesc.xml`?
- Older process docs still say "frozen"; `M2M3PresentationFoundationImplementationPlan.md` needs aligning to the rounds; empty `assets/`, `campaigns/`, `sdk/`, `themes/` folders: keep or remove.

Latest journal: `journal/2026-10-31-2135-pf006c-second-run-prep.md`
