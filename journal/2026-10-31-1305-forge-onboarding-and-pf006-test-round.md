---
type: journal
date: 2026-10-31 13:05
workspace: forge
tool: claude-code
title: Forge onboarding, roadmap reset to test rounds, and the PF.006 notification build and first test
---

# Forge onboarding, roadmap reset to test rounds, and the PF.006 notification build and first test

First journal entry for Forge. It covers the restart and tidy-up of the project
(30 Oct) as well as the PF.005/PF.006 work that followed (30-31 Oct). The
onboarding part is reconstructed from the git history and `NOW.md`, because it
happened in earlier context windows of the same long session.

## Goal
- Restart Forge (a public, open-source Farming Simulator 25 gameplay framework
  in Lua: an Engine plus ForgeOS, the in-game Phone and Laptop) after a pause
  since 30 Aug 2026, and bring the repo and process into a state both Claude and
  Codex can work in.
- Then deliver the next feature work (PF.005 attention badges, PF.006
  notification banners/toasts/sound/tap-to-open) with as little repeat testing
  by the user as possible.

## What happened

### Part 1 - Onboarding and repo rectification (30 Oct)
1. Resumed from `docs/reviews/PresentationFoundationPauseHandoff.md`. State on
   restart: M1-M3 complete; Presentation Foundation PF.001-PF.004 implemented,
   verified, accepted; PF.005-PF.009 not authorised; M4.001 paused.
2. Committed the accepted PF.001-PF.004 work (`ca899c9`).
3. Tidied the repo: filed runtime evidence under `docs/reviews/evidence/`,
   stopped tracking build zips (`93579d8`), stored evidence byte-for-byte
   (`a157dc8`).
4. Added session routing: `NOW.md` handoff, `commands.md` key phrases, journal
   folder (`d79032c`). Rewrote `AGENTS.md` as a short routing guide: the user
   decides, plan first beyond small fixes, no separate roles (`e4ebb20`).
5. Brought the Roadmap and CHANGELOG up to date with PF.004 (`81a9171`).
6. Wrote the PF.005 plan against what the code really contained, then revised
   it twice (`4812f93`, `fe17a53`), including permission for generated badge
   assets.

### Part 2 - PF.005 attention badges (30 Oct)
- Generated badge assets (`809a5a7`) and projected application attention onto
  the Phone and Laptop launcher badges (`813b658`).
- Built `tools/package_runtime.py` to build the operational and verification
  zips and deploy the verification one to the game's mods folder, archiving the
  previous deployment (`024bf58`).
- First in-game look. The user's feedback on badge layout: keep the count where
  it is, but put the state shape (triangle) on the opposite corner, mirrored to
  whichever side the count is on. Built and committed (`509d8a5`).
- The user found the game's developer mode takes F8, hiding the Laptop; the
  Laptop was then opened with Ctrl+L for the rest of testing.

### Part 3 - Roadmap reset and Round 1 plan (30 Oct)
- The user judged the roadmap sections too small: every small batch costs
  their screenshots and testing time. They asked for broader tests, and for
  freezing to be dropped (frozen decisions had repeatedly needed an authorised
  un-freeze to fix things understood only later).
- Roadmap regrouped into test rounds (`84ce88b`): Round 1 = PF.005 retest +
  PF.006; Round 2 = PF.007-PF.009; Round 3 = M4 as essentially one round; M5-M9
  to be planned the same way.
- Wrote the Round 1 plan with four decisions D1-D4 (`a9999b7`); the user
  approved all four recommendations. Banner/toast sizes and timings were agreed
  on rendered mockups (Pillow). The mockup helper was put in the Second Brain
  as a shared kit so other projects can use it.

### Part 4 - PF.006 build and test (30-31 Oct)
- Built: route parameter schema (ADR-008), notification activation service
  (open -> activate -> navigate -> mark read, stop on first failure), cue
  coordinator (one sound per notification, bounded queues), cue view, Phone
  banner, Laptop toast, dev-only console fixtures. About 41 files changed, 16
  new. All new harnesses pass in the in-game dev suite.
- Built and deployed verification package `PF.006`. The user ran it and took 9
  screenshots; I read them with the live log.
- Findings: banners/toasts/stack/expiry/tap-to-open and the PF.005 mirrored
  badges all work. Two real problems: (1) Back fails after tapping a banner
  (`routeNotFound` in the log: the deep link left no earlier screen); (2) the
  source label showed a raw id (`FORGE.COMMUNICATIONS`). Smaller: toasts
  overlapped the bottom bar, the Phone banner duplicated a Laptop toast, the
  "success" sound sample was silent.
- Fixed all of them and built `PF.006b` (deployed, hash verified): deep links
  now seed the app's default route so Back works; labels use the app display
  name; Phone banner yields while the Laptop is open; toasts raised; banners
  and toasts last 10 s; sound tries several base-game sample names and logs the
  ones that exist.
- At the user's request added dev shortcuts: Ctrl+M (test message) and Ctrl+N
  (a guided test run that triggers each scenario and tries to take the
  screenshots itself, or prompts the user to).

## Completed / verified
- PF.001-PF.004 accepted earlier; PF.005 badge mirror seen working in the game
  (screenshots `201920`, `201938`, laptop `202300` onward).
- PF.006 core behaviour seen working in the game: Phone banner over gameplay,
  waiting count, Laptop toast stack capped at 3, expiry, tap opens the right
  message, broken destination fails safely in preflight with nothing opened
  (log: "validationFailed after stage none"), save and reload loaded cleanly.
