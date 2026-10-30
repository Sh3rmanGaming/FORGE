# M2/M3 Presentation Foundation Implementation Plan

**Status:** Approved
**Version:** 0.1
**Milestone State:** Clarified PF.001 Implemented, Verified, Accepted and
Frozen; PF.002 Implemented, Verified, Accepted and Frozen; PF.003 Implemented,
Verified, Visually Reviewed, Accepted and Frozen; PF.004 Implemented, Verified,
Visually Reviewed, Accepted and Frozen; PF.005-PF.009 Implementation Not
Authorized
**Sequence Effect:** Temporarily precedes M4.001 implementation

## Purpose

Define the smallest independently verifiable implementation sequence for the
bounded M2/M3 Presentation Foundation amendment. This plan is not production
implementation authorization.

## Dependency Graph

```text
PF.001 Contracts, Tokens and Protocol Definitions
                 |
                 v
PF.002 Declarative View Validation and Host Renderer
              /     \
             v       v
PF.003 Laptop Shell  PF.004 Phone Shell
             \       /
              v     v
PF.005 Application Attention
                 |
                 v
PF.006 Notification Presentation and Deep Links
                 |
                 v
PF.007 Communications Laptop Reference UX
                 |
                 v
PF.008 Communications Phone Reference UX
                 |
                 v
PF.009 Cross-Device Verification, Acceptance and Freeze
```

PF.003 and PF.004 may be implemented independently after PF.002 acceptance.
Every later batch requires acceptance of all upstream dependencies.

## Global Boundaries

All batches preserve:

- gameplay/domain ownership;
- existing App Registry identity and registration lifecycle;
- Presentation Resolver selection semantics;
- one active application per device;
- Navigation Service route/history/resume ownership;
- Notification Service record/state ownership;
- Communications schema version 1 and message semantics;
- `player.local` and M4.001 assumptions;
- no implicit cross-service rollback; and
- no windows, gameplay domains, multiplayer identity, or speculative state.

## PF.001 — Contracts, Tokens and Protocol Definitions

### Objective

Freeze the semantic design-token vocabulary, bounded v2 view schema, component
IDs, bounded semantic layout/property vocabulary, route-parameter schema
vocabulary, attention model and meanings, notification cue model, layered
activation results, and diagnostics before runtime implementation.

### Dependencies

Presentation Foundation architecture approval and Design Lead review of token
roles. Final palette/audio assets are not required.

### Expected source changes

Definitions-only files for view protocol, component/token identifiers,
bounded layout properties and value constraints, route-parameter schemas,
attention states, notification cue types, activation stages/results, and log
sources. Existing v1 definitions remain valid. No renderer is introduced.

### Documentation

Reconcile ForgeOS Definitions, App Contract, State Model, Component Design, and
the five Proposed ADRs after approval.

### Tests

Definition completeness, uniqueness, immutability, valid/invalid identifiers,
bounded property/value relationships, exact legacy attention mapping, and no
POC palette value presented as final identity.

### Runtime verification

Load-order/definition harness in FS25; no visual acceptance yet.

### STOP conditions

Public API version change without explicit approval, final palette decision,
or gameplay/application-specific fields in shared definitions.

### Acceptance gate

All controlled vocabularies are approved, loaded in deterministic order, and
v1 compatibility remains proven.

## PF.002 — Declarative View Validation and Host Renderer

### Objective

Add the bounded v2 controlled-data view protocol and a shared Host renderer so
future apps can compose distinct views without app draw callbacks or Host-
hardcoded domain access.

### Dependencies

Clarified PF.001 accepted and refrozen.

### Expected source changes

ApplicationPresentationService validation/adapter, shared ForgeOS presentation
validation/layout/render utilities, PhoneHost/LaptopHost integration seams,
ForgeOS facade only where a Host-neutral internal operation is required, source
manifest, synchronized copies, and focused tests.

### Documentation

Reconcile Presentation Architecture, App Contract, Component Design, State
Model, and ADR-006.

### Tests

Bounded depth/count, allow-listed properties, detachment, invalid/cyclic data,
action-reference validation, clipping/layout, v1 fallback, model failure,
re-entrancy, and no callback during draw.

### Runtime verification

Neutral synthetic view on Phone and Laptop; pointer hit regions/actions; no
gameplay fixture.

### STOP conditions

Arbitrary Lua draw/controller execution, third-party component plugins, Host
domain access, generic windows, text entry, or loss of v1 compatibility.

### Acceptance gate

A neutral controlled view renders differently on both Hosts and activates only
declared actions through the existing adapter.

