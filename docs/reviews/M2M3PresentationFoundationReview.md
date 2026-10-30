# M2/M3 Presentation Foundation Review

**Status:** Approved
**Date:** 2026-08-22
**Authority:** Project Director and Chief Architect approval, 2026-08-22
**Implementation:** Original PF.001 Implemented, Verified, Accepted and Frozen;
bounded clarification implemented, verified, accepted and refrozen;
PF.002 implemented and verified, acceptance required; PF.003-PF.009
implementation not authorized

## Approval Amendments Incorporated

The approval incorporated three bounded refinements without redesigning the
architecture:

1. PF.001 defines an allow-listed semantic layout/property vocabulary and
   bounded constraints as well as component identifiers. Arbitrary CSS, pixel
   styling, drawing instructions, and executable layout behavior remain
   prohibited.
2. Notification activation performs every reasonably available side-effect-
   free validation before lifecycle mutation and returns layered stage/outcome
   detail without promising rollback.
3. Attention states have frozen meanings; count remains independent, legacy
   zero maps to `none`, and a positive legacy badge maps to `unread` with its
   exact count.

The broad future application/domain term is now `Projects`. Historical uses of
`contract` remain where they accurately mean a narrower agreement.

## Review Scope and Historical Chain

This record reviews the smallest amendments needed to turn the accepted M2/M3
proof-of-concept presentation into a long-term FORGE OS application foundation.
It preserves the historical sequence:

```text
Original M2/M3 acceptance and freeze
        |
        v
Presentation Foundation reopened by Project Director
        |
        v
Architecture/design approved with amendments
        |
        v
PF.001 definitions implementation and verification (authorized)
        |
        v
PF.002-PF.009 separately approved implementation and verification
        |
        v
Revised presentation acceptance/freeze
        |
        v
Resume M4.001 implementation
```

## A. Executive Decision

```text
APPROVED WITH INCORPORATED AMENDMENTS
```

Do not replace ForgeOS. Retain App Registry, Presentation Resolver, App
Lifecycle, one-active-app behavior, Navigation Service, Notification Service,
device targeting/persistence, Communications domain/service/persistence, and
M3 partial-success semantics.

Approve these bounded changes:

1. add a versioned declarative presentation-view protocol and shared Host
   renderer so future apps do not require app-specific Host branches;
2. amend Phone/Laptop shell presentation while retaining Host ownership and
   lifecycle/input boundaries;
3. replace permanent notification feeds with Host-owned transient banners and
   toasts coordinated from completed Notification Service events;
4. add notification-destination activation over the existing lifecycle and
   Navigation services, with optional route-parameter schemas enforced by
   Navigation rather than application-specific Host code;
5. extend integer badges with an optional domain/app-derived semantic attention
   model;
6. establish semantic design tokens and shared bounded components; and
7. supersede only the POC Communications visual composition with distinct
   Laptop mailbox and Phone compact views over unchanged message truth.

The proposal requires no persisted-schema change or migration and does not
alter M4.001.

## B. Documents Created

| Document | Purpose |
|---|---|
| `docs/forgeos/ForgeOSPresentationArchitecture.md` | Engineering ownership, view protocol, notification, attention, navigation, rendering, state, and input boundaries |
| `docs/forgeos/ForgeOSDesignSystem.md` | Semantic visual language and Design Lead governance without freezing the POC palette |
| `docs/forgeos/ForgeOSApplicationUXContract.md` | Common application behavior, shell separation, navigation, attention, and device-specific composition |
| `docs/forgeos/LaptopUXSpecification.md` | Single-active-app Desktop/workspace UX |
| `docs/forgeos/PhoneUXSpecification.md` | Compact Home/application/banner UX |
| `docs/communications/CommunicationsUXArchitecture.md` | Reference Laptop/Phone Communications UX over the unchanged domain |
| `docs/roadmap/M2M3PresentationFoundationImplementationPlan.md` | Nine independently verifiable PF batches and gates |
| `docs/adr/ADR-005-Laptop-Single-Application-Desktop.md` | Proposed single-active-application Laptop Desktop decision |
| `docs/adr/ADR-006-Device-Specific-Application-Presentation.md` | Proposed shared app identity with distinct device presentation decision |
| `docs/adr/ADR-007-Transient-Notification-Presentation.md` | Proposed Phone banner/Laptop toast decision |
| `docs/adr/ADR-008-Notification-Deep-Linking.md` | Proposed existing-Navigation deep-link activation decision |
| `docs/adr/ADR-009-Semantic-Design-Tokens.md` | Proposed semantic-token and provisional-palette decision |
| This review | Primary architecture approval gate and compatibility analysis |

