# FORGE M2 Architecture Review

**Status:** Approved
**Milestone:** M2 – ForgeOS

## Purpose

This record captures the current M2 ForgeOS Architecture Review outcome,
decisions accepted during review, unresolved decisions, deferred assumptions,
and implementation-alignment requirements.

It records the role-based Chief Architect approval of the reviewed ForgeOS
documentation.

## Scope

The review covers the ForgeOS foundation architecture and its contracts for:

- devices and device hosts;
- application registration and availability;
- presentation resolution;
- application lifecycle;
- navigation and notifications;
- persistence and resume state;
- player and device state; and
- cross-service consistency.

## Reviewed Documents

- [ForgeOS Architecture](../forgeos/ForgeOSArchitecture.md)
- [ForgeOS Component Design](../forgeos/ForgeOSComponentDesign.md)
- [ForgeOS Definitions](../forgeos/ForgeOSDefinitions.md)
- [ForgeOS App Contract](../forgeos/ForgeOSAppContract.md)
- [ForgeOS State Model](../forgeos/ForgeOSStateModel.md)
- [FORGE Roadmap](../roadmap/Roadmap.md)

## Governance References

- [Engineering Process](../style/EngineeringProcess.md)
- [Git Workflow](../style/GitWorkflow.md)
- [Documentation Lifecycle](../style/DocumentationLifecycle.md)
- [Repository Guide](../../AGENTS.md)

## Review Outcome

Chief Architect review is complete. The five reviewed ForgeOS documents are
Approved as the authoritative v0.1 implementation contract. The decisions
recorded below remain authoritative.

Documented open decisions, deferred assumptions, and architecture gaps remain
unresolved. Their preservation does not imply implementation discretion:
implementation MUST NOT resolve them silently and later resolution requires
approved design work.

Document lifecycle status remains distinct from decision acceptance:

```text
Draft
Review
Approved
Implemented
Verified
```

## Architecture Decisions Accepted During the M2 Architecture Review

### Application state separation

Registration, enabled policy, calculated availability, and runtime lifecycle
are separate concerns. Lifecycle contains only `CLOSED`, `OPEN`, `ACTIVE`, and
`BACKGROUND`.

### Unified registration lifecycle

One ForgeOS registration lifecycle governs device definitions/profiles, device
host implementations, and application definitions. Runtime device host
instances are not registrations.

### Device Host Registry boundary

The Device Host Registry registers device host implementations. Runtime host
instance creation, tracking, and ownership remain subject to the future host
lifecycle design.

### Presentation fallback

`allowCapabilityFallback` is optional and defaults to `false`. An explicit
`supportedDevices[deviceId] = false` is an absolute block. Undeclared device
types require explicit fallback opt-in.

### Capability composition

App-level required capabilities are universal minimums. Presentation-level
requirements are additional, and both sets must pass.

### Persistence namespace

`forge.os` is the stable authoritative ForgeOS State Store namespace.

### Persistence restoration

Runtime rendering objects and ephemeral presentation state are never persisted.
Contract-approved plain-data resume state may persist. Runtime lifecycle and
references are reconstructed and validated against frozen registrations.

### Preference authority

Presentation-only preferences should be player-local. Gameplay-affecting
access, permissions, progression, company policy, and authoritative behavior
remain server- or domain-authoritative.

### Minimum cross-service atomicity

ForgeOS must not report a multi-service operation as successful while exposing
partially committed lifecycle, navigation, resume, notification, or visibility
state.

### Device visibility boundary

Device host implementations may request visibility changes through the public
ForgeOS API but may not mutate authoritative visibility state directly.
Authoritative ownership remains unresolved.

## Architecture Change Log

### 1. Application state separation

- **Previous contract:** Disabled policy was represented as a lifecycle state.
- **Accepted contract:** Lifecycle has four runtime states; registration,
  enabled policy, and availability are separate.
