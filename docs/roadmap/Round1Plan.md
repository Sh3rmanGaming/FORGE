# Round 1 Plan — PF.005 Retest and PF.006 Notification Presentation

**Status:** Implemented and deployed as the `PF.006` verification package
(2026-10-30). Awaiting your test session. Decisions D1–D4 and the mockups
(sizes and timings) approved.
**Date:** 2026-10-30
**Governing rules:** [Roadmap working rules](Roadmap.md#working-rules)
**Replaces, for planning:** the separate PF.005 retest and PF.006 sections of the
[Presentation Foundation implementation plan](M2M3PresentationFoundationImplementationPlan.md)

## Purpose

Deliver everything left in PF.005 and all of PF.006 as **one build and one
player test session**: attention badges (retest only), Phone banners, Laptop
toasts, semantic sound cues, and tapping a banner or toast to open the right
screen in the right app.

## What exists already

- Notification Service records, read and dismiss state, persistence, and the
  `NOTIFICATION_CREATED` completed event.
- Communications already creates a linked notification for a message, with an
  app, a route and parameters.
- Definitions for banner, toast and sound cue types, sound cue meanings, and the
  activation stages and results (`NotificationCueType`,
  `NotificationActivation`).
- Reserved empty geometry: a top banner seam on the Phone and a lower-right
  toast-safe region on the Laptop.
- ADR-007 (transient presentation) and ADR-008 (deep linking), both Accepted.
- PF.005 badges on both devices. The mirrored count-and-shape layout is built and
  committed but has not been seen in the game.

## What gets built

1. **Notification Presentation Coordinator** (internal). Listens for completed
   `NOTIFICATION_CREATED` events, works out which devices should show a cue, and
   hands each device a detached copy. It owns no notification data, saves
   nothing, keeps no history, and clears on shutdown. It sends one sound cue per
   notification, never one per device.
2. **Phone banner.** Appears at the top edge of the Phone, shows the source app
   name, title and a short body, stays a few seconds and leaves. Expiry never
   marks the notification read or dismissed.
3. **Laptop toast.** The same cue, shown in the lower-right region. Toasts stack
   up to a small limit and leave on their own.
4. **Sound cue.** Selected by severity (information, success, warning, error,
   critical) and de-duplicated. See decision D2 for what actually plays.
5. **Tap to open (deep link).** One ForgeOS operation checks the notification,
   the device, the app, the screen and its parameters first, with no side
   effects, then opens the app, brings it forward and navigates, in that order.
   It stops at the first failure and reports how far it got. It never rolls
   back. A successful navigation marks the **notification** read; it never
   changes the linked message or any other domain state.
6. **Route parameter checks.** An app may declare an optional parameter schema on
   a route. Navigation applies the same schema to direct navigation, resume and
   deep links. Routes without a schema behave as today.
7. **Development-only fixtures** (verification build only), so every case can be
   triggered without waiting:
   - `forgeTestMessage` (exists): creates a Communications message and its
     linked notification.
   - `forgeTestNotification <severity>`: creates a plain notification of any
     severity, with and without a destination.
   - `forgeTestNotificationBurst`: creates several at once to exercise the queue
     limits.
   - a notification with a deliberately invalid destination, to prove the
     failure path.

Not built: any change to what a notification record contains, to how it is
saved, to Communications messages, or to who owns unread truth. No permanent
notification list, no windows, no saved animation state, no new public API.

## Decisions (approved 2026-10-30: recommendations accepted)

| # | Decision | Recommendation |
|---|----------|----------------|
| D1 | **When does a cue show?** A closed Phone or Laptop draws nothing. Options: (a) only while that device is open; (b) the Phone banner also shows over normal gameplay while the Phone is closed, the Laptop toast only while the Laptop is open. | (b). With (a), a player walking around the farm would never see a banner, which defeats the purpose. Launcher badges still show the unread count either way. |
| D2 | **Sound.** No audio asset exists and the repo has no sound-playing code yet. Options: (a) route and de-duplicate the cue and log it, but play nothing this round; (b) play a base-game interface sound as a provisional placeholder; (c) wait for your approved sound files. | (b) if the game's sound call works in testing; otherwise (a). I cannot confirm the base-game call without trying it in the game, so this is the main unknown in the round. |
| D3 | **Appearance numbers.** Banner and toast size, how long they stay, and how many stack. Settled on a rendered mockup before any build. | Proposed starting values: Phone 1 banner at a time with up to 3 waiting, 5 seconds; Laptop up to 3 toasts, 6 seconds. |
| D4 | **Pointer needed to tap.** Banners and toasts can only be clicked in pointer mode (F6), like every other control. | Accept this. Without pointer mode a cue is information only. |

## Order of work

1. **Mockup for approval (no build).** I render banner and toast images from the
   real theme tokens and the real badge assets, on both devices, and show them
   with D3. You approve or adjust on the picture.
2. Coordinator, queues and cue routing, with automated tests.
3. Route schema and activation operation, with automated tests.
4. Host banner and toast drawing and tap handling, with automated tests.
5. Development fixtures and the dev-only console commands.
6. Full run in my Lua test environment, the tool tests and the sync, test-order
   and package checks.
7. Build and deploy the verification package, then hand you the test script.
8. Read your screenshots and the log, write the PF.005 and PF.006 verification
   record, and ask for acceptance.

## Automated tests (before you test)

Targeting of cues; queue limits and order; expiry leaves read and dismiss state
alone; sound de-duplication and severity mapping; route schema accepted and
rejected on direct, resume and deep-link paths; preflight changes nothing;
valid, missing and invalid destinations; open then activate then navigate order
with stop-on-failure; exact partial-outcome reporting; notification marked read
only after navigation succeeds; no domain mutation; no query or callback during
drawing; Phone and Laptop sessions independent. The existing PF.005 and earlier
suites stay green.

## Your test session (one sitting)

Use a throwaway savegame. Leave `log.txt` alone until I have read it. Game's own
developer mode is **off** for the Laptop steps so F8 opens the Laptop. Exact
steps and screenshot names are issued with the build; the shape of it is:

| Area | What you do | Screenshots |
|------|-------------|-------------|
| Badges (PF.005 retest) | Open Phone page 1 and 2, then the Laptop | Phone page 2 (triangle at top-left of the icon), Laptop home close-up of "Warning 3" |
| Banner | Run a test message with the Phone closed, then with it open | One screenshot of the banner each way |
| Toast | Run a test message with the Laptop open | One screenshot of the toast |
| Queue | Run the burst command | One screenshot of the stack on each device |
| Tap to open | Click a banner and a toast | Communications on the correct message, on each device |
| Failure path | Run the invalid-destination notification and click it | The result, with nothing broken |
| Both devices | Open both together and run a message | One screenshot |
| Persistence | Save and quit, reload, check badge and notification state | Phone home after reload |
| Sound | Listen once per severity | None; you tell me what you heard |

Expected: about 10 screenshots and one save and quit. That replaces what would
have been a PF.005 retest round plus a PF.006 round.

## Risks

- **Sound is unproven in the game** (D2). It cannot block acceptance of the rest.
- **Route schema touches Navigation**, which was accepted earlier. The change is
  additive and routes without a schema behave exactly as now. The Navigation
  tests are rerun and a short note is recorded.
- **A bigger build** means a failure in one part can hold up the rest. Mitigation:
  everything runs in my test environment first; the coordinator, activation and
  drawing are independent pieces, so one failing does not hide the others.
- **Old Communications screens.** A deep link opens the current v1
  Communications screens until Round 2 replaces them.

## Acceptance

Both devices show current badges, banners and toasts that match notification
truth, tapping opens the right destination or fails safely with an accurate
report, and notification and Communications saved data are unchanged. You decide
acceptance. On acceptance PF.005 and PF.006 are recorded as accepted together,
with evidence kept per batch.

## What this plan does not authorize

Round 2 (Communications screens and the cross-device check) and anything in M4.