## C. Existing Documents Requiring Amendment After Approval

Do not rewrite historical evidence as though the amendment always existed.

| Existing document | Required bounded reconciliation |
|---|---|
| `docs/forgeos/ForgeOSArchitecture.md` | Add approved presentation layer/coordinator while preserving service/domain ownership |
| `docs/forgeos/ForgeOSDefinitions.md` | Add view/token/component/attention/cue vocabulary and results |
| `docs/forgeos/ForgeOSAppContract.md` | Add v2 view/attention and notification-activation contracts; retain v1 and current lifecycle/navigation |
| `docs/forgeos/ForgeOSStateModel.md` | Classify view/toast/banner/layout state as runtime-only; retain notification/resume persistence |
| `docs/forgeos/ForgeOSComponentDesign.md` | Add bounded renderer/presentation coordinator ownership and source order |
| `docs/reviews/M2ArchitectureReview.md` and `M2.013FinalArchitectureReview.md` | Append explicit reopening/amendment references; preserve original acceptance text |
| `docs/communications/CommunicationsAppContract.md` | Add v2 device-specific reference views and Archive view; retain actions/badge/domain results |
| `docs/communications/CommunicationsComponentDesign.md` | Add provider/view composition only; no service/schema ownership change |
| `docs/reviews/M3ArchitectureReview.md` | Append approved amendment and later verification/acceptance; preserve M3 history |
| `docs/roadmap/Roadmap.md` | Show temporary PF gate before M4.001 implementation and later reconcile Projects terminology |
| `docs/README.md` and `docs/adr/README.md` | Index the complete design package and ADR lifecycle |

Runtime-verification records remain historical evidence and are not rewritten.

## D. Contract Classification

Definitions:

- **RETAIN UNCHANGED** (`RETAIN`): current accepted contract is sufficient.
- **ADDITIVE EXTENSION** (`EXTEND`): backward-compatible additional capability.
- **AMEND EXISTING CONTRACT** (`AMEND`): accepted responsibility/contract
  requires bounded change.
- **SUPERSEDE**: POC behavior is replaced while history is preserved.
- **DEFER**: not included; restriction stated.

The compact labels in the matrix are aliases for exactly these five required
classifications; no row has a mixed or unclassified outcome.

