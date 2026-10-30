# FORGE OS Laptop Shell Architecture

**Status:** PF.003 Implemented, Verified, Visually Reviewed, Accepted and Frozen  
**Version:** 0.1  
**Date:** 2026-08-22  
**Owners:** Project Director, Design Lead, Chief Architect  
**Implementation:** Implemented, Verified, Visually Reviewed, Accepted and Frozen

## 1. Purpose and authority

This document defines PF.003, the Host-owned FORGE OS Laptop Desktop and
single-active-application shell. It translates the accepted Laptop UX direction
into an implementation-independent component design without changing the
accepted M2/M3, PF.001, or PF.002 contracts.

Authority is applied in this order:

1. frozen architecture and contracts define behaviour;
2. approved UX specifications define interaction;
3. the approved PF.003 concept image defines visual direction and composition
   philosophy; and
4. illustrative text, records, applications, and functions in that image have
   no authority.

The accepted PF.002 operational fingerprint is
`8472BF9B8A3ED573DA57BA7BB99E71B98E69AE7147D31961A98D37C1A654D10F`.
PF.001 and PF.002 remain frozen inputs. PF.003 is implemented, verified,
visually reviewed, accepted, and frozen at operational package SHA-256
`AE46B6233E40B9D0D272DBF2213589C9F3A2D512D383D6F0BF7E6D6E6B4558D1`.
Additional PF.003 production changes require a new approval.

## 2. Product model

The Laptop is a focused operations computer, not a tablet dashboard or window
manager:

```text
Laptop visible
    -> Host-owned Desktop
    -> launch one registry-derived application
    -> one active application occupies the delegated workspace
    -> OS Home/Desktop closes that application through App Lifecycle Service
    -> Host-owned Desktop
```

There is no minimise state, task switcher, taskbar, overlapping application
window, background application surface, or second active Laptop application.
Application Back remains logical Navigation/application behaviour. Device Close
remains Host visibility behaviour. Neither is an alias for OS Home/Desktop.

## 3. Responsibility boundary

```text
App Registry
    -> eligible Laptop application identity and display metadata

LaptopHost
    -> shell composition, trusted profile/geometry, wallpaper, input ownership

Application Presentation Service
    -> detached and validated application presentation

Shared Renderer
    -> generic application layout, render plan, and application hit regions

Laptop Host adapter/backend
    -> device geometry, drawing, clipping, and primary-pointer ingress
```

LaptopHost may understand application identity, `displayName`, optional
`iconId`, support/resolution outcome, and lifecycle state supplied through
approved ForgeOS contracts. It must not understand application-domain concepts
or branch on an application identifier. It must not render application content.

The Desktop and global shell are not PF.001 application views. They are bounded
Host-owned surfaces. An active application's delegated viewport is rendered by
the frozen PF.002 pipeline. The application cannot draw, arrange, or register
hit regions outside that trusted viewport. Shell-owned hit regions remain
separate from PF.002 application hit regions and win only within shell-owned
geometry.

Gameplay and domain services remain authoritative for gameplay truth.

## 4. Laptop presentation states

The shell has three presentation outcomes:

- **Desktop:** no active Laptop application; show wallpaper, identity, status,
  eligible shortcuts, shell controls, and the future-toast safe-region seam.
- **Application Active:** one active application; retain restrained Host chrome
  and delegate the majority of usable geometry to its validated presentation.
- **Controlled Unavailable:** shell remains operable when registry projection,
  application resolution, validated presentation, asset resolution, or backend
  work fails. It never fabricates application or domain state.

The shell does not introduce a persisted state machine. Active application and
route continue to come from accepted lifecycle/navigation ownership. Hover,
pressed control, projected shortcut arrangement, measured geometry, icon
resolution results, clipping, and shell render data are runtime-only.

## 5. Desktop composition and ownership

The Desktop is composed back-to-front as follows:

1. **Host base and wallpaper:** fixed shell-owned milestone asset or semantic
   fallback surface;