- **Reason:** Keep runtime lifecycle independent from registry and policy state.
- **Documents affected:** Architecture, Component Design, Definitions, App
  Contract, State Model.
- **Classification:** Inconsistency correction.

### 2. Unified registration lifecycle

- **Previous contract:** Registration participants and phase permissions were
  described inconsistently.
- **Accepted contract:** All three registries share one registration lifecycle;
  runtime host instances do not register.
- **Reason:** Validation requires stable, complete registration sets.
- **Documents affected:** Architecture, Component Design, Definitions, App
  Contract, State Model.
- **Classification:** Clarification.

### 3. Device Host Registry boundary

- **Previous contract:** Implementation registration and runtime host instances
  were conflated.
- **Accepted contract:** The registry registers implementations; runtime
  instance ownership remains open.
- **Reason:** Separate registration definitions from runtime objects.
- **Documents affected:** Architecture, Component Design, Definitions, App
  Contract.
- **Classification:** Inconsistency correction.

### 4. Presentation fallback contract

- **Previous contract:** Fallback opt-in, defaults, and precedence were not
  consistently specified.
- **Accepted contract:** `allowCapabilityFallback` defaults to `false`, and an
  explicit device block cannot be overridden.
- **Reason:** Make presentation support deterministic.
- **Documents affected:** Architecture, Component Design, Definitions, App
  Contract.
- **Classification:** New architectural rule.

### 5. Capability composition

- **Previous contract:** App and presentation capability requirements had no
  explicit composition rule.
- **Accepted contract:** App requirements are universal and presentation
  requirements are additional; both must pass.
- **Reason:** Prevent presentations from weakening application requirements.
- **Documents affected:** Architecture, Component Design, Definitions, App
  Contract.
- **Classification:** Clarification.

### 6. Authoritative persistence namespace

- **Previous contract:** `forge.os` and `forge.forgeos` remained alternatives.
- **Accepted contract:** `forge.os` is the stable persistence-facing namespace.
- **Reason:** Establish one durable identifier and align with the definition.
- **Documents affected:** Architecture, Component Design, Definitions, State
  Model.
- **Classification:** Open decision resolved.

### 7. Persistence and reconstruction

- **Previous contract:** Persistence boundaries and validation timing were
  incomplete.
- **Accepted contract:** Only approved plain data persists; runtime state is
  reconstructed and validated by phase.
- **Reason:** Prevent stale references and runtime objects from crossing saves.
- **Documents affected:** Architecture, Component Design, Definitions, App
  Contract, State Model.
- **Classification:** New architectural rule.

### 8. Preference authority

- **Previous contract:** Preference locality did not clearly protect gameplay
  authority.
- **Accepted contract:** Presentation preferences may be local; authoritative
  gameplay policy remains outside presentation control.
- **Reason:** Preserve multiplayer and domain authority boundaries.
- **Documents affected:** Architecture, Component Design, App Contract, State
  Model.
- **Classification:** New architectural rule.

### 9. Minimum cross-service atomicity

- **Previous contract:** Cross-service atomicity was entirely unresolved.
- **Accepted contract:** Partial state must not be exposed as a successful
  operation; mechanism details remain open.
- **Reason:** Establish a minimum externally observable correctness guarantee.
- **Documents affected:** Architecture, Component Design, App Contract, State
  Model.
- **Classification:** New architectural rule.

### 10. Device visibility boundary

- **Previous contract:** Candidate service descriptions implied visibility
  ownership.
- **Accepted contract:** Hosts request visibility changes; authoritative
  ownership and the exact API remain open.
- **Reason:** Avoid approving ownership through an illustrative design.
- **Documents affected:** Component Design, State Model.
- **Classification:** Inconsistency correction.

### 11. M2.003A Core lifecycle clarification

- **Previous contract:** ForgeOS v0.1 defined phase meanings, ownership
  boundaries, and conceptual Core interfaces but left the bounded M2.003A
  transition, query, idempotence, rollback, base-state, and lifecycle-event
  behaviour insufficiently deterministic for implementation.