| Reviewed contract | Classification | Decision |
|---|---|---|
| App Registry identity/registration/freeze | RETAIN | One logical app and existing registration owner remain sufficient |
| App Registry presentation declarations | EXTEND | Add approved view protocol metadata only if needed; no second registry |
| App Registry route declarations | EXTEND | Add optional bounded parameter schemas to the existing registry |
| Presentation Resolver exact/capability/default selection | RETAIN | Already resolves distinct Phone/Laptop presentations |
| Application lifecycle | RETAIN | Open/activate/background/close semantics remain |
| One-active-app per device | RETAIN | Exactly matches Phone and Laptop product model |
| Navigation Service | RETAIN | Remains sole logical route/history owner |
| Detached route parameters | RETAIN | Controlled plain data remains the transport representation |
| Route-parameter validation | EXTEND | Navigation enforces optional declared schemas for direct, resume, and deep-link paths |
| Runtime navigation history and Back | RETAIN | Existing semantics remain sufficient |
| OS Home/Desktop shell action | RETAIN | Reusable Host close-app behavior remains distinct from Back/app Home |
| Notification Service ownership | RETAIN | Remains notification authority |
| Notification persistence | RETAIN | SAVEGAME/SESSION/TRANSIENT semantics remain |
| Notification targeting | RETAIN | Existing targetDevices supports device cues |
| Notification read/dismiss state | RETAIN | Shared record state remains |
| Notification route record | RETAIN | Existing appId/routeId/parameters representation is sufficient |
| Notification presentation coordinator | EXTEND | Add runtime-only event-to-Host cue delivery |
| Permanent Host notification feeds | SUPERSEDE | Replace with transient Phone banners/Laptop toasts |
| Notification sound cue | EXTEND | Add semantic cue/dedup path; defer final asset |
| Notification deep-link activation | EXTEND | Orchestrate existing lifecycle and Navigation; no new route system |
| Application integer badge | RETAIN | Existing exact integer remains compatible |
| Semantic application attention model | EXTEND | Optional derived state/count/accessible label; never Host-owned |
| PhoneHost ownership | AMEND | Render shell + bounded declarative views + banner queue, still presentation-only |
| LaptopHost ownership | AMEND | Render Desktop/workspace + bounded views + toast queue, still presentation-only |
| Phone one-active-app presentation | RETAIN | Launcher replaced by active app viewport as accepted |
| Laptop single-active-app full workspace | RETAIN | Explicitly becomes intentional Desktop model, no windows |
| Hardcoded app-specific rendering inside Hosts | SUPERSEDE | Replace with bounded declarative view rendering |
| Device-specific presentation IDs/data | RETAIN | Already accepted and proven |
| Versioned declarative view protocol | EXTEND | v2 alongside legacy v1 during transition |
| UI component reuse | EXTEND | Controlled semantic components, not arbitrary app callbacks |
| Theme/design tokens | EXTEND | Central semantic roles; final values remain design-approved |
| Generic windows/z-order/multi-app rendering | DEFER | Explicitly prohibited |
| Keyboard/controller app focus and text entry | DEFER | Visual states prepared; behavior separately reviewed later |
| Communications service/repository ownership | RETAIN | Messages/read/archive remain authoritative there |
| Communications persistence/schema v1 | RETAIN | No visual field added |
| Communications message IDs/recipient/player.local | RETAIN | Exact existing identity remains |
| Communications read/unread | RETAIN | Shared authoritative truth |
| Communications archive mutation | RETAIN | Existing action/state remains |
| Communications Archive mailbox view | EXTEND | Derive a read-only view from existing archived records |
| Communications Phone POC composition | SUPERSEDE | Replace with design-system compact Inbox-to-Message view |
| Communications Laptop POC composition | SUPERSEDE | Replace with mailbox/list/reading-pane view |
| Communications notification linking/deep-link metadata | RETAIN | Existing messageDetail destination is sufficient |
| Communications partial-success/read asymmetry | RETAIN | No rollback/reverse-domain mutation added |
| Starred | DEFER | Needs domain/schema authority |
| Categories | DEFER | Needs domain/schema authority |
| Sent/outbound messaging | DEFER | Outbound Communications remains excluded |
| Message date/time | DEFER | `createdOrder` is not a timestamp |
| Existing public APIs | RETAIN | No removal or semantic break proposed |
| Internal Host-facing presentation API | EXTEND | Add v2 view/attention/deep-link operations with v1 compatibility |
| Existing retained tests | RETAIN | Must remain; new tests are additive |
| Existing save compatibility | RETAIN | No schema migration required |

### D1. Amendment Analyses

#### D1.1. Declarative View Protocol and Host Rendering

1. **Current:** Provider protocol v1 returns strict detached models; Hosts
   hardcode Communications drawing by app/content kind.
2. **Problem:** Every future app would require Host source changes and duplicate
   Phone/Laptop app-specific rendering logic.
