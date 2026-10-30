# FORGE OS Phone Shell Architecture

**Status:** PF.004 Implemented, Verified, Visually Accepted and Frozen  
**Version:** 0.1  
**Date:** 2026-08-23  
**Owners:** Project Director, Design Lead, Chief Architect  
**Implementation:** Complete, Accepted and Frozen

## 1. Purpose and authority

This document defines PF.004: the Host-owned Phone Home, compact launcher,
trusted application viewport, navigation shell, geometry profile, and device
coexistence boundary. It preserves frozen PF.001-PF.003 and introduces no public
API, persistence schema, renderer semantic, application field, or domain rule.

Authority order is frozen contracts, approved UX specifications, approved
high-fidelity concept direction, then non-authoritative POC evidence. Current
runtime screenshots prove implementation behaviour only and are not visual
templates. PF.004 is implemented, verified, visually accepted and frozen;
PF.005-PF.009 implementation remains unauthorized.

## 2. Product model

Phone is a persistent right-side companion device for quick, contextual work
while gameplay or Laptop work continues. It is not a miniature Laptop, Laptop
panel, modal, child view, or shared Laptop session.

```text
gameplay or Laptop workspace
                    +
independent right-side Phone companion

Phone visible
    -> Host-owned Home
    -> launch one registry-derived application
    -> one active application replaces the Home interior
    -> OS Home closes that app through accepted lifecycle ownership
    -> Host-owned Home
```

Phone may later present guidance while an approved gameplay/domain system
observes completed actions elsewhere. Phone does not control Laptop state,
detect objectives, or own tutorial, Project, mission, or progression truth.

## 3. Responsibility boundary

```text
App Registry ----------------> eligible Phone applications and metadata
App Lifecycle / Navigation --> active app, route, Back and OS Home effects
Application -----------------> detached device-specific presentation model
Application Presentation ----> acquisition, validation, action mediation
PF.002 shared renderer ------> generic v2 measure/arrange/render semantics
PhoneHost -------------------> shell, profile, viewport, input and clipping
FS25 adapter/backend --------> device geometry, pointer and pixels
```

PhoneHost owns frame/safe bounds, shell identity/status, Home launcher,
application viewport, OS Home and Close affordances, contextual input hints,
shell hit regions, top-edge PF.006-safe geometry, and runtime shell state.

PhoneHost does not own application/domain truth, route meaning, notification or
attention truth, persistence, tutorial progression, or application drawing
outside the delegated viewport. No application-specific launcher branch is
allowed.

## 4. Shell states and composition

The shell has two presentation states only:

- **Home:** identity/status, compact launcher, deliberate negative space,
  navigation/Close treatment, and an empty reserved banner-safe region.
- **Application Active:** the Home launcher is absent; the active application
  receives the trusted viewport while bounded identity/status, OS Home, Close,
  and input hints remain Host-owned.

Unavailable providers never fabricate content. Home displays a bounded shell
message when no eligible apps exist. A launch failure leaves or restores Home
with controlled diagnostic status. An active-app presentation failure uses the
PF.002 last-safe rule within that Phone session or a bounded unavailable state.

## 5. Phone Home and registry projection

Home projects the accepted App Registry rather than a Host catalog. An entry is
eligible only when its registered definition supports Phone and the accepted
Presentation Resolver reports an available Phone presentation. The projection
uses existing stable app identity, `displayName`, and optional `iconId` only.

Missing or unresolved icons use one controlled generic fallback paired with the
text label. The fallback does not infer domain semantics and is visually
different from disabled/unavailable state. Final artwork and asset-registration
format remain outside PF.004.

Each shortcut has a compact visual icon/label but a larger meaningful hit area.
Reserved badge anchoring can later consume PF.005 output; PF.004 creates no
attention query, count, severity, persistence, or Communications special case.

## 6. Deterministic launcher growth

The launcher is a bounded paged cluster, not an unlimited shrinking grid.
Profile determines a fixed column/row capacity using minimum icon, label, gap,
and hit-target constraints. Registry order is preserved with stable app-ID
fallback ordering. Only the current page is measured, drawn, and hit-testable.

- one app occupies the first deliberate anchor without stretching into a card;
- a few apps fill the compact cluster in reading order;
- normal population adds cells within the profile capacity;
- larger populations create deterministic pages;
- page controls appear only when needed and remain shell-owned;
- an incomplete last page preserves empty space;
- app count never changes registration identity or creates a public maximum.

If the safe viewport cannot fit the profile's minimum cell and navigation
targets, the Host selects an approved compact profile. If no supported profile
fits, it renders a controlled unavailable shell rather than shrinking below
readability or allowing overflow.

## 7. Trusted geometry profile

Geometry is Host-derived from actual viewport metrics, UI scale, aspect ratio,
Phone frame/safe bounds, and overlap environment. Concept pixels are not a
contract. Every profile derives non-overlapping regions for:

1. physical frame and inset safe area;
2. compact identity/status;
3. reserved top-edge PF.006 banner seam;
4. Home launcher or active application viewport;
5. OS Home/navigation and device-close controls;
6. contextual pointer hints; and
7. shell-owned clipping and hit regions.