## PF.003 — Laptop Shell

**Current gate:** Implemented and verified — acceptance required.

### Objective

Implement the approved single-app Desktop, icon launcher, semantic chrome,
workspace, Home/Desktop behavior, safe geometry, and remove the permanent
notification feed.

### Dependencies

PF.002 accepted and Laptop UX visual specification approved by Design Lead.

### Expected source changes

After separate implementation approval: LaptopHost; bounded internal Laptop
shell/profile composition; existing internal semantic theme/asset resolution
only where already authorized; focused Host and integration tests; and required
synchronized copies/manifests. Exact files require review against the then-current
dirty tree.

### Documentation

The design package reconciles Laptop UX, Presentation Architecture, Design
System, Component Design, App Contract, State Model, ADR-005, ADR-009, and the
dedicated [Laptop Shell Architecture](../forgeos/ForgeOSLaptopShellArchitecture.md).
Concept imagery supplies visual hierarchy, density, character, and composition
direction only; depicted functionality remains illustrative.

### Planned implementation sequence

1. Add bounded trusted Laptop shell/profile composition without public fields.
2. Project eligible Laptop shortcuts from existing App Registry metadata.
3. Add compact deterministic layout with bounded overflow and generic icon and
   wallpaper fallbacks through existing internal facilities.
4. Delegate the majority workspace to the frozen PF.002 Laptop session.
5. Preserve Home/Desktop, Back, Close, one-active-app, and Phone occlusion.
6. Remove legacy oversized cards, permanent feed, Communications-specific
   Desktop launch, hardcoded palette, and six-app presentation cap. Preserve
   only the frozen active-app Communications v1 renderer inside the trusted
   application viewport until PF.007.
7. Add focused automated and FS25 visual/runtime verification.

This replaces legacy presentation composition while preserving registry,
resolver, lifecycle, Navigation, Notification, Communications domain/service,
v1 compatibility, PF.001, and PF.002 authority.

### Tests

Registry projection/order; one/few/expected/overflow/empty populations; icon
fallback; one active app; launcher rollback; Home versus Back versus F8 Close;
viewport/safe area/clipping; resolution/UI-scale profiles; wallpaper fallback;
shortcut pointer states; Phone draw/input priority; bidirectionally independent
Host sessions; v1 compatibility; runtime-state reset; and absence of PF.005,
PF.006, persistence/public-API changes, or application-specific Host paths.

### Runtime verification

Player-visible Desktop/app transitions at approved resolutions, aspect ratios,
and UI scales in bright exterior, dark/night, busy farm, and machinery contexts.
Exercise Laptop alone and Phone over Laptop, varied shortcut populations,
active-app majority workspace, pointer lifecycle, missing assets, unavailable
app, normal save, and clean shutdown. Review hierarchy and readability rather
than pixel-perfect concept reproduction.

### STOP conditions

Windows, taskbar, multiple rendered apps, persisted shell state, controller
focus, changed Lifecycle/Navigation meaning, App Registry/public API field,
PF.001/PF.002 semantic change, application-specific Host path, new asset
registration architecture, PF.005/PF.006 implementation, Phone ownership change,
or functionality inferred only from concept art.

### Acceptance gate

Laptop shell behavior and visual direction pass player/Design Lead review while
retained lifecycle/navigation/PF.002/v1 tests remain green. Evidence also shows
compact registry-derived shortcuts, bounded growth, majority app workspace,
future-toast safe geometry without behavior, real-scene readability, and Phone
coexistence without session cross-mutation.

## PF.004 — Phone Shell

### Objective

Implement the right-side companion Phone shell: compact registry-derived Home,
semantic identity/status, bounded launcher paging, reusable OS Home, trusted
application viewport, and removal of the permanent notification feed and
generic-surface notification mutation.

### Dependencies

PF.001-PF.003 accepted/frozen and PF.004 architecture/Phone UX approved. The
bounded Communications model-v1 compatibility exception must remain isolated.

### Expected source changes

`PhoneHost.lua`, focused Phone Host and integration harnesses, approved existing
semantic asset use, and synchronized copies. No public API, persistence,
PF.001/PF.002, final asset-registration, or Communications schema change.

### Documentation

Use [FORGE OS Phone Shell Architecture](../forgeos/ForgeOSPhoneShellArchitecture.md)
as the authoritative PF.004 design and traceability package; reconcile Phone UX,
component/presentation/design, app/state contracts, Communications transition,
plan, and documentation index.

### Tests