2. **readability treatment:** shell-owned semantic scrim/overlay where required;
3. **identity region:** restrained FORGE OS mark/word identity placement;
4. **status region:** bounded global/device status already authorized by Host
   contracts, with no fabricated balances, updates, or domain facts;
5. **shortcut region:** deterministic projection of eligible Laptop apps;
6. **future toast-safe region:** geometry seam only, without PF.006 behaviour;
7. **control/hint region:** device Close, contextual pointer hint, and, only
   where meaningful, OS Home/Desktop; and
8. **Host-owned input regions:** generated from the arranged shell controls.

The composition deliberately preserves wallpaper and negative space. Shortcut
growth is contained in its own bounded region; it does not progressively turn
the entire Desktop into a mobile-style grid.

### 5.1 Identity and branding

The approved concept establishes geometric, modern FORGE identity character and
placement direction. It does not supply a production logo. PF.003 reserves a
bounded identity slot that supports an approved asset and a controlled textual
fallback. It must not procedurally recreate, trace, or approximate the concept
mark in Lua. Final mark, typography, and exact placement remain Design Lead
decisions.

### 5.2 Wallpaper

Wallpaper is Laptop shell content, never application content. PF.003 supports
one fixed approved shell-owned asset for the milestone. It adds no preferences,
selection UI, theme choice, user customization, or persistence.

If the asset is unavailable or cannot render, the shell uses
`Surface.Background`. The Host may apply an approved semantic surface treatment
or scrim to protect contrast. Readability wins over preserving raw image
brightness or detail. Applications cannot select or modify the wallpaper.

### 5.3 Status and control regions

Status remains compact, bounded, and subordinate to the workspace. It may show
only data already owned and exposed through accepted Host contracts. Illustrative
time, connectivity, balances, and update indicators in the concept are not
requirements.

Device Close remains available through existing Host/Engine input ownership.
OS Home/Desktop is visible while an application is active and invokes the frozen
`osHome` path. Pointer-mode hints are contextual and restrained. PF.003 does not
introduce keyboard/controller focus navigation.

## 6. App Registry to shortcut projection

LaptopHost obtains registered application identifiers through the existing App
Registry boundary and projects only applications for which the accepted
support/presentation resolution contracts produce an available Laptop
presentation. It does not maintain a second catalog, fabricate applications, or
special-case a built-in app.

Each projected shortcut uses only existing controlled metadata:

- stable application identifier for lifecycle requests and deterministic order;
- `displayName` for visible and accessible textual identity;
- optional `iconId` for controlled asset resolution; and
- existing compatibility badge information only where required by the accepted
  current contract, pending PF.005.

Ordering is deterministic: the shell uses the registry's stable enumeration
contract, with lexical application identifier as a defensive tie/fallback. It
must not order by notification content, domain state, pointer history, or table
iteration order.

An omitted, unknown, or unresolved optional `iconId` produces the common FORGE
OS generic-application fallback. The fallback retains the app's display label,
does not infer domain meaning or fabricate artwork, and is visually distinct
from disabled/unavailable treatment. Final fallback artwork remains an asset
decision; this architecture does not define an asset-registration format.

## 7. Shortcut layout

The trusted Laptop geometry profile derives a bounded shortcut region from the
current viewport, safe margins, shell regions, UI scale, and Phone overlap. The
arranger uses semantic spacing and profile-selected shortcut metrics rather than
application-provided geometry or pixels measured from the concept.

Within that region it performs deterministic column-major placement into a
bounded set of compact desktop shortcut cells. A cell provides a meaningful hit
area without visually inflating its icon or label. Labels use bounded wrapping
or ellipsis according to the shell profile. Badges occupy a consistent corner
slot without obscuring icon recognition.

Population behaviour is:

- **one app:** place it at the region origin; do not centre or enlarge it;
- **a few apps:** fill the deliberate shortcut cluster in stable order while
  retaining most Desktop negative space;