- **Accepted contract:** Core authoritatively owns and performs phase changes;
  Bootstrap requests and coordinates them. M2.003A defines its read-only Core
  queries, result-bearing lifecycle operations, bounded transition matrix,
  idempotence, safe partial-startup handling, mandatory initial state,
  lifecycle-event timing and payloads, and runtime gating.
- **Reason:** Clarify behaviour already implied by the Approved v0.1 contracts
  without adding capability or resolving unrelated open decisions.
- **Documents affected:** Architecture, Component Design, Definitions, State
  Model, M2 Architecture Review.
- **Classification:** Clarification.

### 12. M2.003B registration coordination boundary

- **Previous contract:** ForgeOS required one lifecycle across three stable
  registration sets but did not define a deterministic coordinator boundary or
  an exact internal participant contract.
- **Accepted contract:** M2.003B coordinates three explicit Registration
  Participant roles through a fixed internal contract, deterministic
  validation and freeze ordering, shared phase gating, failure cleanup, and
  `completeStartup()`. Concrete registry capabilities remain deferred.
- **Reason:** Make the Approved unified registration lifecycle implementable
  without absorbing concrete registry milestones.
- **Documents affected:** Architecture, Component Design, Definitions, App
  Contract, M2 Architecture Review.
- **Classification:** Clarification.

### 13. M2.004 Device Registry deterministic contract

- **Previous contract:** ForgeOS v0.1 assigned Device Registry ownership and a
  conceptual schema but did not freeze exact facade methods, deterministic
  result ordering, copy isolation, event completion behaviour, or production
  participant installation timing.
- **Accepted contract:** M2.004 defines the public registration and query
  facade, controlled plain-data storage, detached and lexically ordered query
  results, lifecycle-local uniqueness, atomic deterministic registration
  results, `DEVICE_REGISTERED` completion semantics, participant behaviour,
  and installation before `REGISTRATION_OPENED` observers.
- **Reason:** Make the existing Device Registry capability implementable
  without absorbing later registries or resolving preserved identifier,
  host-binding, policy, and metadata decisions.
- **Documents affected:** Architecture, Component Design, Definitions, M2
  Architecture Review.
- **Classification:** Clarification.

## M2.004 Test-Lifecycle Reconciliation

M2.004 preserves every existing manual harness and public harness entry point
while separating production diagnostics from development regression execution.

When the existing Logger development mode is disabled, Engine does not invoke
manual harnesses. Normal logs contain only genuine operational startup,
persistence, lifecycle, warning, failure, and shutdown diagnostics.

When development mode is enabled, Engine invokes the complete retained
development suite, including the Device Registry component and integration
harnesses. The M2.003B coordinator harnesses use the production Device Registry
installed by ForgeOS and retain explicit test participants only for the
deferred Device Host Registry and App Registry roles.

Current harness classification:

| Classification | Harnesses |
|---|---|
| Operational smoke | Production Engine, persistence, and ForgeOS lifecycle diagnostics |
| Active regression | Definitions, Event Bus, State Store, Save Manager, Save Manager integration, Bootstrap, Registration Coordinator, Registration Lifecycle, Device Registry, Device Registry integration |
| Development diagnostic | XML Writer, XML Reader, Core, Core lifecycle |
| Trace/debug candidate | Logger and the focused persistence/Core diagnostic harnesses |
| Historical archive | None |
| Obsolete | None |

No historical harness is deleted or archived by M2.004. Intentional
negative-path diagnostics are development evidence and do not execute during
normal operation.

## Future Engineering Recommendation

### FORGE Diagnostics and Runtime Profiles

A separately reviewed capability should consider `OFF`, `OPERATIONAL`,
`DEVELOPMENT`, and `TRACE` profiles, centralized suite selection, structured
fault classification, diagnostic-session identifiers, concise operational
summaries, optional full traces, separation of subsystem diagnostics from
suite orchestration, and beta/development build or configuration control.

