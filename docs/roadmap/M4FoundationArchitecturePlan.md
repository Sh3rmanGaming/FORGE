# M4 Foundation Contracts and Runtime Seams — Architecture Plan

**Status:** Approved
**Version:** 0.2
**Date:** 2026-08-20
**Approved:** 2026-08-22
**Milestone State:** Not Started

## 1. Purpose

M4 establishes the minimum shared contracts that Character, Companies,
Banking, Projects, and Campaign content require. It converts the accepted
[Foundation Assumption Review](../reviews/FoundationAssumptionReview.md) into
small, ordered architecture and implementation gates.

This plan is not an implementation authorization. Each capability batch must
receive architecture approval before production implementation begins.

## 2. Architectural Outcome

After M4, future gameplay domains can be designed against:

- stable subject identity without redefining `player.local`;
- one server-authoritative mutation entry pattern;
- one simulation-time and deadline interpretation;
- one persistence migration and compatibility policy;
- deterministic external definition identity and dependency rules;
- validated immutable XML definition registration;
- explicit cross-domain partial-success and retry rules; and
- traceable framework, package, API, schema, and build versions.

M4 supplies foundations and ports. It does not supply gameplay-domain truth.

## 3. Scope Boundary

### Included

- architecture, definitions, adapters, registries, validation, and focused
  infrastructure required by the eight M4 batches;
- compatibility adapters that preserve frozen M2/M3 state;
- detached controlled-data contracts;
- test fixtures that prove the foundation without becoming gameplay systems;
- documentation, synchronization, packaging, and runtime verification required
  for the implemented M4 boundary.

### Excluded

- qualifications, reputation, experience, or character progression;
- company creation, membership gameplay, or company finances;
- currencies, balances, accounts, transfers, rewards, or settlement;
- Projects, Contracts, objectives, deadlines as gameplay records, or rewards;
- campaign lifecycle, campaign gameplay authority, or content packs;
- full network transport, replication, prediction, or dedicated-server UI;
- a distributed transaction framework;
- reinterpretation or rewrite of M2/M3 persisted state; and
- framework/package version changes unless separately approved.

If a batch requires excluded capability, it must STOP rather than introduce a
temporary owner.

## 4. Dependency Structure

```text
M4.001 Subject Identity and Compatibility
        |
        v
M4.002 Authority Request and Execution Seam
        |
        +--------------------+
        |                    |
        v                    v
M4.003 Game Time       M4.004 Persistence Compatibility
        |                    |
        +----------+---------+
                   |
                   v
M4.005 External Identity, Dependencies and API Evolution
                   |
                   v
M4.006 XML Definition Registry Foundation
                   |
                   v
M4.007 Cross-Domain Coordination Policy
                   |
                   v
M4.008 Version Mapping, Integration Verification and Freeze
```

Identity precedes authority because an authoritative request must name both its
actor and affected owner without relying on device-local identity. Time and
persistence can then mature independently. External identifiers precede XML
registration so discovery never invents collision policy. Cross-domain policy
is finalized after the ports and identifier rules it coordinates are stable.

## 5. Capability Batches

### M4.001 — Subject Identity and Legacy Compatibility

#### Objective

Define stable identity categories and the compatibility boundary through which
existing local-only contracts participate without being redefined.

#### Architecture contract

- `subjectId` identifies a persistent player, organisation, or system subject.
- Runtime player identity, persistent identity, ownership, and permission are
  distinct concepts.
- `player.local` remains the exact accepted M2/M3 local runtime identifier.
- A compatibility resolver may map the bounded legacy local subject into the
  authoritative local-server context; it must not rewrite old stored values or
  claim global uniqueness.
- New gameplay-domain ownership fields use stable subject identifiers from
  inception.
- Organisation identifiers are subjects but organisation membership and rules
  remain M6-owned.

#### Expected deliverables

- Subject Identity architecture and definitions contract.
- Legacy `player.local` compatibility contract.
- Subject identifier validation and detachment rules.
- Focused component and persistence-compatibility tests.

#### Exit gate

A future domain can name an actor and owner without reading a Host, device, or
raw M2/M3 state table and without treating `player.local` as multiplayer ID.

### M4.002 — Authoritative Mutation Request Seam

#### Objective

Prevent `local client call == authoritative mutation` from entering future
domain designs while allowing single-player development before full networking.

#### Architecture contract