- **expected ecosystem:** add profile-determined columns/rows inside the same
  bounded region;
- **more apps than one page:** expose deterministic paged/scrollable shell
  navigation within the shortcut region, with a bounded visible cell count and
  runtime-only page/offset; and
- **maximum practical registry population:** enumerate and project the finite
  registry result, but measure/render only the bounded visible shortcut page.

No new public maximum application count is invented. Existing registry and
runtime defensive behaviour remains authoritative. Presentation work is bounded
by visible cells plus fixed navigation controls; changing page invalidates and
rebuilds only Laptop shell hit regions. The mechanism must not become a general
window, application switcher, or persisted launcher preference.

The exact choice between page controls and a bounded scroll treatment, exact
cell counts, and breakpoints is an implementation-plan decision to be approved
after FS25 geometry trials. Either treatment must preserve stable ordering,
discoverability, non-colour state cues, and substantial negative space.

## 8. Shortcut interaction and visual states

Shortcut states use the shared semantic design system:

- default: readable icon and label with restrained or absent container;
- hover: semantic border/surface/elevation cue plus non-colour change;
- focus-capable: a reserved visible focus treatment, without implementing a
  generic focus/controller system;
- pressed: transient inset/surface/border cue while primary pointer is held;
- disabled/unavailable: reduced emphasis plus explicit non-colour cue or label;
- selected: not used as a persistent Desktop app state; opening transitions to
  Application Active; and
- attention-capable: reserve a badge/status slot, but do not derive or implement
  PF.005 attention truth.

A launch occurs only when primary press and release validate against the same
Host-owned logical shortcut. The shell then calls the existing open, activate,
and default-route lifecycle/navigation sequence. Any failure is rolled back as
required by existing services and returns to an operable Desktop with controlled
diagnostics. It does not manufacture a route, provider model, or app state.

## 9. Active-application composition

While one application is active, Host-owned geometry is limited to:

- identity/status chrome where the approved profile retains it;
- OS Home/Desktop;
- device Close and contextual pointer hint where required;
- safe margins and clipping boundary; and
- the future-toast safe-region seam.

The remaining majority of usable Laptop geometry is the application viewport.
LaptopHost supplies that trusted rectangle and the Laptop density/profile to the
PF.002 Host adapter. The Application Presentation Service supplies only a
detached validated model. Applications cannot request shell removal, overwrite
shell regions, place raw geometry, or register their own Host hit regions.

Dense multi-region applications may compose frozen PF.001 primitives such as
nested generic `Split` inside the delegated viewport. LaptopHost has no knowledge
of why those regions exist. PF.003 does not design Communications or any other
application.

## 10. Trusted geometry and adaptation

The Laptop profile is derived entirely from Host-observed FS25 viewport size,
aspect ratio, UI scale, safe-area rules, and visible Phone occlusion. It exposes
trusted semantic geometry to shell composition and PF.002; it does not expose
raw shell geometry as an application-controlled API.

The profile defines related regions rather than concept-pixel coordinates:

- outer safe viewport and margins;
- compact identity/status band;
- Desktop shortcut cluster;
- active application viewport;
- shell control/hint band;
- lower-right future-toast safe region; and
- right-side Phone overlap/occlusion region when present.

Deterministic profile breakpoints adapt column/row capacity, label fitting,
chrome density, margins, and workspace bounds across approved UI scales and
aspect ratios. Geometry below the approved minimum readable profile produces a
controlled unavailable/unsupported presentation rather than clipped or
overlapping controls. Exact numerical values are not frozen by this document;
they require FS25 runtime acceptance at supported resolutions and scales.

All shell drawing and input is clipped to trusted regions. Detailed wallpaper
cannot reduce text/control contrast below the approved design-system baseline.
Reduced-motion operation does not depend on animation to communicate state.

## 11. Future toast-safe region: PF.006 seam only