M2.004 does not introduce these profiles, public definitions, a diagnostics
API, or a new configuration contract. It uses only the existing internal
Logger development-mode setting.

## M2.004 Development Verification Bootstrap

No deterministic repository-controlled mechanism previously enabled Logger
development mode before Engine invoked the approved development suite.
M2.004 therefore includes a temporary internal
`DevelopmentTestBootstrap.lua`.

The bootstrap loads after Logger and before the remaining services, ForgeOS,
manual harnesses, and Engine. It enables the already approved suite through
the existing `FORGE.Logger:setDevelopmentMode(true)` operation, confirms the
setting through `isDevelopmentMode()`, and emits one concise activation or
failure diagnostic.

The bootstrap:

- defines no public API, setting, profile, or second development flag;
- performs no ForgeOS, persistence, registry, gameplay, or test operation;
- does not change Logger's permanent `developmentMode = false` default;
- is activated only by its explicit development-verification `modDesc.xml`
  source entry; and
- is not part of the frozen Device Registry contract or production ForgeOS
  capability.

Beta and operational load order MUST exclude the bootstrap entry. Normal
execution MUST emit neither its activation message nor manual-suite
diagnostics. Packaging review MUST verify that exclusion and the unchanged
Logger default. The authoritative and synchronized bootstrap source MAY remain
available while unloaded.

This temporary mechanism is expected to be superseded by the separately
reviewed future FORGE Diagnostics and Runtime Profiles capability.

## Remaining Open Decisions

### Cross-component

- lifecycle callback timing and rollback;
- event ordering and re-entrancy;
- availability-provider composition, precedence, conflict handling, and
  diagnostics;
- navigation/lifecycle staging and rollback;
- notification authority boundaries;
- whether `ForgeOSStateService` is required and which invariants it owns;
- stable multiplayer player identity and persistence policy;
- active-device persistence; and
- multi-app, windowing, and multiple-host-instance implications.

### Definitions and presentation

- third-party device identifier ownership, compatibility, namespace, and
  collision rules;
- presentation priority range and deterministic tie-breaking.

### Application contract

- exact application-context API;
- localisation metadata format;
- asset registration format;
- action result format;
- formal addon dependency declarations; and
- controlled app unregistration.

### State model

- authoritative visibility owner and exact visibility API;
- exact persistence mechanism for presentation preferences;
- app-state repair logging level;
- state migration process;
- route-level availability policies;
- notification retention and expiry;
- preference schema registration; and
- per-app session-state interface.

## Deferred Assumptions

- M2 may use the isolated `player.local` resolver.
- Current persistence remains savegame-global.
- True per-player multiplayer persistence is not implemented.
- M2 assumes one active application per device type.
- Device host instance ownership is not assigned.
- Atomicity staging, rollback, callback timing, and re-entrancy are not selected.

These assumptions are constraints or deferrals, not resolved long-term
contracts.

## Remaining Architecture Gaps

- Presentation Resolver ownership and component boundaries are not yet
  explicitly defined in the Component Design.
- The device host instance lifecycle and owner are not defined.
- Stable multiplayer identity and per-player persistence are not defined.
- The authoritative visibility owner is not defined.
- State migration and long-term compatibility policy remain incomplete.
- Notification authority and retention boundaries remain incomplete.

## M2.002 Implementation and Verification

The Approved ForgeOS v0.1 definitions contract has been implemented and
verified.

M2.002 implementation evidence confirms:

- all authoritative ForgeOS definition files exist;
- the approved ForgeOS log sources are implemented;
- ForgeOS Lua sources are included in synchronization;
- authoritative and prototype copies are aligned;
- the prototype loads all ForgeOS definitions in the approved order; and
- the manual ForgeOS Definitions harness is invoked by the Engine development
  test runner.

