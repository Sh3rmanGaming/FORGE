---
type: journal
date: 2026-10-31 21:35
workspace: forge
tool: claude-code
title: PF.006b first-run results and the PF.006c build for the second test run
---

# PF.006b first-run results and the PF.006c build for the second test run

Follows `journal/2026-10-31-1305-forge-onboarding-and-pf006-test-round.md`.

## Goal
- Read the user's run of `PF.006b`, fix what it showed, and shorten the second
  run so the user only repeats what still needs testing.

## What happened
1. The user ran the guided run (Ctrl+N). The game has no usable screenshot call
   (`saveScreenshot` / `takeScreenshot` probe failed), so the user took the
   screenshots with F12 (Steam folder, `YYYYMMDDHHMMSS_1.jpg`). I matched them
   to steps by the log's `SNAP` timestamps.
2. Findings from the run:
   - Sound logging crashed after a stop/clear/start cycle: "attempt to index
     boolean with 'information'". Cause: `clearRuntimeState` reset
     `soundOutcomeReported` to `false` instead of `{}`.
   - Pressing Ctrl+N after the run finished (or during it) restarted or skipped
     the run.
   - Banner text of an open Phone showed through the banner: FS25 draws text
     above every filled panel regardless of draw order, so overlaps must be
     avoided by placement.
   - Step 8 did not tap a real message toast.
   - The user heard only 3 sounds (a harmonica, then two engine/step-like
     ones), but their game audio had been turned down, so the sound result is
     unreliable.
3. Built `PF.006c`:
   - Fixed the sound-outcome reset; added a regression test (verified to fail
     on the old code and pass on the fix).
   - Banner now sits below an open Phone (top of screen when closed); Laptop
     toast moves left of an open Phone. New `View:setAnchor`.
   - Guided run reduced to the steps still needed: 04 banner with Phone open,
     08 tap a real message toast on the Laptop, 10 both devices, a sound
     audition (all 31 base-game interface samples, 1.5 s apart, name on screen
     and in the log) and a per-severity sound step. `forgeTestRunAll` runs
     every step. Extra key presses are ignored.
   - Deployed verification build; mods-folder hash matched the verification
     zip (`FA7FAF0B...8B61`); operational zip `1000056B...1A87F`; previous
     deployment archived in `_builds\deployed-backups\`.
4. At the user's request committed (`85f2864`) and pushed the PF.006c work.

## Completed / verified
- In the Lua VM (lupa, Lua 5.1): banner and toast positions (Phone open: banner
  y 0.0736 below the Phone; both open: toast x 0.455 left of the Phone; Laptop
  alone x 0.74; Phone closed: banner y 0.79); guided run of 5 steps with 3
  SNAPs then finish.
- Gates: `sync.py --check` (143 identical, 0 divergent), `check_test_order.py`,
  12 tool unit tests; only the 6 known out-of-game harness failures.
- NOT verified in the game: `PF.006c` itself; which sample suits each severity;
  Phone home after reload (never screenshotted).

## Decisions
- Second run covers only retest steps plus sound audition (user's request).
- Placement, not draw order, resolves text overlap.
- Commit and push of PF.006c approved by the user.

## Problems and corrections
- `soundOutcomeReported = false` bug (above).
- Earlier journal said the profile "may need updating" about OneDrive. Wrong:
  the profile is correct. There is no OneDrive on this machine; the name is a
  leftover in folder paths. A memory note records this.
- Earlier shell issues repeated: CRLF from Python on LF files (fixed with
  `newline='\n'`), a bash heredoc quoting failure.

## Understanding checks
- None new this segment beyond the OneDrive correction above.

## Boundary crossings
- Deployed `PF.006c` to the mods folder (previous archived) as the established
  test-handoff step.
- Dev-only input actions still declared in the shipped `modDesc.xml`; decision
  pending.
- Second Brain `pipelines/ui-mockups` files remain uncommitted there.

## Discoveries and lessons
- FS25 text always draws above panels; avoid overlap by layout.
- The game has no screenshot Lua call; F12 plus timestamp matching works.
- A key that restarts a run needs a guard once the run is finished.

## Skills practised
- Running the test, taking F12 screenshots, deciding scope of the retest, and
  approving the build and commit: user.
- Code, tests, build, deploy, log and screenshot analysis: AI.

## Unresolved
- Sound names per severity (from the audition).
- Phone home after reload.
- Keep dev-only actions out of the operational `modDesc.xml`?
- Older process docs still say "frozen"; `M2M3PresentationFoundationImplementationPlan.md`
  not aligned to rounds; empty `assets/`, `campaigns/`, `sdk/`, `themes/`.
- Round 2 not authorised; "Laptop presentation model acquisition failed" log
  spam belongs there.

## Resume here
User runs `PF.006c`: Ctrl+N once, F12 at each yellow prompt (3 shots), note the
audition sound names, do not press Ctrl+N after "finished", save/quit/reload,
screenshot Phone home. Then read log and screenshots, set the sound mapping,
write `docs/reviews/PF.006RuntimeVerification.md` and ask for acceptance.