PF.003 reserves an intentional lower-right region that future PF.006 Laptop
toasts may temporarily occupy. On Desktop it does not overlap the primary
shortcut cluster or essential controls. In Application Active it may overlay a
bounded non-critical edge of the application viewport, but it must not conceal
OS Home/Desktop or device Close. When Phone overlaps that area, Phone input and
visible geometry take priority and future toast layout must adapt.

PF.003 implements no toast creation, queue, capacity, timing, motion, dismissal,
activation, notification mutation, or deep link. The region is empty in PF.003.
The legacy permanent Laptop notification feed is superseded and provides no
geometry precedent for the new Desktop.

## 12. Future attention seam: PF.005 boundary

Shortcut geometry reserves a bounded badge/status anchor capable of displaying
future approved semantic application attention. PF.003 creates no attention
truth, query, state mapping, count, or notification-derived substitute. Existing
accepted integer badge compatibility may continue only through its current
contract until PF.005 replaces or reconciles it. Absence of attention never
makes an otherwise available shortcut disappear.

`Accent.Primary` is not an alias for unread, selected, attention, warning, or
error. Each future semantic state must retain its frozen meaning and non-colour
cue.

## 13. Simultaneous Phone and Laptop

Phone remains a right-side companion overlay during gameplay and may remain
visible over or alongside Laptop Desktop or an active Laptop application.

```text
Laptop visible, Phone hidden
    Laptop draws its shell/application session and owns pointer input within
    its visible bounds.

Laptop visible, Phone visible
    Laptop session remains unchanged.
    Laptop draws first; Phone draws above it.
    Phone claims pointer input within its visible interactive region.
    Laptop receives pointer input only in its remaining unoccluded region.
```

Showing or rendering Phone must not close or navigate Laptop, reset Laptop app
state or scroll, replace its PF.002 session, invalidate its provider generation,
or mutate its hit regions. Laptop activity has the equivalent prohibition over
Phone state. Each Host retains independent viewport, density/profile, clipping,
hover, press, scroll, last-safe view, hit regions, and generation/invalidation.

PF.003 does not move or redesign Phone, implement tutorial/mission behaviour,
or introduce general focus, window, or multi-pointer architecture.

## 14. Failure and unavailable behaviour

- Empty registry projection shows an intentional shell-owned no-app state with
  identity, wallpaper/fallback, Close, and restrained explanatory text.
- An app unsupported on Laptop is omitted from the eligible projection; it is
  not shown as a fabricated working shortcut.
- A registered app whose presentation becomes unavailable during activation
  produces a controlled failure and returns to Desktop according to existing
  lifecycle rollback rules.
- Missing icon or wallpaper assets use the approved generic semantic fallback;
  missing visual assets do not fabricate domain meaning.
- PF.002 provider, model, layout, render-plan, and backend failures retain its
  controlled failure and last-safe-view contracts inside the application
  viewport.
- Shell layout/backend failure preserves device-close recovery, records bounded
  diagnostics, and never fabricates application/domain content.
- If current geometry cannot meet the minimum readable profile, the Host shows a
  controlled unsupported-size result rather than accepting unsafe clipping.

## 15. Semantic visual interpretation

The concept's authoritative visual direction is translated as follows:

- dark, low-glare semantic background and elevated surfaces;
- a fixed atmospheric agricultural/logistics wallpaper with readability scrim;
- compact shortcuts concentrated in a deliberate Desktop region;
- substantial uninterrupted negative space;
- restrained identity/status chrome and modest corner radii;
- fine semantic borders and limited elevation rather than universal cards;
- dense, majority-workspace application presentation;
- amber/orange only through approved brand/accent/action roles; and
- professional, modern, industrial, agricultural/logistics character.

The shell must avoid sci-fi HUD, cyberpunk, glossy gaming UI, retro technology,
generic SaaS dashboard structure, oversized tablet tiles, and decorative card
proliferation.

The following concept content is explicitly non-authoritative: its application
catalog; Contracts as a broad product name; Starred, Sent, Drafts, Categories,
and New Message; timestamps; balances; system updates; tutorial/onboarding;
Market, Suppliers, Settings, and Documents functionality; notification records;
and all other illustrative domain data. Broad future terminology remains
Projects. Legitimate narrow or historical uses of contract are unaffected.

