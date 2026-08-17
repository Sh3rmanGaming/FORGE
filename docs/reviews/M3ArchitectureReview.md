# FORGE M3 Architecture Review

**Status:** Approved
**Milestone:** M3 - Communications

## Purpose

Record the M3.001 Communications architecture direction, review boundary,
remaining decisions, and authorization state without claiming implementation.

## Approved Direction

The Project Director and Chief Architect approved M3.001 documentation work on
2026-08-11 with these bounded directions:

- one built-in `forge.communications` application;
- Communications owns messages, inbox, read, archive, and badge truth;
- ForgeOS retains OS infrastructure ownership;
- initial identity is `player.local`;
- received messages only, with no deletion/editing/outbound semantics;
- SAVEGAME-backed bounded storage, monotonic identifiers, archived-first
  reclamation, unread protection, and deterministic repair;
- linked notifications remain alerts rather than message storage;
- reading a message may mark its linked notification read, never the reverse;
- dismissing a notification does not archive/delete its message;
- bounded detached presentation models and controlled actions;
- Phone/Laptop shared message state with independent navigation/presentation;
  and
- Laptop window/desktop architecture remains excluded.

These directions authorize specification, not M3.002 implementation and not an
automatic freeze of every low-level proposal.

## Review Set

- [Communications Architecture](../communications/CommunicationsArchitecture.md)
- [Communications Component Design](../communications/CommunicationsComponentDesign.md)
- [Communications Definitions](../communications/CommunicationsDefinitions.md)
- [Communications State Model](../communications/CommunicationsStateModel.md)
- [Communications Application Contract](../communications/CommunicationsAppContract.md)

## Proposed M3 Decomposition

1. M3.001 - Communications Architecture
2. M3.002 - Communications Definitions
3. M3.003 - Communications Manager
4. M3.004 - Communications Application Contract
5. M3.005 - Notification Integration
6. M3.006 - Phone Communications UI
7. M3.007 - Laptop Communications UI
8. M3.008 - End-to-End Verification and Polish

## Accepted Review Decisions

### Presentation adapter

The three proposed Engine/Host-facing ForgeOS methods, model
version 1 envelope, provider protocol, action outcome, result mapping,
side-effect-free query rule, re-entrancy guard, and declarative navigation
mediation are approved. These are additive integration contracts and do not alter existing
M2 method meanings.

### Notification creation boundary

The message-authoritative sequence is approved: commit the
message, request the optional alert, and retain a link only on alert success.
State Store provides no general cross-service transaction; alert failure leaves
the message readable and returns detached notification-result detail.

If notification creation succeeds but linkage commit fails, both records remain
without a fabricated Communications link. One controlled diagnostic and
detached failure detail are required; retry and restoration inference are
forbidden.

### Producer acquisition

M3 may use an in-process FORGE-owned producer and test-only fixture boundaries.
An external addon-facing Communications acquisition/public producer API is
deferred and must not be inferred from the ForgeOS export bridge.

### Action result layering

The layered result is approved: `ForgeOSResult` classifies the
new adapter operation, while a successfully invoked provider returns a detached
`completed/domainResult` outcome. This avoids treating controlled domain
rejection as callback failure and does not reinterpret existing M2 results.

## Non-Freeze Scope

- external producer API until explicitly approved;
- multiplayer/dedicated-server runtime behaviour;
- outbound delivery and conversations;
- arbitrary/third-party application rendering;
- generic widgets;
- source-derived badges;
- Laptop desktop/windows/focus/text input; and
- physical Laptop interaction.

## Implementation Gate

The Project Director and Chief Architect approved M3.001 on 2026-08-11. M3.002
Communications Definitions may proceed within its definitions-only scope. M2
remains closed and frozen within its accepted scope.

## M3.002 Implementation Status

The definitions-only implementation now provides the approved Communications
namespace/application identifiers, Message Channel, Message Priority,
Communications Result, Communications Event, and pure validation/detachment
helper. The component harness is loaded by the development test runner and all
authoritative files have synchronized prototype copies.

The authoritative [M3.002 Runtime Verification](M3.002RuntimeVerification.md)
records a passing FS25 development-suite gate and restored operational package.