Registry eligibility; no hardcoded launcher; one/few/normal/large population;
paging; icon/unavailable fallback; trusted profiles and clipping; generic v2;
Home/app/Home; Back/app Home/OS Home/Close distinction; primary release/cancel;
Phone occlusion; bidirectional session independence; no permanent feed or
notification mutation; PF.005/PF.006 seams only; Communications v1 containment;
no new app-specific branch; retained PF.001-PF.003/M1-M3 suites.

### Runtime verification

Actual-size Phone Home and active app over bright, dark, busy, and machinery
contexts; Phone over gameplay and Laptop; representative resolutions/scales;
launcher population/fallback cases where authorized; save/shutdown,
synchronization, package/deployment fingerprint, and Design Lead review.

### STOP conditions

App Registry/public API/persistence/PF.001/PF.002 changes; Phone repositioning;
shared Host session; generic v1 renderer; Communications v2 migration; PF.005,
PF.006, PF.008, tutorial/Project/mission, controller/focus, final asset-
registration work; direct domain access; or another app-specific Host path.

### Acceptance gate

Implementation and the retained automated/runtime suite are complete. PF.004
awaits Project Director, Design Lead, and Chief Architect acceptance. Runtime
evidence is recorded in
[PF.004 Runtime Verification](../reviews/PF.004RuntimeVerification.md).

Phone reads as a compact companion; generic Home/viewport/lifecycle and
coexistence pass player/Design Lead review; the v1 exception is isolated with
PF.008 removal ownership; and retained suites, save, package, and shutdown pass.

## PF.005 — Application Attention

### Objective

Project the controlled attention model onto both Hosts while preserving exact
legacy integer badges and application/domain ownership. The attention query
stays private; PF.005 adds no public API.

### Already delivered (PF.001/PF.002, frozen)

The five attention states, the optional exact count, the independent-count rule,
and `ApplicationPresentationService:getAttention()` with its validation, legacy
badge mapping, fail-closed handling, and tests. PF.005 does not re-add them.

### Dependencies

PF.003 and PF.004 accepted.

### Expected source changes

- one private Host-context function, `getApplicationAttention(appId)`, in the
  per-device context built by `ForgeOS.lua`, calling the existing service query;
  no new method on the public `FORGE.ForgeOS` table;
- LaptopHost and PhoneHost badge drawing for the five states (drawn shapes, exact
  count, `99+` display above 99), replacing integer-only drawing, including the
  Laptop active-app badge route;
- the Communications provider attention method (active unread to `unread` with
  the exact count; otherwise `none`); and
- tests.

No Notification Service ownership inference, no App Registry field, no API
version change, and no persistence change.

### Documentation

Reconcile Presentation Architecture, Design System, Laptop and Phone UX
Specifications, Communications App Contract, and App Contract (provider method
noted as not yet contractual). Definitions, Component Design, and State Model do
not change.

### Tests

Count/state/label validation, legacy mapping, unavailable fallback, exact count,
side-effect-free queries, stale prevention after read/archive, same truth on both
Hosts, and no source-derived badge.

### Runtime verification

Badge transitions on both device launchers using authoritative Communications
state.

### STOP conditions

Persisted badge state, Host counting, notification-source ownership inference,
domain-value capping, or unapproved public API exposure.

### Acceptance gate

Both Hosts display current domain-derived attention with exact semantics and no
new persisted state.

## PF.006 — Notification Presentation and Deep Links

### Objective

Add ForgeOS coordination of top Phone banners, bottom-right Laptop toasts,
semantic sound cues, and preflighted activation through existing
lifecycle/navigation.

### Dependencies

PF.005 accepted; notification cue/deep-link outcome clarification approved.

### Expected source changes

Internal NotificationPresentationCoordinator, Host transient queues/rendering,
optional App Registry route-parameter declarations, Navigation schema
enforcement, ForgeOS activation facade, Engine/Event Bus lifecycle wiring,
tests, and source manifests. NotificationService route/state schema remains
unchanged.

### Documentation

Reconcile Notification contracts, Presentation Architecture, Phone/Laptop UX,
ADR-007, and ADR-008. Audio asset remains separately approved work.

### Tests

Targeting, queue bounds, timing, expiry non-mutation, read/dismiss separation,
sound deduplication, route-schema acceptance/rejection across direct, resume,
and deep-link paths, preflight before lifecycle mutation, valid/missing/invalid
routes, open/activate/navigate stop order, exact layered partial outcomes,
notification-read timing, and domain non-mutation.

### Runtime verification

Real Phone banner and Laptop toast, selection/deep-link, simultaneous Hosts,
save compatibility, and clean shutdown.

### STOP conditions