Runtime evidence confirms that the ForgeOS Definitions harness started and
passed in Farming Simulator 25 and that Engine startup subsequently completed.
The authoritative evidence is recorded in
[M2.002 Runtime Verification](M2.002RuntimeVerification.md).

This evidence implements and verifies M2.002 only. At the M2.002 acceptance
point, ForgeOS Core, Bootstrap, registries, services, device hosts,
applications, and all later M2 work remained outstanding. All open decisions,
deferred assumptions, and architecture gaps recorded in this review remained
unresolved.

## M2.003A Implementation and Verification

The accepted M2.003A Core lifecycle clarification has been implemented and
verified.

Implementation evidence confirms:

- ForgeOS Core owns and enforces the authoritative lifecycle phase;
- Bootstrap requests phase changes and coordinates startup and shutdown;
- the approved lifecycle and compatibility queries are exposed;
- mandatory `forge.os` state and persistence registration are established;
- registration-open and stopped events follow completed transitions;
- Engine startup reaches `REGISTRATION_OPEN`; and
- Engine shutdown stops ForgeOS before global cleanup.

Runtime evidence confirms that the Core, Bootstrap, and lifecycle integration
harnesses started and passed in Farming Simulator 25. Production ForgeOS
startup reached registration-open before Engine startup completed, and ForgeOS
stopped before Engine shutdown completed. The authoritative evidence is
recorded in
[M2.003A Runtime Verification](M2.003ARuntimeVerification.md).

This evidence implements and verifies M2.003A only. Registration validation,
registration freeze, runtime activation, registries, hosts, applications, and
later ForgeOS services remain outstanding. Every unrelated open decision,
deferred assumption, and architecture gap remains unresolved.

## M2.003B Implementation and Verification

The accepted coordinator-only Registration Foundation has been implemented and
verified.

Implementation evidence confirms:

- Registration Coordinator ownership;
- the explicit internal Registration Participant contract;
- exactly one required Device Registry, Device Host Registry, and App Registry
  participant role per lifecycle;
- deterministic Device, Device Host, then App coordination order;
- participant completeness and shared registration gating;
- validation and freeze orchestration;
- failure cleanup, shutdown, and restart behaviour;
- transition capability through `VALIDATING`, `REGISTRATION_FROZEN`, and
  `RUNTIME_ACTIVE`; and
- registration-frozen and started event publication.

Coordinator capability evidence uses explicit test participants. The harnesses
reach registration-frozen and runtime-active, observe the approved events, shut
down, and restart successfully.

Production integration evidence has a different boundary. Concrete registry
participants do not yet exist, so production correctly opens registration,
loads persistence, completes Engine startup, and remains at
`REGISTRATION_OPEN`. It then reaches `STOPPED` before Engine shutdown
completes. Production registration freeze, runtime activation, and started
event publication remain deferred until all three concrete participants exist.

The authoritative evidence is recorded in
[M2.003B Runtime Verification](M2.003BRuntimeVerification.md).

## Parent M2.003 Acceptance

The Project Director accepts M2.003 – ForgeOS Core as complete.

M2.003A and M2.003B together provide the implemented and verified Core
Lifecycle and Registration Coordinator foundations. Parent maturity is:

| Authored | Architecture Review | Approved | Implemented | Verified |
|----------|---------------------|----------|-------------|----------|
| Complete | Complete | Complete | Complete | Complete |

This acceptance does not complete the overall M2 ForgeOS milestone. The next
implementation boundary is M2.004 – Device Registry, which has not started.

## Contract Freeze

The ForgeOS v0.1 documentation contract remains frozen. The verified
definitions package is now the authoritative v0.1 implementation baseline for
subsequent M2 work.

- Approved technical content MUST NOT change silently.
- Contract changes require architecture review and documentation updates.
- Open decisions MAY be resolved through later approved design work.
- Implementation evidence MAY justify future revisions, but revisions MUST NOT
  be applied retroactively without review.
- Public identifiers and persistence-facing contracts require compatibility
  review before change.