## M3.002 Milestone Acceptance

The Project Director and Chief Architect accepted M3.002 on 2026-08-15. It is
authored, architecture-reviewed, approved, implemented, and verified.

The bounded freeze covers:

- `CommunicationsNamespace.STATE`;
- `CommunicationsAppId.COMMUNICATIONS`;
- Message Channel;
- Message Priority;
- Communications Result, including secondary notification failure detail;
- Communications Event;
- stable identifier validation; and
- controlled-data validation and detachment rules.

The freeze does not include message storage, Communications Manager,
persistence operations, message creation/read/archive, notification execution,
presentation providers or execution, UI, external producer APIs, multiplayer,
or outbound communications. M3.003 – Communications Manager was the next
unstarted implementation boundary at M3.002 acceptance.

## M3.003 Implementation Clarification

The Project Director and Chief Architect approved the temporary M3.003 handling
of the optional notification request. A structurally valid message definition
containing `notification` returns `CommunicationsResult.NOT_AVAILABLE`, consumes
no identifier, and mutates no state. Malformed notification data remains
`INVALID_DEFINITION`. Notification creation and linkage remain wholly deferred
to M3.005; M3.003 does not silently discard a valid request or partially
implement that later integration.

## M3.003 Runtime Verification Status

The authoritative [M3.003 Runtime Verification](M3.003RuntimeVerification.md)
records a passing complete FS25 development-suite gate, Communications service,
persistence, and integration harnesses, and a clean production load, save, and
shutdown lifecycle on 2026-08-16. Runtime verification does not itself grant
milestone acceptance or authorize M3.004 implementation.

## M3.003 Milestone Acceptance

The Project Director and Chief Architect accepted M3.003 on 2026-08-16. It is
authored, architecture-reviewed, approved, implemented, and verified.

The bounded freeze covers:

- the FORGE-owned, in-process Communications facade;
- authoritative bounded message storage with an initial capacity of 256;
- monotonic message identifiers and deterministic archived-first reclamation;
- message creation, detached queries, read, and archive operations;
- Communications event publication semantics;
- persistence registration, serialization, restoration, validation, and
  deterministic repair;
- Engine startup, persistence-load completion, save, and shutdown coordination;
  and
- the temporary M3.003 notification-request deferral recorded by the approved
  implementation clarification.

The freeze does not include notification creation or linkage, application
registration, presentation providers or execution, Phone or Laptop UI,
external producer APIs, multiplayer, outbound communications, or any other
deferred M3 capability. M3.004 - Communications Application Contract is the
next unstarted implementation boundary and requires a separate implementation
authorization.

## M3.004 Implementation Clarification

The Project Director and Chief Architect approved the bounded M3.004
player-visible compatibility clarification on 2026-08-16. The built-in
presentation identifiers are `forge.communications.phone` and
`forge.communications.laptop`. Missing detail content contains only
`kind = "communications.messageDetail"` with no fabricated message. Inbox
preview is the complete untransformed body, and sender display falls back from
`senderDisplayName` to `source`.

Successful archive returns declarative navigation to the default inbox;
successful or idempotent mark-read remains on detail. Opening a missing or
reclaimed message returns adapter `SUCCESS` with `completed = false`,
`domainResult = "notFound"`, and no navigation. These decisions do not add
Host clipping policy, sender authority, outbound behavior, generic model
schemas, or other deferred capability.

## M3.004 Implementation Status

M3.004 implementation provides the built-in Communications application,
private provider retention, the ForgeOS Application Presentation Service, and
the three approved Host-facing facade operations. Component and integration
harnesses cover strict model/outcome validation, detachment, re-entrancy,
provider failure containment, shared domain state, and independent device
navigation. The later runtime and acceptance sections below record the
completed verification and bounded freeze.

## M3.004 Runtime Verification Status

The authoritative [M3.004 Runtime Verification](M3.004RuntimeVerification.md)
records a passing complete FS25 development-suite gate, the Application
Presentation Service and Communications Application harnesses, and a clean
production load, save, and shutdown lifecycle on 2026-08-16. Runtime
verification does not itself grant milestone acceptance or authorize M3.005.