Second notification/navigation authority, implicit rollback, message read on
notification activation, permanent feed, persisted animation queue, or final
audio asset without Design Lead approval.

### Acceptance gate

Transient notification UX and deep links pass player-visible testing while
Notification Service semantics and persistence remain frozen.

## PF.007 — Communications Laptop Reference UX

### Objective

Implement the Laptop mailbox/list/reading-pane reference view using existing
message truth and accepted actions.

PF.007 also owns the mandatory migration of Communications Laptop presentation
from model-v1 to model-v2 and removal of the grandfathered
Communications-specific Laptop renderer. PF.007 acceptance must not leave that
branch in place unless a new architecture review explicitly authorizes it. This
exit obligation does not authorize PF.007 work during PF.003.

### Dependencies

PF.006 accepted; Communications UX Laptop composition approved.

### Expected source changes

Communications presentation provider/model composition, Laptop declarative view,
Archive read-only view where approved, focused Communications/Host integration
tests, and synchronized copies. No Communications service/schema change.

### Documentation

Reconcile Communications App Contract, UX Architecture, M3 Architecture Review
as an amendment record, and applicable runtime evidence.

### Tests

Inbox/Archive navigation, three-region composition, selection, newest-first
visual order, read/archive actions, missing message, attention, deep link,
clipping/scroll, detachment, error containment, and Phone independence.

### Runtime verification

Player/Design Lead review of Laptop workflow with controlled fixture messages.

### STOP conditions

Starred, categories, Sent, dates inferred from `createdOrder`, outbound behavior,
schema migration, direct Host domain access, or windows.

### Acceptance gate

Laptop Communications proves the reference design language without changing
authoritative message/persistence semantics.

## PF.008 — Communications Phone Reference UX

### Objective

Implement the compact Phone Inbox-to-Message reference view against the same
logical data/routes/actions as Laptop.

PF.008 also owns mandatory migration of Communications Phone presentation from
model-v1 to model-v2 and removal of the grandfathered Communications-specific
Phone renderer. PF.008 acceptance must not leave that branch in place unless a
new architecture review explicitly authorizes it. This obligation does not
authorize PF.008 work during PF.004.

### Dependencies

PF.007 accepted and Phone Communications composition approved.

### Expected source changes

Communications Phone declarative view, Phone interaction/layout tests, focused
cross-device harness, and synchronized copies. No domain/schema change.

### Documentation

Reconcile Communications App Contract, Phone UX, Communications UX, and M3
amendment review.

### Tests

Inbox/detail, Back/app Inbox/OS Home distinction, read/archive, exact badge,
deep link, missing message, clipping/scroll, pointer semantics, and shared state
with independent Laptop route/view state.

### Runtime verification

Player/Design Lead review of compact workflow and cross-device consistency.

### STOP conditions

Laptop layout copied to Phone, new message schema/authority, local read/archive
mutation, or controller/focus/text-input expansion.

### Acceptance gate

Phone Communications proves device-specific UX over identical authoritative
message state.

## PF.009 — Cross-Device Verification, Acceptance and Freeze

### Objective

Prove the complete amendment, accepted-save compatibility, operational package,
and historical freeze/reopening chain before resuming M4.001 implementation.

### Dependencies

PF.001-PF.008 implemented, verified, and individually accepted.

### Expected source changes

Verification harnesses/records and documentation reconciliation only unless a
defect receives separate correction authorization.

### Documentation

Final Presentation Foundation runtime verification, M2/M3 amendment acceptance,
roadmap/index reconciliation, ADR acceptance/supersession status, updated
authoritative contracts, and explicit bounded freeze.

### Tests

Complete retained M1-M3 suite, new presentation suite, package/source order,
synchronization, save/reload and hard restart where applicable, Phone/Laptop
simultaneous use, deep links, badges, no unexpected diagnostics, and clean
shutdown.

### Runtime verification

Two-cycle persistence only if authoritative persisted state changes; otherwise
accepted-save load/save/hard-restart compatibility plus full player-visible UX
gate. Package/deployed hashes and logs are recorded under existing policy.

### STOP conditions

Any frozen domain/schema regression, missing evidence, weakened retained test,
unapproved persistence migration, or operational package dependency on
development fixtures.

### Acceptance gate

Return `READY FOR APPROVAL — M2/M3 Presentation Foundation Acceptance`. Resume
M4.001 implementation only after explicit acceptance/freeze.

## Working Tree and Git Safety

Preserve all accumulated documentation, ZIP, log, cache, and runtime evidence
artifacts. No staging, commit, push, tag, clean, reset, delete, rename, or history
operation is authorized by this Review plan.