- Gates before each build: `sync.py --check`, `check_test_order.py`, 12 tool
  tests, package validation; Lua harnesses run outside the game (lupa/Lua 5.1).
  Six harnesses fail only outside the game because they need FS25 globals; they
  pass in the game.
- Guided test run exercised end to end in the Lua VM.
- NOT verified: `PF.006b` in the game (the user has not run it yet); whether
  the game has a usable screenshot call; sounds for any severity other than
  "information" (CLICK works; "success" was silent); banner while the Phone is
  open, Laptop toast tap, both devices together, Phone home after reload.

## Decisions
- Test in broad rounds, not small batches - the user's time is the scarce
  resource. Recorded in `docs/roadmap/Roadmap.md`.
- No freezing; accepted work may be changed later without an un-freeze
  approval (user's decision; older process docs still say "frozen").
- D1-D4 (Round 1 plan): Phone banner also shows over gameplay while the Phone
  is closed; placeholder base-game sounds; the agreed sizes and timings; cues
  can only be tapped in pointer mode (F6). Recorded in `Round1Plan.md`.
- Mirrored badge layout (count stays, shape goes to the opposite corner).
- Deep link seeds the default route beneath its destination (recommended by me,
  accepted by the user).
- Banners and toasts last 10 s so a screenshot is feasible by hand.
- Phone banner yields while the Laptop is open (my recommendation, accepted).
- Dev shortcuts and the guided run exist only in the verification build.
- No commit or push without a yes; the repo is public.

## Problems and corrections
- Mirror test used the wrong painter field (`width`, not `w`); fixed.
- Several tests needed fixes while writing them (cue lookup order, pill drawn
  before the title, a Laptop route lacking a schema, a Phone test resetting
  labels).
- The game's developer mode binds F8, which hid the Laptop in the first test.
- Back after a deep link had nothing to return to (found from the log, not from
  a screenshot).
- A bash heredoc broke on quoting; the code was written to a file and spliced
  instead.
- Python edits wrote Windows line endings into LF files; converted back and the
  sync check re-run.
- The "Laptop presentation model acquisition failed: no model" warning repeats
  (130 lines this run). Not caused by PF.006; belongs to Round 2.

## Understanding checks
- I said 25 tracked files had changed and "6 commits ahead"; the second was 5.
  Corrected during the session.
- I told the user the banner's grey-blue fill matched the Phone's panels. It
  matches the Phone's buttons (the game brightens the colour), not the darker
  panel body. Left as is; the user can ask for a darker fill.
- The user's reading of the Back failures: they pressed Back twice because they
  did not understand the first result, then Home. So the log's two errors were
  not two distinct faults.

## Boundary crossings
- I deployed verification builds `PF.006` and `PF.006b` into the game's mods
  folder (old build archived each time) without a separate ask each time, as
  the established workflow for a test handoff.
- The two new dev input actions are declared in `modDesc.xml`, which ships in
  the operational build too; they are only registered (and bound to keys) in
  development verification builds. Worth a deliberate decision on whether the
  operational modDesc should omit them.
- The shared mockup kit lives in the Second Brain repo, uncommitted. Created at
  the user's request; not committed.
- Memory files were added for this project (public repo, broad test batches, no
  freezing, mockup kit, handoff screenshots).
- Nothing from PF.006 or PF.006b is committed or pushed.

## Discoveries and lessons
- The log is often a better test oracle than screenshots (it showed the Back
  failure and proved the broken-destination path).
- Make test rounds hands-off: a scripted run with screenshot prompts saves the
  user far more time than extra test fixtures.
- Short-lived UI is hard to capture by hand; give it enough time or script it.
- FS25 brightens dark UI colours, so token values in code do not look like they
  read.
- Windows Python writes CRLF; check line endings before committing in an LF repo.
- The working profile says no OneDrive on this machine, yet FS25's mods
  folder, log and screenshots all live under OneDrive. The profile may need
  updating for this machine.

## Skills practised
- Design and acceptance decisions (roadmap structure, D1-D4, badge layout,
  sizes and timings, fixes to apply) - independent (user).
- Running the game, console commands, taking and organising the screenshots -
  independent (user).
- Writing code, tests, build and deploy, reading the log - done by the AI, not
  practised by the user.
- Using Git history/roadmap as the record of work - encountered.

## Unresolved
- Does the game expose a screenshot call the guided run can use? (Left open;
  the run falls back to prompting.)
- Which working base-game sounds to use per severity (waiting on what the user
  hears and the sample list in the log).
- Whether the dev-only actions should be kept out of the operational modDesc.
- Older process docs still say "frozen" (`EngineeringProcess.md`, ADRs,
  M2.013); `M2M3PresentationFoundationImplementationPlan.md` is not aligned to
  the new rounds.
- The empty `assets/`, `campaigns/`, `sdk/`, `themes/` folders: keep or remove.
- Round 2 (Communications screens, cross-device check) is not yet authorised.
- Second Brain `pipelines/ui-mockups` files are uncommitted there.

## Resume here
Wait for the user's run of `PF.006b`: Ctrl+N once, say what they heard for the
five sounds, save and quit, reload, and screenshot the Phone home. Then read the
log and screenshots, write `docs/reviews/PF.006RuntimeVerification.md`
(covering PF.005 and PF.006, evidence named `PF.006-<n>-<what>` in
`docs/reviews/evidence/`), and ask for acceptance. Ask before committing the
uncommitted PF.006 work (one commit proposed, no push until told).