## M3.004 Milestone Acceptance

The Project Director and Chief Architect accepted M3.004 on 2026-08-16. It is
authored, architecture-reviewed, approved, implemented, and verified.

The bounded freeze covers:

- the exact `forge.communications.phone` and
  `forge.communications.laptop` presentation identifiers;
- built-in `forge.communications` application registration during
  `REGISTRATION_OPEN`;
- private provider retention outside detached application snapshots;
- the provider protocol version 1 boundary;
- the three approved Host-facing ForgeOS model, action, and badge operations;
- strict detached inbox, detail, not-found, action, and outcome schemas;
- complete-body preview and sender-display fallback behavior;
- shared active-unread badge truth;
- layered controlled domain outcomes;
- mark-read route stability, archive-to-inbox navigation, and controlled
  missing-message behavior; and
- provider failure containment and per-device/application re-entrancy guards.

The freeze does not include notification creation or linkage, Phone/Laptop
Communications rendering or input, external producer/provider APIs, generic
application-model schemas, multiplayer, outbound communications, or other
deferred M3 capability. M3.005 - Notification Integration is the next
unstarted implementation boundary and requires separate authorization.

## M3.005 Implementation Authorization

The Project Director and Chief Architect authorized the bounded M3.005
Notification Integration implementation. The clarification fixes the exact
notification source, metadata, route, title/body fallbacks, three-value
creation return, partial-integration details, message-first atomicity boundary,
asymmetric read propagation, diagnostics, and lifecycle separation.

Implementation remains limited to Communications coordination through the
frozen public ForgeOS Notification facade, focused tests, synchronized
prototype copies, and verification evidence. It does not authorize UI,
external producer APIs, outbound messaging, notification-driven domain
mutation, reverse-link repair, or cross-service rollback.

The bounded implementation and focused harness updates are synchronized.
M3.005 FS25 runtime verification passed on 2026-08-16. Milestone acceptance and
contract freeze remain separate pending gates.

## M3.005 Milestone Acceptance

The Project Director and Chief Architect accepted M3.005 on 2026-08-16. It is
authored, architecture-reviewed, approved, implemented, and runtime verified.

The bounded freeze covers Communications-created notification identity,
definition mapping, message-first creation/linkage ordering, detached
three-value creation detail, accepted partial outcomes, persisted successful
linkage, no reverse-link inference, asymmetric read propagation, and
notification/message lifecycle separation. It does not include Phone/Laptop UI,
external producers, outbound messaging, notification actions, or general
cross-service transactions.

## M3.006 Implementation Authorization

The Project Director and Chief Architect authorized the bounded M3.006 Phone
Communications Presentation implementation. The clarification fixes active-app
composition, launcher sequencing, newest-first rendering, deterministic
viewports and clipping, transient scroll state, primary-release hit semantics,
declared action use, badge ownership, controlled empty/missing/error states,
and pointer-only interaction. It does not authorize generic widgets,
controller execution, keyboard/controller focus, text entry, or changes to
Communications domain ownership.

## M3.006 Acceptance and Bounded Freeze

M3.006 is implemented, runtime verified, accepted, and frozen within its
bounded Phone Communications presentation scope. Accepted capability includes
retained Phone shell composition, launcher sequencing, newest-first detached
inbox rendering, fixed viewports, transient scrolling, deterministic clipping,
primary-release controls, declared application actions, exact badge ownership,
controlled missing/error states, and a reusable Host-owned Phone Home control.

The accepted FS25 development suite and focused Phone Communications harness
passed on 2026-08-16. Evidence is recorded in
`M3.006RuntimeVerification.md`. This freeze does not include Laptop UI,
keyboard/controller focus, text entry, generic widgets/controller execution,
window management, or Communications domain expansion.

## M3.007 Implementation Authorization

The Project Director and Chief Architect authorized the bounded M3.007 Laptop
Communications presentation. The approved scope retains Laptop shell chrome,
replaces the active Home interior with one Communications surface, uses the
existing Host-neutral presentation adapter, renders newest-first detached
models through deterministic Laptop-specific viewports, owns transient scroll
and hit-region state, and routes primary-release controls only through declared
application actions.