The active application receives only the application rectangle and matching
density/profile information through existing PF.002 Host-adapter facilities.
Application render plans and hit regions are clipped to it. Banner-safe and
shell-owned regions are never included in application geometry.

Profile proposals remain subject to FS25 trials at representative aspect
ratios, resolutions, and UI scales. Numerical breakpoints are not frozen by
this architecture document.

## 8. Active application presentation

```text
Phone shell
    +-- shell-owned regions
    `-- trusted application viewport
            +-- model-v2 -> PF.002 shared renderer
            `-- model-v1 -> Communications-only temporary compatibility
```

All future applications use model-v2. PF.002 owns generic validation, layout,
render planning, action mediation, scrolling, last-safe view, and Host-owned hit
regions inside the viewport. PhoneHost does not inspect application concepts.

## 9. Communications model-v1 transition

The existing Communications Phone model-v1 active-app renderer is the sole
grandfathered exception until PF.008. It receives only the trusted application
viewport and may remain functionally equivalent to the frozen path where shell
geometry inherently changes its bounds.

It gains no feature, UX redesign, layout architecture, persistence, API,
consumer, generic abstraction, notification ownership, Home ownership, global
navigation ownership, or PF.002 integration. No new app may select it. PF.008
must migrate Communications Phone to model-v2, replace its legacy visual
composition, and remove the branch. PF.008 acceptance cannot retain it without
a new architecture review.

## 10. Navigation and lifecycle distinctions

- **Application Back** follows accepted Navigation history or an approved
  application action.
- **Application Home/Inbox** is an application route/action and remains active.
- **OS Home** closes the active Phone app through App Lifecycle and reveals Home.
- **Device Close** changes Phone visibility through the existing device adapter;
  it is not navigation and does not fabricate route changes.

PF.004 adds no competing navigation stack, minimise state, task switcher, or
second active Phone app. Same-route hide/show and accepted resume behaviour
remain Navigation/lifecycle-owned.

## 11. Input and occlusion

Shell controls use primary press followed by release on the same current logical
region. Release outside cancels. PF.002 applies the same rule to application hit
regions. Secondary, controller, keyboard, general focus-navigation, and text
entry architecture remain deferred.

When Phone and Laptop overlap, Phone draws later and receives first opportunity
to claim input within its visible bounds. Laptop may receive input outside those
bounds. Showing, hiding, drawing, or interacting with Phone must not mutate
Laptop app, route, scroll, selection, provider generation, last-safe view,
geometry, hover, pressed state, clipping, or hit regions; the reverse also holds.

## 12. PF.005 attention seam

Shortcuts reserve a semantic anchor capable of showing future application
attention. PF.004 does not define or derive state, unread count, label, severity,
colour meaning, persistence, or refresh behaviour. Existing compatibility data
may be displayed only where already accepted; Communications-specific badge
logic is not the future shell model. PF.005 owns the generic contract and UX.

## 13. PF.006 notification seam

The shell reserves non-overlapping top-edge geometry that can later contain a
bounded transient banner over Home or application content. PF.004 keeps that
region empty and defines only its safe-area, clipping, and shell ownership.

PF.004 defines no queue, capacity, timing, animation, sound, expiry, activation,
deep link, read/dismiss mutation, severity behaviour, or notification content.
Generic Phone surface input never mutates notification truth. PF.006 owns all
banner behaviour.

## 14. Visual and accessibility direction

Phone and Laptop share semantic tokens, typography roles, icon family, borders,
restrained accent, interaction semantics, and FORGE identity—not identical
layout. Phone favours compact icons, restrained labels, deliberate spacing,
useful negative space, small status treatment, minimal chrome, and progressive
disclosure suited to brief interactions.

It avoids dashboard panels, oversized cards, permanent feeds, debug/presentation
IDs, unnecessary headings, hardcoded RGB, sci-fi HUD, glossy gaming UI, and a
Laptop layout scaled down. Essential controls retain non-colour cues, readable
contrast, clipping, and meaningful hit targets over bright, dark, busy, and
machinery environments. Reduced-motion compatibility remains available to
PF.006; PF.004 introduces no motion.

## 15. Runtime-only state and failure handling

Launcher page, projected entries, shortcut geometry, hover/focus/press,
resolved profile/viewport, clipping, shell hit regions, transient status,
resolved asset fallback, and PF.002 Phone session internals are runtime-only.
They are cleared at shutdown and never persisted.

Registry/resolution failure omits an ineligible entry or reports controlled
unavailability as appropriate. Asset failure uses semantic fallback. Lifecycle,
navigation, provider, validation, layout, action, or backend failure does not
invent domain state or mutate another Host session. Diagnostics identify Host,
stage, and stable application identity without leaking a stack trace to UI.

## 16. Legacy POC supersession

PF.004 supersedes hardcoded Communications activation, Communications-only
launcher hit regions, the four-app cap, permanent notification feed, generic
surface notification mutation, ACTIVE SURFACE/presentation-ID debug content,
oversized cards, hardcoded RGB, undocumented fixed geometry, and
Communications-specific badge projection.