3. **Proposed:** Add bounded v2 declarative views rendered by shared Host
   utilities; actions remain declared and mediated.
4. **Why extension alone is partly insufficient:** v2 is additive at the
   provider boundary, but hardcoded Host branches must ultimately be superseded.
5. **Compatibility:** v1 remains accepted during transition and regressions.
6. **Persistence:** None; view trees/layout/hit regions are runtime-only.
7. **Public API:** Internal/provider extension initially; external exposure
   requires separate version review.
8. **M4.001:** None.
9. **Migration:** No save migration; bounded model-protocol transition only.
10. **Verification:** strict schema/bounds/detachment, v1 fallback, distinct
    devices, declared actions, no callbacks during draw.

#### D1.2. Phone and Laptop Host Responsibilities

1. **Current:** Hosts own geometry/input but also hardcode POC Communications and
   permanent notification text feeds.
2. **Problem:** Mixed shell/app code and non-scalable extension path.
3. **Proposed:** Hosts retain shell/layout/render/input ownership, interpret
   validated views, and own transient cue queues only.
4. **Why additive is insufficient:** permanent feeds/app branches must be
   removed after reference-app migration.
5. **Compatibility:** lifecycle, visibility, input, Home, route, and overlay
   behavior remain.
6. **Persistence:** None.
7. **Public API:** None.
8. **M4.001:** None.
9. **Migration:** None.
10. **Verification:** retained Host tests plus shell/view/transient-state visual
    and interaction gates.

#### D1.3. Transient Notification Presentation and Deep Links

1. **Current:** Notification Service stores route/target/read/dismiss data;
   Hosts show bounded permanent feeds and do not generically activate routes.
2. **Problem:** Feed conflicts with product direction; destination is not
   actionable through one controlled flow.
3. **Proposed:** Event-driven presentation coordinator, Host banner/toast queues,
   ForgeOS lifecycle/navigation activation, and optional route-parameter schemas
   declared in App Registry and enforced by Navigation.
4. **Why additive is sufficient:** Notification Service record semantics and
   route records need no replacement; validation metadata is added to the
   existing route declarations.
5. **Compatibility:** existing records/routes remain valid.
6. **Persistence:** cue queue/animation are not persisted; record state unchanged.
7. **Public API:** proposed activation and route-schema metadata are
   ForgeOS/Host-facing first; external exposure requires explicit review.
8. **M4.001:** None.
9. **Migration:** None.
10. **Verification:** targets, expiry non-mutation, sound dedup, schema
    validation across direct/resume/deep-link paths, exact deep link,
    mark-notification-read timing, partial failures, no message read.

#### D1.4. Semantic Attention

1. **Current:** `getApplicationBadge()` returns one non-negative integer.
2. **Problem:** future applications need unread, attention, warning, or error
   semantics without overloading color/count.
3. **Proposed:** optional derived attention model; integer badge retained and
   compatibility-mapped.
4. **Why additive is sufficient:** current Communications integer truth is valid.
5. **Compatibility:** exact count remains.
6. **Persistence:** none; query-derived.
7. **Public API:** internal/provider additive first.
8. **M4.001:** none.
9. **Migration:** none.
10. **Verification:** validation, fallback, stale prevention, cross-device truth,
    no notification-source inference.

#### D1.5. Communications Reference UX

1. **Current:** accepted Phone/Laptop POC list/detail rendering, same domain and
   independent routes.
2. **Problem:** Laptop is effectively a larger list/detail view; visual language
   is hardcoded and not a reference foundation.
3. **Proposed:** Laptop mailbox/list/reading pane and compact Phone list/detail
   via distinct declarative views; optionally expose existing Archive records.
4. **Why additive is insufficient:** POC visual compositions are intentionally
   replaced, though routes/actions/domain remain.
5. **Compatibility:** existing models may remain during transition; exact
   message/action semantics retained.