## 16. Legacy POC migration boundary

PF.003 implementation supersedes these Laptop presentation behaviours:

- oversized application cards;
- permanent notification feed;
- Communications-specific rendering as a long-term Host architecture;
- hardcoded Communications launch behaviour;
- hardcoded palette values; and
- six-application display cap.

The existing active-app Communications model-v1 Laptop renderer is a bounded,
grandfathered compatibility exception until PF.007. It remains functionally
equivalent, gains no feature or layout responsibility, and receives only the
same trusted application viewport supplied to PF.002 model-v2 rendering. It
cannot own or redraw Desktop, identity, status, Home/Desktop, device Close,
future-toast safe geometry, or another shell region. No other application may
use this path and it is not a generic model-v1 renderer.

PF.007 must migrate Communications Laptop presentation to model-v2 and remove
this exception. PF.007 acceptance cannot retain the renderer without a new
architecture review.

PF.003 retains the authoritative App Registry, Presentation Resolver, App Lifecycle,
Navigation, Notification, Communications domain/service, device visibility,
one-active-app, PF.001, and PF.002 contracts. Removing legacy presentation code
does not authorize replacement of those services or broad application migration.
PF.007 owns Communications Laptop UX.

Migration must preserve the accepted v1 presentation path while PF migrations
remain incomplete. Shell replacement must not convert unrelated applications or
Hosts merely to demonstrate PF.003.

## 17. Component design and implementation plan

Implementation remains subject to a separate approval gate. The planned work is:

1. Introduce a Laptop-shell composition module owning semantic regions,
   wallpaper fallback, shortcut arrangement, and shell render/hit plans.
2. Introduce a trusted Laptop geometry-profile module or bounded extension of
   the existing Host adapter profile; no public or application-provided fields.
3. Refactor LaptopHost into orchestration of visibility, shell state, lifecycle,
   PF.002 application viewport, and input priority.
4. Replace Communications-specific Desktop launch behavior with generic
   registry projection. Isolate the frozen active-app v1 compatibility branch
   inside the trusted app viewport pending mandatory PF.007 removal.
5. Remove the permanent feed and six-item cap; add bounded shortcut-region
   overflow navigation.
6. Resolve semantic tokens and controlled shell/icon/wallpaper assets through
   existing internal asset facilities only. If that proves insufficient, STOP
   rather than defining asset registration in PF.003.
7. Retain v1 presentation compatibility and all existing lifecycle/navigation
   service calls.
8. Add focused definition/unit/layout/Host/integration tests and a controlled
   FS25 visual-verification harness or fixture without adding domain behaviour.

Likely implementation files are LaptopHost, internal Laptop shell/profile
components, existing internal theme/asset resolution where already authorized,
focused Host tests, integration tests, and synchronization manifests/copies.
The exact list must be reviewed against the then-current dirty tree before
implementation. No production file is authorized by this document.

## 18. Automated verification strategy

PF.003 implementation acceptance will require automated evidence for:

- registry-derived shortcut population and deterministic ordering;
- one, few, expected, overflow, and empty populations;
- optional/missing/unresolved icon fallback without domain inference;
- no hardcoded app IDs or application-domain renderer/Host branches;
- exact one-active-app launch, OS Home/Desktop, Back, and device Close meanings;
- launch rollback and unavailable presentation behavior;
- compact shortcut geometry, bounded labels, hit areas, and badge anchor;
- hover/press/release/cancel/disabled distinctions and overlapping-region order;
- trusted viewport clipping and application inability to overwrite shell;
- deterministic profiles across approved geometry/UI-scale fixtures;
- lower-right PF.006 safe region remaining behavior-free;
- no PF.005 attention derivation or notification-derived badge truth;
- wallpaper and icon fallback paths;
- independent Laptop/Phone PF.002 session snapshots in both mutation directions;
- Phone draw/input priority in overlap and Laptop input outside overlap;
- v1 application compatibility and retained regression suites;
- runtime-only shell state reset with no persistence writes/schema change; and
- controlled shell, renderer, provider, asset, and backend failures.