The authorization also includes an exact badge, controlled empty/missing/error
states, independent Laptop navigation over shared Communications state, and a
Host-owned Laptop Home control using Lifecycle Service. It excludes windows,
taskbars, z-order, movable/resizable geometry, multi-app rendering, keyboard or
controller application focus, text entry, arbitrary controller execution,
physical Laptop interaction, and Communications ownership changes.

## M3.007 Full-Screen Laptop Visual Amendment

The Project Director and Chief Architect approved a full-screen Laptop visual
surface with one active application, an original woodland operations Home
background, fixed launcher shortcuts, and active-application replacement of
Home content. This remains non-windowed: no taskbar/window manager, movable
geometry, application z-order, or multi-app rendering is introduced.

The amendment makes one explicit exception to the M2.011 Host freeze:
presentation drawing is Laptop then Phone so the independently visible Phone
appears above the full-screen Laptop. Construction, initialization, update,
lifecycle, eligible input, and reverse shutdown order remain unchanged.
Pointer input inside a visible Phone rectangle is occluded from Laptop even
when the Phone does not activate a control; outside that rectangle, Laptop
receives its normal bounded pointer input.

## M3.007 Acceptance and Bounded Freeze

M3.007 is implemented, runtime verified, accepted, and frozen within its
bounded Laptop Communications presentation scope. Accepted capability includes
the full-screen non-windowed Laptop Home and active-application surfaces,
Laptop-specific detached Communications rendering, fixed viewports and
transient scrolling, declared application actions, exact badge ownership, a
Host-owned Laptop Home control, Laptop-before-Phone presentation order, and
Phone-region pointer occlusion.

The accepted FS25 development suite, focused Laptop Communications harness,
and retained multi-Host regression passed on 2026-08-17. Evidence is recorded
in `M3.007RuntimeVerification.md`. This freeze does not include windows,
taskbars, application z-order, movable/resizable geometry, keyboard/controller
application focus, text entry, physical Laptop interaction, generic widget or
controller execution, or Communications domain expansion.

M3.008 - End-to-End Verification and Polish is the active verification and
acceptance boundary.

## M3.008 Runtime Verification Status

M3.008 implementation and runtime verification are complete. The approved
development-only verifier established five controlled Communications fixtures
on Cycle 1 and verified their restoration in a new FS25 process on Cycle 2.
Both definitive cycles used savegame 3 and the unchanged verification package
SHA-256
`FB75D4313D2195C5B6927515C5447B78689C896837FA86521C805F313316D89D`.

The gate proved exact message identity/content/state restoration, successful
notification linkage, absence of reverse-link inference from notification
metadata, shared badge truth, independent Phone/Laptop navigation resume,
runtime-only visibility reset, safe message-sequence continuation, complete
retained regression, player-visible Phone/Laptop behavior, normal save, and
clean shutdown. Evidence is recorded in `M3.008RuntimeVerification.md`.

Development Test Bootstrap and the M3.008 verifier load entry were removed
after the definitive pair. Their sources remain preserved as development test
infrastructure. The independently validated operational package is deployed
with SHA-256
`E6FF9613E1D89142D462F20ED9CC759714C9C79CABC9B4BB1C257EDA6D1FF2B7`.

## M3.008 and Overall M3 Acceptance

The Project Director and Chief Architect accepted M3.008 and overall M3 on
2026-08-17. M3 is authored, architecture-reviewed, approved, implemented,
runtime verified through its definitive unchanged-package two-cycle gate, and
accepted.

The bounded M3 freeze covers the received-message Communications domain and
persistence compatibility boundary, application presentation adapter,
notification integration, Phone Communications presentation, Laptop
Communications presentation, shared authoritative cross-device message/badge
state, and independent per-device navigation resume.

This acceptance does not freeze or authorize external producer APIs, outbound
communications, replies, drafts, threads, attachments, deletion/trash,
multiplayer authority, dedicated-server Communications UI, generic application
widgets/controllers, Laptop windows, text input/focus, or physical Laptop
interaction. A post-M3 implementation boundary requires separate Project
Director and architecture authorization.