6. **Persistence:** none; Archive derives from current records.
7. **Public API:** none.
8. **M4.001:** none.
9. **Migration:** none.
10. **Verification:** shared identity/state, distinct composition, deep links,
    attention, errors, no speculative features.

## E. Proposed Implementation Batches

The viable bounded sequence is documented in
`M2M3PresentationFoundationImplementationPlan.md`:

```text
PF.001 Contracts, Tokens and Protocol Definitions
PF.002 Declarative View Validation and Host Renderer
PF.003 Laptop Shell
PF.004 Phone Shell
PF.005 Application Attention
PF.006 Notification Presentation and Deep Links
PF.007 Communications Laptop Reference UX
PF.008 Communications Phone Reference UX
PF.009 Cross-Device Verification, Acceptance and Freeze
```

PF.002 is required before shell redesign so new shells do not preserve
hardcoded app rendering. PF.003 and PF.004 may proceed independently after
PF.002 acceptance. Every batch has a separate architecture/implementation,
verification, and acceptance gate.

## F. Persistence and Existing-Save Impact

### No schema/version change

- `forge.os` unchanged;
- `forge.communications` schema version 1 unchanged;
- notification records/routes/read/dismiss/targeting unchanged;
- Communications messages/read/archive/linkage unchanged; and
- M4.001 `forge.identity` proposal unchanged.

### Runtime-only new state

- declarative view instances;
- layout/geometry/hit regions;
- hover/pressed/focus/scroll;
- Phone banner queue/animation;
- Laptop toast queue/animation; and
- sound-cue deduplication.

### Derived state

- attention model and exact count;
- Archive mailbox view;
- device-specific composition.

No save migration is justified. Accepted saves should load unchanged. PF.009
must prove load/save/hard-restart compatibility and full retained regression;
two-cycle migration evidence is needed only if later approved architecture adds
authoritative persisted state, which this review does not propose.

## G. Compatibility and Regression Impact

- Existing App Registry, Resolver, Lifecycle, Navigation, Notification, and
  Communications contracts remain the upstream behavioral baseline.
- v1 application models remain accepted during bounded migration.
- Existing M1-M3 tests remain valid and cannot be weakened or removed merely
  because POC visuals are superseded.
- Visual assertions tied specifically to permanent feeds/hardcoded POC geometry
  require replacement with approved new shell/view assertions after amendment
  approval; historical evidence remains unchanged.
- New tests cover the v2 view protocol, transient cues, deep links, attention,
  shells, and reference Communications UX.
- No domain or save compatibility regression is expected.

## H. Impact on M4.001 Subject Identity Architecture

| Question | Finding |
|---|---|
| Change literal `player.local`? | No |
| Change meaning of `player.local`? | No |
| Change `forge.os` ownership? | No |
| Change `forge.communications` ownership? | No |
| Change Communications recipient identity? | No |
| Require Subject Identity awareness in M2/M3? | No |
| Alter M4.001 bootstrap? | No |
| Alter one-way legacy compatibility mapping? | No |
| Create new authority concept? | No; presentation coordination is not gameplay/identity authority |
| Can M4.001 proceed unchanged afterward? | Yes, after Presentation Foundation acceptance |

M4.001 remains architecturally unchanged. Its implementation is temporarily
paused only by sequencing, not by contract conflict.

### H1. Required Questions Answered

1. **App Registry ecosystem support?** Yes. Retain it; add only optional view
   protocol metadata if implementation requires it.
2. **Presentation Resolver distinct layouts?** Yes, already proven by exact
   Phone/Laptop presentations; retain unchanged.
3. **One-active-app invariant?** Yes; it exactly supports the Laptop model.
4. **Host responsibility changes?** Bounded amendment to interpret declarative
   views and own transient cues; no authority change.
5. **Navigation deep links?** Existing route ownership and parameter records
   suffice, but generic parameter-shape validation does not. Add optional route
   schemas to App Registry, enforce them in Navigation for direct/resume/deep-
   link paths, preflight all available validation before lifecycle mutation,
   and add one layered lifecycle/navigation orchestration operation.