Static scope checks must search Laptop shell/Host code for known application IDs
and prohibited domain terms, and inspect public API and persistence diffs.

## 19. FS25 visual and runtime acceptance

Runtime evidence must use the actual FS25 render/input environment and cover:

- bright exterior daylight;
- dark/night exterior;
- high-detail or visually busy farm environment;
- vehicle or machinery interior/context;
- Laptop alone and Laptop with right-side Phone visible;
- Desktop with one, few, expected, and overflow shortcut populations;
- active application with majority usable workspace;
- approved representative resolutions, aspect ratios, and multiple UI scales;
- pointer hover, press, cancel, release, launch, OS Home/Desktop, and Close;
- missing wallpaper/icon and unavailable application controlled fallbacks; and
- reduced-motion-compatible state communication.

Design Lead and Project Director review evaluates hierarchy, density, character,
readability, restrained card use, identity, shortcut intuitiveness, and semantic
state clarity—not pixel-perfect reproduction of concept pixels. Runtime logs
must show no new controlled failure, application-specific Host path, or session
cross-contamination. Normal save and clean shutdown confirm no new persisted
shell state. Packaging, synchronization, deployment, and fingerprint evidence
belong to the later authorized implementation gate.

## 20. Acceptance criteria

PF.003 may be accepted only when:

1. Laptop reads as a professional desktop/work computer rather than a tablet.
2. Desktop shortcuts are compact, discoverable, registry-derived, and bounded.
3. One/few applications remain intentionally composed and future growth remains
   deterministic without filling the entire Desktop.
4. FORGE OS identity is recognizable without fabricating the final mark.
5. Wallpaper and shell remain readable over real FS25 scenes and scales.
6. Active application receives the majority of usable workspace.
7. Host controls remain available without dominating the application.
8. No application-specific LaptopHost or shared-renderer branch exists.
9. OS Home/Desktop, Back, Close, and one-active-app lifecycle remain exact.
10. Phone coexists on the right with input priority in overlap and without
    mutating Laptop state; the reverse invariant also passes.
11. Future lower-right toast geometry is intentional but PF.006 behavior absent.
12. Attention placement is possible but PF.005 truth/behavior absent.
13. No public API, persistence schema, PF.001, or PF.002 change exists.
14. Legacy v1 compatibility and retained regression suites pass.
15. The result follows the concept's hierarchy and character without importing
    unsupported mock functionality.

## 21. Open decisions

These remain explicitly open for their named authority and are not closed by
PF.003 architecture:

- final production FORGE mark — Design Lead / Project Director;
- final application and generic-fallback icon assets — Design Lead;
- exact theme palette — Design Lead under frozen semantic meanings;
- final typography assets — Design Lead;
- exact numerical Laptop geometry and breakpoints — Chief Architect and Design
  Lead after FS25 trials;
- final wallpaper asset and treatment — Design Lead;
- PF.005 attention behavior — later architecture/implementation gate;
- PF.006 toast appearance, timing, and behavior — later gate; and
- asset-registration format — separate architecture decision if required.

## 22. STOP conditions

PF.003 must stop and return the exact missing contract if implementation or
further design requires an App Registry field, public API change, persistence
schema change, PF.001 vocabulary/semantic change, PF.002 renderer change,
application-specific Host rendering, persisted shell presentation state, a new
asset-registration architecture, windows/multitasking, changed lifecycle or
Navigation meaning, new attention semantics, PF.005/PF.006 implementation,
Phone repositioning/ownership change, generic controller/focus architecture, or
functionality inferred only from the concept.

No STOP condition was encountered while completing this documentation design.

## 23. Thirty-requirement traceability