- All shared gameplay mutations enter an authority port using controlled data
  equivalent to `requestId`, `actorSubjectId`, `operation`, `parameters`, and
  authenticated authority context.
- The authoritative server-side domain validates permissions and invariants,
  commits its own state, and returns a detached layered outcome.
- Single player uses the same local authoritative-server execution path.
- Transport authenticates or binds the actor; callers cannot self-assert
  authority through mutable parameters.
- Clients may request mutations and render replicated/detached state but may
  never commit shared gameplay truth.
- Full network serialization and replication remain deferred.

#### Expected deliverables

- Authority request/result contract.
- Local authoritative execution adapter.
- Permission-decision port without a Character or Company implementation.
- Duplicate request/idempotency boundary.
- Tests for validation, actor binding, rejection, detachment, and local-server
  equivalence.

#### Exit gate

A synthetic test domain can execute through the authority seam without a
client directly invoking authoritative mutation or M4 owning gameplay rules.

### M4.003 — Shared Game Time and Deadline Semantics

#### Objective

Give every future duration/deadline consumer one deterministic interpretation
of FS25 simulation time.

#### Architecture contract

- The authoritative server obtains time from one FS25 simulation-time provider.
- The canonical unit is an integer simulation minute unless runtime validation
  proves that basis cannot be stable; that finding is a STOP condition.
- Persisted deadlines are absolute canonical simulation timestamps; durations
  are integer simulation minutes.
- Pause stops advancement, time-scale changes advancement through FS25, and
  save/reload preserves comparisons without wall-clock elapsed time.
- Overdue means `authoritativeNow >= deadline` unless a domain explicitly owns
  a stricter approved boundary.
- Calendar presentation may derive day/month/year labels but cannot become the
  calculation authority.
- Clients consume detached time snapshots for presentation only.

#### Expected deliverables

- Game Time architecture, definitions, and provider contract.
- Deadline calculation/comparison helpers with overflow and malformed-input
  rules.
- Tests for pause, acceleration, boundaries, save/reload, and client read-only
  behavior.

#### Exit gate

Future domains can persist and compare deadlines without interpreting FS25 time
or wall-clock time independently.

### M4.004 — Persistence Migration and Compatibility

#### Objective

Create one lifecycle policy for future domain namespaces while preserving
existing M2/M3 persistence contracts unchanged.

#### Architecture contract

- Document format version, domain schema version, and runtime/API version are
  separate axes.
- Save Manager orchestrates loading but each domain owns sequential `N -> N+1`
  migrations for its detached candidate state.
- Migration transforms older valid schema; repair handles malformed current
  schema; additive defaulting fills defined absent fields; discard rejects a
  bounded invalid record or namespace according to its approved policy.
- Missing older fields and malformed present fields are never equivalent.
- Migration completes in memory before authoritative registration. The source
  save tree is not partially mutated to manufacture success.
- A failed step yields a controlled incompatible-state outcome and no partial
  migrated commit.
- A future unsupported schema is not downgraded or overwritten automatically.
- The next normal authoritative save may emit the successfully migrated current
  representation; backup policy must be settled before destructive conversion
  is ever introduced.

#### Expected deliverables

- Persistence Compatibility architecture contract.
- Domain migration registration/orchestration contract.
- Controlled migration result definitions and diagnostics.
- Synthetic version fixtures proving sequential migration and failure atomicity.

#### Exit gate

A synthetic namespace can distinguish migration, repair, defaulting, discard,
and incompatibility without changing M2/M3 saved schemas.

### M4.005 — External Identity, Dependencies and API Evolution

#### Objective

Define deterministic identities and dependency rules before external XML
content is discoverable.

#### Architecture contract

- External definition IDs use `<registered-owner>.<domain>.<local-name>`.
- `forge` owns built-in identifiers; third parties use an approved registered
  owner namespace.
- Runtime-generated record IDs are not external content IDs.
- A duplicate identity conflict invalidates the complete conflict group; load
  order never selects a winner.
- Required and optional dependencies are explicit and version constrained.
- Required dependency failure rejects the dependent provider; optional absence
  disables only declared optional integration.
- Overrides and replacements remain forbidden until separately approved.
- Public APIs expose explicit versions/capabilities, prefer additive evolution,
  deprecate before removal, and never infer compatibility from package load
  order.

#### Expected deliverables