- Definition changes require corresponding test updates.
- Synchronized prototype definitions must remain aligned with authoritative
  source.

This freeze records implementation and verification of M2.002 only.
Implementation, testing, and verification of the remaining ForgeOS subsystem,
and overall M2 completion, remain outstanding.

### M2.003 Parent Implementation Freeze

The implemented and verified parent M2.003 baseline is frozen for:

- `FORGE.ForgeOS` as the public Core facade;
- ForgeOS Bootstrap lifecycle coordination;
- Core ownership of authoritative phase state;
- Bootstrap-driven lifecycle transition requests;
- lifecycle and compatibility queries;
- the query-return versus operation-result rule;
- `start()`, `shutdown()`, and `completeStartup()`;
- M2.003 phase transitions and idempotence;
- mandatory base-state initialisation;
- persistence registration;
- implemented lifecycle event timing and payloads;
- Registration Coordinator ownership;
- the Registration Participant internal contract;
- the three required participant roles and deterministic ordering;
- registration gating;
- validation and freeze orchestration;
- failure cleanup, restart, and shutdown behaviour; and
- synchronization, load order, testing, and runtime-evidence requirements.

These contracts MUST NOT change silently. Contract changes require architecture
review; public-facing changes require compatibility review; persistence-facing
changes require migration and compatibility review where applicable; tests
must accompany approved changes; and synchronized outputs must remain aligned
with authoritative source.

### Explicit M2.003 Non-Freeze Scope

The M2.003 implementation freeze does not claim implementation or verification
of:

- Device Registry, Device Host Registry, or App Registry;
- registry storage, duplicate-definition detection, identifier validation,
  definition-specific validation, or concrete lookup;
- device-host binding or runtime host instances;
- applications, presentation resolution, or availability;
- application lifecycle, navigation, or notification services;
- Phone Host, Laptop Host, or UI rendering;
- multiplayer identity or true per-player persistence; or
- later ForgeOS services and applications.

## Implementation Alignment

Implementation work must align with:

- the four-state application lifecycle;
- enabled policy outside the Lifecycle Service;
- three-registry registration-phase enforcement;
- the accepted `allowCapabilityFallback` contract;
- combined app and presentation capability checks;
- phase-aware restoration and runtime reconstruction;
- the minimum atomicity invariant; and
- controlled visibility requests without direct host mutation.

The ForgeOS definition package aligns with the accepted v0.1 definitions
contract and is verified by the M2.002 runtime evidence. Remaining ForgeOS
components and services must not be described as implemented or verified until
code and evidence exist.

The M2.003A Core lifecycle clarification is accepted as part of the frozen v0.1
implementation contract. It is limited to the Core Lifecycle Foundation.
Implementation and runtime evidence now advance M2.003A to Implemented and
Verified without advancing later ForgeOS work.

The M2.003B Registration Participant and coordinator clarification is accepted
as part of the frozen v0.1 implementation contract. Implementation and runtime
evidence advance M2.003B to Implemented and Verified without changing concrete
registry milestone ownership.

Parent M2.003 is accepted as Implemented and Verified within the bounded freeze
recorded above. Production remaining at `REGISTRATION_OPEN` is expected until
concrete registry participants are implemented.

## Review Status

Chief Architect review is complete and the reviewed documentation contract is
frozen at v0.1.

- ForgeOS Definitions document: `Verified`
- Remaining reviewed documents: `Approved`
- Accepted decisions: recorded
- Formal document approval: recorded
- M2.002 implementation: complete
- M2.002 verification: complete
- M2.003A implementation: complete
- M2.003A verification: complete
- M2.003B implementation: complete
- M2.003B verification: complete
- Parent M2.003 acceptance: complete
- Parent M2.003 freeze: recorded
- Next implementation boundary: M2.004 – Device Registry
- Remaining ForgeOS implementation and verification: outstanding
- Remaining open decisions: recorded above