| # | Requirement | Design location | Verification evidence |
|---:|---|---|---|
| 1 | Desktop composition/ownership | Sections 3, 5 | shell ownership and region tests |
| 2 | Active-app composition/ownership | Sections 4, 9 | viewport and single-app tests |
| 3 | Registry to shortcut projection | Section 6 | registry population/order tests |
| 4 | Shortcut interaction lifecycle | Section 8 | press/release and launch rollback |
| 5 | Shell/application boundary | Sections 3, 9 | clipping/overwrite tests |
| 6 | OS Home/Desktop lifecycle | Sections 2, 8, 9 | lifecycle/navigation tests |
| 7 | Device Close | Sections 5.3, 9 | Close versus Home tests |
| 8 | Identity/branding region | Section 5.1 | asset/fallback visual review |
| 9 | Status region | Sections 5, 5.3 | bounded authorized-data review |
| 10 | Wallpaper ownership/fallback | Section 5.2 | missing-asset/contrast tests |
| 11 | Trusted Laptop profile | Section 10 | profile fixture tests |
| 12 | Scale/aspect behavior | Sections 7, 10 | resolution/UI-scale matrix |
| 13 | Application viewport | Sections 9, 10 | majority-workspace/clipping tests |
| 14 | Shortcut algorithm | Section 7 | one/few/overflow determinism |
| 15 | Icon/label/badge semantics | Sections 6–8 | fallback/fitting/anchor tests |
| 16 | Interaction/disabled states | Section 8 | state and non-colour-cue tests |
| 17 | PF.005 seam | Section 12 | scope/static inspection |
| 18 | PF.006 safe region | Section 11 | geometry and absence-of-behavior tests |
| 19 | Simultaneous Phone/Laptop | Section 13 | multi-Host integration test |
| 20 | Phone overlap/input | Sections 10, 13 | draw/hit priority tests |
| 21 | Independent PF.002 sessions | Sections 4, 13 | bidirectional mutation snapshots |
| 22 | Runtime readability/contrast | Sections 5.2, 10, 19 | FS25 scene matrix |
| 23 | Semantic token interpretation | Sections 8, 15 | token-resolution/static review |
| 24 | Reuse versus Laptop composition | Sections 3, 9, 17 | dependency/scope inspection |
| 25 | Failure/unavailable states | Section 14 | controlled-failure tests |
| 26 | POC migration | Sections 16, 17 | legacy-path removal/regression |
| 27 | Superseded legacy behavior | Section 16 | targeted static/runtime checks |
| 28 | Implementation file plan | Section 17 | implementation gate review |
| 29 | Automated verification plan | Section 18 | recorded exact suite outcomes |
| 30 | FS25 visual/runtime plan | Section 19 | runtime log and visual acceptance |

All 30 requested PF.003 architecture requirements are traced. Traceability does
not authorize implementation.

## Related documentation

- [FORGE OS Presentation Architecture](ForgeOSPresentationArchitecture.md)
- [FORGE OS Shared Host Renderer Architecture](ForgeOSSharedHostRendererArchitecture.md)
- [FORGE OS Declarative Presentation Protocol](ForgeOSDeclarativePresentationProtocol.md)
- [FORGE OS Component Design](ForgeOSComponentDesign.md)
- [FORGE OS Design System](ForgeOSDesignSystem.md)
- [FORGE OS Application UX Contract](ForgeOSApplicationUXContract.md)
- [FORGE OS Laptop UX Specification](LaptopUXSpecification.md)
- [FORGE OS App Contract](ForgeOSAppContract.md)
- [FORGE OS State Model](ForgeOSStateModel.md)
- [ADR-005 — Laptop Single-Application Desktop](../adr/ADR-005-Laptop-Single-Application-Desktop.md)
- [ADR-009 — Semantic Design Tokens](../adr/ADR-009-Semantic-Design-Tokens.md)
- [Presentation Foundation Implementation Plan](../roadmap/M2M3PresentationFoundationImplementationPlan.md)
