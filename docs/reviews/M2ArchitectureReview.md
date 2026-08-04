# FORGE M2 Architecture Review

**Status:** Review  
**Milestone:** M2 – ForgeOS

## Purpose

This record captures the current M2 ForgeOS Architecture Review outcome,
decisions accepted during review, unresolved decisions, deferred assumptions,
and implementation-alignment requirements.

It does not mark any Review-status document as Approved.

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

The documents have been authored and reconciled and remain in Architecture
Review. The decisions recorded below were accepted for inclusion during the
review. Further open decisions and architecture gaps prevent final document
approval.

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

Existing `ForgeOSPhase.lua` and `ForgeOSNamespace.lua` align with the accepted
phase and namespace contracts. Remaining ForgeOS definitions and services must
not be described as implemented or verified until code and evidence exist.

## Review Status

The M2 Architecture Review remains in progress.

- Documents: `Review`
- Accepted decisions: recorded
- Formal document approval: not recorded
- Implementation: incomplete
- Verification: not started
- Remaining open decisions: recorded above