- External Identifier and Namespace contract.
- Dependency and version-compatibility contract.
- Public API evolution/deprecation policy.
- Validation tests for collision groups and deterministic dependency ordering.

#### Exit gate

M4.006 can discover definitions without inventing ownership, collision,
dependency, or compatibility behavior.

### M4.006 — XML Definition Registry Foundation

#### Objective

Provide the XML-first content seam that later domains extend with their own
schemas without making campaign packs runtime authorities.

#### Architecture contract

- The Definition Registry discovers providers, resolves approved dependencies,
  selects owned schema validators, and freezes validated definitions for the
  runtime session.
- Each gameplay domain owns its definition schema and conversion into detached
  runtime models.
- XML supplies immutable data; Lua supplies approved behavior and domain rules.
- Providers register definitions, not authoritative runtime mutations.
- Definition objects are detached from mutable XML trees and cannot be changed
  after registration freeze.
- Invalid providers or conflict groups fail through controlled diagnostics;
  deterministic ordering never repairs collision by winner selection.
- Addon/campaign discovery uses explicit provider metadata and does not become
  campaign lifecycle implementation.

#### Expected deliverables

- Definition Registry architecture and component design.
- Provider manifest, discovery, dependency, validation, freeze, and query
  contracts.
- One neutral synthetic schema/fixture proving the pipeline.
- No Character, Company, Banking, Project, or Campaign schema.

#### Exit gate

A synthetic external definition can be discovered, validated, detached,
queried, and frozen deterministically without owning gameplay state.

### M4.007 — Cross-Domain Mutation and Partial-Success Policy

#### Objective

Generalize the proven M3 authoritative-commit-plus-secondary-outcome pattern
without promising distributed transactions.

#### Architecture contract

- Required cross-domain prerequisites may be validated or reserved through
  explicitly approved non-finalising ports before the initiating authoritative
  commit.
- A preflight or reservation must never be treated as successful downstream
  authoritative mutation unless that owning domain explicitly defines such a
  reservation contract.
- Once the initiating domain commits, downstream authoritative effects do not
  implicitly participate in rollback.
- Completed events publish immutable facts after commit; events are not
  transactional commands and listener failure cannot reverse the commit.
- Secondary effects use explicit ordered requests and return detached
  integration outcomes separately from the initiating domain result.
- No cross-domain rollback is implied.
- Automatic retry is forbidden unless one owner defines a stable operation ID,
  receiver idempotency, retry bounds, and terminal failure behavior.
- Re-entrant mutation of the initiating operation is rejected or deferred by
  an explicit domain policy.
- Every partial state names its reconciliation owner; absence of a reconciler
  is an explicit terminal outcome, not silent eventual consistency.

#### Expected deliverables

- Cross-Domain Coordination contract.
- Event publication timing and re-entrancy policy.
- Integration-result and diagnostic conventions.
- Synthetic multi-participant tests for success, rejection, secondary failure,
  duplicate delivery, and no rollback.

#### Exit gate

Future Projects can describe progression, settlement, company, and
Communications effects without making any one of those domains a hidden
transaction participant.

### M4.008 — Version Mapping, Integration Verification and Foundation Freeze

#### Objective

Make compatibility axes traceable and prove the combined M4 seams before any
gameplay-domain milestone starts.

#### Architecture contract

- `FORGE.Version` is framework/runtime SemVer.
- `modDesc.xml` version is the GIANTS numeric package version.
- Public API versions and persisted schema versions remain separate.
- Every verified package record maps framework version, package version, API
  versions, schema versions, source commit, and package/deployed hash.
- Version values change only through explicit release/version approval.
- Current `0.5.0-dev` and `0.4.1.0` remain unchanged during planning.

#### Expected deliverables

- Version Identity policy and build-record format.
- Integrated M4 test harness and retained M1-M3 regression gate.
- Save/reload and, where persistence changes warrant it, hard cross-launch
  verification using a disposable save.
- Final M4 architecture review, runtime evidence, operational package
  restoration, documentation reconciliation, and bounded freeze proposal.

#### Exit gate

All approved M4 contracts are implemented and verified together, retained M1-M3
tests pass, no gameplay domain has been introduced, and the result is returned
for explicit M4 acceptance.

## 6. Ownership Boundaries