It preserves underlying App Registry, Presentation Resolver, lifecycle,
Navigation, Notification Service, Communications domain/service, PF.001,
PF.002, PF.003, public APIs, persistence, input ordering, and independent Host
sessions. The Communications v1 active renderer is retained only under section 9.

## 17. Implementation file plan

After separate authorization, expected authoritative changes are limited to
`forgeos/hosts/PhoneHost.lua`, focused Phone Host/integration tests, and only
approved existing shell asset use. Synchronization may update corresponding
prototype copies after source verification. No final asset-registration system,
schema migration, or public facade is planned.

## 18. Automated verification plan

Tests must cover registry eligibility; no hardcoded launcher; one/few/normal/
large populations; paging; unavailable/missing icon; minimum geometry profiles;
shell/app clipping; generic v2 rendering; Home/app/Home lifecycle; Back versus
app Home versus OS Home versus Close; press/release/cancel; Phone occlusion;
bidirectional session independence; no notification feed or shell mutation;
PF.005/PF.006 seams only; v1 viewport containment; no new app-specific branch;
retained Communications v1 harness; no persistence/API change; and complete
retained PF.001-PF.003/M1-M3 regression suites.

## 19. FS25 visual/runtime acceptance plan

Capture actual-size Phone Home and active-app evidence over bright exterior,
dark/night, busy farm, and vehicle/machinery contexts; Phone over gameplay;
Phone over Laptop Home and active app; one/few/overflow launcher fixtures where
authorized; missing icon/unavailable state; and representative resolutions/UI
scales. Review compactness, legibility, hit targets, clipping, shell restraint,
negative space, application dominance, right-side gameplay visibility, and
cross-device identity without requiring pixel-perfect concept reproduction.

Runtime acceptance also requires retained tests, synchronization, package
validation, accepted-save compatibility, normal save, clean shutdown, logs,
screenshots, and package/deployment fingerprints.

## 20. Acceptance criteria

PF.004 may be accepted only when the Phone reads as a companion device; Home is
registry-derived and compact; growth is bounded; app content is clipped to the
trusted viewport; navigation meanings remain distinct; Phone remains right-side
and independent over gameplay/Laptop; PF.005/PF.006 are seams only; the permanent
feed and generic notification mutation are absent; generic v2 rendering is
application-agnostic; the sole v1 exception is isolated and assigned to PF.008;
no public/persistence/frozen-contract change exists; and automated plus FS25
visual evidence passes its approval gate.

## 21. Open Design Lead decisions

Production FORGE mark, application and fallback icons, exact token values,
typography assets, numerical Phone geometry/breakpoints, final launcher spacing,
PF.005 attention presentation, PF.006 banner appearance/motion/sound, and final
Phone polish remain open. Implementation must not close them opportunistically.

## 22. STOP conditions

Stop for App Registry/public API/persistence/PF.001/PF.002 changes; Phone
repositioning; shared Host sessions; generic v1 rendering; Communications v2
migration; PF.005/PF.006/PF.008 implementation; tutorial/Project/mission
architecture; controller/focus architecture; final asset-registration design;
or another application-specific Host path.

## 23. Requirement traceability

| # | Requirement | Design location | Result |
|---:|---|---|---|
| 1 | Companion product model | 2 | Traced |
| 2 | Home ownership/composition | 3-5 | Traced |
| 3 | Active-app shell | 4, 8 | Traced |
| 4 | Registry projection | 5 | Traced |
| 5 | Generic launch | 5, 10 | Traced |
| 6 | One/few/normal populations | 6 | Traced |
| 7 | Large/overflow populations | 6 | Traced |
| 8 | Unavailable/missing icons | 4-6, 15 | Traced |
| 9 | Trusted geometry/profile | 7 | Traced |
| 10 | Frame/status/safe bounds | 7 | Traced |
| 11 | Application viewport/clipping | 7-9 | Traced |
| 12 | Compact readable interaction | 6, 14 | Traced |
| 13 | Back/app Home/OS Home/Close | 10 | Traced |
| 14 | Primary pointer semantics | 11 | Traced |
| 15 | Right-side gameplay role | 2, 11 | Traced |
| 16 | Phone over Laptop | 2, 11 | Traced |
| 17 | Independent Host sessions | 11, 15 | Traced |
| 18 | Future guidance compatibility | 2 | Traced |
| 19 | PF.005 seam only | 12 | Traced |
| 20 | PF.006 seam only | 13 | Traced |
| 21 | No generic notification mutation | 13, 16 | Traced |
| 22 | Generic model-v2 path | 8 | Traced |
| 23 | Communications v1 exception | 9 | Traced |
| 24 | PF.008 exit ownership | 9 | Traced |
| 25 | Runtime-only state | 15 | Traced |
| 26 | Controlled failures | 15 | Traced |
| 27 | Legacy supersession | 16 | Traced |
| 28 | Implementation plan | 17 | Traced |
| 29 | Automated verification | 18 | Traced |
| 30 | FS25 visual acceptance | 19-21 | Traced |

All 30 PF.004 architecture requirements are traced without changing a frozen
contract or implementing PF.004-PF.008 functionality.