6. **Notification targeting/state sufficient?** Yes, unchanged.
7. **Transient presentation owner?** ForgeOS coordinator routes detached cues;
   each Host owns its runtime queue/geometry/animation.
8. **Badge derivation?** Owning app/domain derives attention; Host presents;
   nothing persisted.
9. **Shared versus app visual concerns?** Tokens, component behavior, shell,
   accessibility, and interaction states are shared; information architecture
   and composition are app/device-specific.
10. **Obsolete POC behavior?** Permanent feeds, debug launcher text, immutable
    hardcoded palette, generic large cards, and Host-hardcoded app rendering.
11. **M2 amendments?** Host rendering/shell responsibility, v2 view validation,
    transient notification coordination, deep-link activation, attention query.
12. **M3 amendments?** Device-specific Communications view models and visual
    compositions only; domain/integration contracts remain.
13. **Archive/Starred/Categories compatibility?** Archive view can use existing
    state; Starred/Categories require future domain/schema architecture.
14. **Implement now?** Archive view may be in reference UX; Starred, Categories,
    and Sent are deferred.
15. **Different Phone/Laptop layouts?** Yes, existing resolver and shared message
    truth already prove the separation.
16. **Persisted migration?** No.
17. **Existing saves?** Expected compatible unchanged; PF.009 must prove it.
18. **Retained tests?** Yes; remain required, with only superseded visual
    expectations replaced after approval.
19. **M4.001 unchanged?** Yes.
20. **Smallest safe sequence?** PF.001-PF.009 above, with protocol/renderer
    before shell and reference-app changes.

## I. Approval Decisions

All decisions below were approved on 2026-08-22, subject to the three
incorporated amendments recorded above.

1. Approve the bounded v2 declarative view protocol instead of continued Host-
   hardcoded application rendering.
2. Approve the initial component boundary, bounded semantic property/value
   vocabulary, and explicitly deferred component set; prohibit arbitrary CSS,
   pixels, style values, drawing instructions, and executable layout behavior.
3. Approve v1 compatibility during transition and internal-only v2/attention
   exposure until public API version review.
4. Approve the Notification Presentation Coordinator and session-only Host
   banner/toast queues.
5. Approve preflight before lifecycle mutation, layered partial outcomes, and
   marking the notification read only after successful navigation, without
   linked-domain mutation.
6. Approve optional App Registry route-parameter schemas, Navigation-owned
   enforcement, legacy no-schema compatibility, and mandatory schemas for
   notification-actionable routes.
7. Approve one sound cue per logical notification creation even if both targeted
   Hosts are visible; final sound asset remains deferred.
8. Approve the exact `none`, `unread`, `attention`, `warning`, and `error`
   meanings, count independence, and legacy integer mapping.
9. Approve the Archive read-only mailbox as the only new Communications mailbox
   function in this amendment; defer Starred, Categories, Sent, and date/time.
10. Approve supersession of the listed POC visual behaviors while preserving all
   historical evidence.
11. Approve PF.001-PF.009 ordering and per-batch gates.
12. Approve ADR-005 through ADR-009 as the decision set after final review.
13. Use `Projects` as the broad future application/domain terminology without
    rewriting historical uses of contract in narrower meanings.

## J. Recommended Next Gate

Original PF.001 architecture reconciliation and bounded definitions
implementation remain implemented, verified, accepted, and frozen. The later
bounded node/action/text clarification is implemented, verified, accepted and
refrozen as the current definition baseline. No renderer, PF.002-PF.009
implementation, M4.001 implementation, or gameplay-domain work is authorized.
PF.002 may proceed through its architecture gate only.

```text
M2/M3 PRESENTATION FOUNDATION
PF.001 CLARIFIED AND REFROZEN — PF.002 ARCHITECTURE ONLY
```