| Concern | M4 owner | Explicit non-owner |
|---|---|---|
| Stable subject identity and resolution | Subject Identity boundary | Hosts, ForgeOS apps, future Projects |
| Mutation admission/execution | Authority seam plus owning domain | Client presentation, Event Bus listeners |
| Simulation time conversion | Game Time provider | Individual gameplay domains |
| Schema migration logic | Owning domain, orchestrated by Save Manager | Save Manager as gameplay-rule owner |
| External definition IDs/dependencies | Definition foundation | Per-domain load iteration |
| Runtime gameplay truth | Future owning domain | XML providers, campaign packs, ForgeOS |
| Secondary outcome coordination | Initiating domain contract | Generic implicit rollback framework |
| Version-axis mapping | Build/version policy | Ad hoc normalization |

## 7. Compatibility With M2 and M3

M4 must preserve unchanged:

- the literal and bounded meaning of `player.local`;
- existing ForgeOS and Communications namespaces and stored schema;
- ForgeOS lifecycle, application, navigation, notification, and Host ownership;
- Communications message authority and presentation adapters;
- detached presentation models;
- notification non-authority;
- Phone/Laptop independent presentation state; and
- M3 partial-link and partial-success behavior.

M4 may add adapters around these contracts. It may not rewrite their history,
infer new multiplayer meaning from their state, or migrate them merely for
uniformity.

## 8. Verification Strategy

Each batch requires:

1. contract/definition validation;
2. focused component tests;
3. negative and malformed-input coverage;
4. integration tests against the immediately preceding seams;
5. synchronization verification where authoritative/generated copies apply;
6. retained M1-M3 regression coverage proportionate to affected boundaries;
7. FS25 runtime verification when engine lifecycle, persistence, XML loading,
   or package behavior changes; and
8. a separate acceptance record before the next batch relies on its contract.

Static checks cannot substitute for an agreed FS25 persistence or lifecycle
gate. Synthetic fixtures must remain development-only and must not create a
public gameplay API.

## 9. Proposed Documentation Package

The architecture phase should determine exact repository-consistent names, but
is expected to create or reconcile:

- Subject Identity Architecture and definitions;
- Authority Request Contract;
- Game Time Contract;
- Persistence Compatibility and Migration Contract;
- External Identifier and Dependency Contract;
- Public API Evolution and Version Identity policy;
- XML Definition Registry architecture/component/state contracts;
- Cross-Domain Coordination Contract;
- M4 Architecture Review; and
- per-batch runtime verification records where applicable.

No single generic “FoundationManager” is proposed. Components remain separated
by ownership and dependency.

## 10. Approval and Execution Gates

Approval of this plan authorizes detailed M4.001 architecture work only unless
the approval explicitly authorizes more. It does not authorize all M4 batches
as one implementation operation.

For every batch:

```text
architecture and contracts
        -> review
        -> explicit approval
        -> bounded implementation
        -> tests/runtime evidence
        -> acceptance
        -> next dependent batch
```

Parallel architecture work is permitted only where the dependency graph shows
no unresolved dependency. Production implementation may not build against an
unapproved upstream assumption.

## 11. M4 STOP Conditions

STOP before editing production implementation if work would:

- redefine `player.local` or rewrite frozen M2/M3 state;
- require a stable subject source not approved by M4.001;
- let clients self-assert actor identity or mutate shared gameplay state;
- introduce a domain-specific clock or wall-clock progression;
- put domain migration rules in Save Manager;
- allow duplicate external IDs to select a winner by load order;
- permit definition overrides without a new approval;
- make XML providers or campaign packs runtime authorities;
- imply cross-domain rollback or introduce unbounded automatic retry;
- implement Character, Companies, Banking, Projects, Contracts, or Campaign
  gameplay;
- require a persisted-schema change to ForgeOS or Communications;
- require full network transport to make the current batch truthful;
- change framework/package/API/schema versions without explicit approval; or
- weaken a retained M1-M3 regression contract.

## 12. Review Questions Requiring Approval

The Project Director and Chief Architect should confirm:

The Project Director and Chief Architect approved all nine questions on
2026-08-22. Question 8 was approved with the M4.007 preflight/reservation
clarification incorporated above. Integer simulation minutes remain subject to
the existing M4.003 runtime-feasibility STOP.

## 13. Proposed Review Outcome

The plan was approved on 2026-08-22. Authorization extends to M4.001
architecture and contract design only. M4 remains unimplemented and unverified
until each approved batch passes its own gates and the combined milestone
receives explicit acceptance.
