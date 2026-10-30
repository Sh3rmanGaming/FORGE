# FORGE Foundation Assumption Review

**Status:** Approved
**Review Date:** 2026-08-17
**Accepted:** 2026-08-20
**Scope:** Post-M3 foundation and future-domain planning

## Purpose

Determine which early FORGE assumptions are safe foundations for later
gameplay domains and which require a compatibility seam or superseding
architecture before M4 begins. This is a documentation-only review. It does
not authorize gameplay-domain implementation and does not alter the accepted
M2 or M3 contracts.

The dependency-based M4-M9 sequence below was accepted on 2026-08-20 and is
the authoritative basis for post-M3 roadmap reconciliation. Acceptance does
not itself authorize M4 production implementation.

## A. Executive Findings

The existing separation between gameplay domains, ForgeOS, applications,
Hosts, notifications, and domain-specific state is a sound foundation and
should be retained. The blocking problems are above that layer:

1. `player.local` and savegame-global persistence are bounded M2/M3
   compatibility contracts, not a stable multiplayer subject model.
2. "multiplayer first" and "server authoritative" lack a common gameplay
   mutation boundary that future domains can implement against.
3. Time-dependent domains have no shared comparable game-time/deadline
   contract.
4. Projects cannot own money, company membership, qualifications, reputation,
   or experience merely because their owning domains do not yet exist.
5. XML-first authoring requires a definition/discovery foundation before
   Lua-first gameplay schemas become public facts.
6. Namespace schema versions exist, but future domains lack one common
   migration, repair, downgrade, and failure policy.
7. Cross-domain effects need an explicit authoritative-commit plus secondary-
   outcome policy; distributed rollback remains intentionally absent.
8. External content identifiers, dependencies, overrides, and API evolution
   require one shared policy before campaign/addon growth.
9. Several early documents and version labels no longer describe the accepted
   runtime accurately.

Stable identity, authority request handling, time, definition loading,
persistence migration, and external identifier policy must therefore form a
foundation milestone before Character, Companies, Banking, or Projects.

## Preserved Foundation Principles

The review found no contradiction requiring changes to these accepted rules:

- gameplay domains remain separate from ForgeOS;
- domain managers own gameplay truth;
- applications adapt domain state to presentation and do not own rules;
- State Store and persistence namespaces remain domain-specific;
- presentation models remain detached controlled data;
- notifications do not become authoritative gameplay records;
- cross-service rollback is never implicitly promised; and
- Phone and Laptop remain presentation Hosts, not gameplay authorities.

These rules are classified **RETAIN AND FREEZE** for future-domain design.

## B. Assumption Classification Matrix

| Assumption | Current evidence | Classification | Reason | Affected systems | Required action | Timing |
|---|---|---|---|---|---|---|
| M2/M3 local runtime identity is `player.local` | ForgeOS Definitions; Communications Architecture | **RETAIN TEMPORARILY WITH MIGRATION SEAM** | It is accepted and runtime proven for one local player but is not stable multiplayer identity. | ForgeOS, Communications | Preserve existing values; place future subject resolution behind an adapter. | Adapter contract in M4; no M2/M3 rewrite |
| Savegame-global M2/M3 persistence | ForgeOS State Model and M2/M3 reviews | **RETAIN TEMPORARILY WITH MIGRATION SEAM** | Existing state is valid, but future per-subject domains cannot equate a save with one player. | All future domains | New domains key ownership through stable subject IDs; define legacy local mapping. | Before persistent gameplay-domain schemas |
| Stable player/account/organisation identity may be inferred later | No accepted stable identity source | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | Retrofitting ownership IDs after Companies, Banking, or Projects would break schemas and permissions. | Progression, Companies, Banking, Projects, Campaigns | Introduce the Subject Identity contract below. | M4 foundation |
| Multiplayer-first means clients may call managers directly until networking exists | Vision versus local-process M2/M3 APIs | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | A local call cannot be assumed to be authoritative in multiplayer. | Every mutable gameplay domain | Require all gameplay mutations to enter through an authority request boundary. | M4 foundation |
| Server owns shared gameplay truth | Project Vision; Startup Lifecycle | **RETAIN AND FREEZE** | This is the correct long-term authority rule. | Every shared gameplay domain | Make single-player use the local authoritative server path. | Contract in M4; transport may follow later |
| Full network transport must exist before any domain code | No transport is currently approved | **DEFER WITH EXPLICIT RESTRICTION** | Domain logic can be built against an authority port without implementing replication immediately. | Networking, dedicated server | No client-authoritative mutation; no multiplayer-complete claim until transport/runtime verification exists. | Transport before multiplayer acceptance |
| FS25 simulation time is the only gameplay clock | Project Vision; Startup Lifecycle | **RETAIN AND FREEZE** | Prevents offline progression and competing clocks. | Progression, Banking, Projects, Campaigns | Route time-dependent decisions through one shared time provider. | Provider contract in M4 |
| Domains may interpret FS25 day/time independently | No shared deadline contract exists | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | Independent conversions create inconsistent deadlines and reload behavior. | Banking, Projects, Contracts, Campaigns | Introduce the Game Time contract below. | Before any duration/deadline state |
| A temporary Project balance/reward field is acceptable before Banking | Banking is planned after Projects in the old roadmap | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | It would make Projects a competing financial authority. | Projects, Companies, Banking | Define economic identities and implement Banking before reward settlement. | Economy architecture before Projects |
| Banking owns balances and transactions | Future Banking domain | **RETAIN AND FREEZE** | One ledger authority prevents competing money state. | Banking, Companies, Projects | Use account references and settlement requests; never direct balance mutation. | Banking milestone |
| Character eligibility may be embedded in Projects | Progression is absent from the current roadmap | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | Qualifications, reputation, and experience are reusable player truth. | Progression, Companies, Projects, Campaigns | Create Character and Progression domain contracts and eligibility queries. | Before Projects; recommended M5 |
| Qualifications, reputation, and experience are one unstructured value | Project Vision lists distinct progression concepts | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | They have different invariants and query needs. | Progression, eligibility consumers | One Character/Progression domain may coordinate separate qualification, reputation, and experience aggregates. | M5 architecture |
| XML-first and campaign-driven content | Project Vision and Engine Architecture | **RETAIN AND FREEZE** | This is the intended creator experience and should constrain schemas early. | All configurable gameplay domains | Definitions are immutable validated data; Lua supplies behavior adapters. | Foundation contract in M4 |
| Campaign packs own gameplay mutation | No accepted campaign authority exists | **DEFER WITH EXPLICIT RESTRICTION** | Content packages should provide data, not become runtime authorities. | Campaign SDK, all domains | Packs may register definitions only; domain managers own instances and mutations. | Freeze restriction in M4; SDK in M9 |
| Definition loading can be added after domains stabilize | Campaign SDK currently follows gameplay domains | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | Late loading/schema policy would invert XML-first architecture. | Progression, Companies, Banking, Projects | Build a Definition Registry/discovery/validation foundation first. | M4 foundation |
| Domain namespaces own state and schema versions | M2/M3 persistence contracts | **RETAIN AND FREEZE** | Ownership and versioning are proven and appropriately isolated. | All persisted domains | Each future namespace declares its current schema version. | Every domain from inception |
| Save Manager performs gameplay-schema migration | Early Persistence Format draft | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | Save Manager cannot know domain invariants. | Persistence and all domains | Save Manager orchestrates; each domain owns sequential detached migrations. | Common policy in M4 |
| Repair, migration, defaulting, and discard are interchangeable | Existing domains define local repair rules | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | Conflation risks silent data loss and incompatible save interpretation. | All persisted domains | Adopt the Persistence Compatibility contract below. | Before new namespace implementation |
| Cross-service rollback is not guaranteed | M3 notification integration | **RETAIN AND FREEZE** | M3 proved controlled partial outcomes are safer than fabricated atomicity. | Projects, Progression, Banking, Companies, Communications | Initiator commits authoritative state, then reports secondary outcomes explicitly. | Future cross-domain flows |
| Events may be treated as transactional commands | Event Bus and M2 open decisions | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | Listener failure and re-entrancy cannot control authoritative commit. | All domains | Events publish completed facts only; mutation requests use explicit domain/authority ports. | M4 coordination contract |
| Automatic retry is a harmless default | M3 explicitly forbids unapproved retry | **RETAIN AND FREEZE** | Retry without idempotency can duplicate rewards, progress, or notifications. | Cross-domain integrations | Retry requires an owning policy, stable operation ID, and idempotent receiver. | Before any retrying integration |
| Existing built-in IDs can define third-party content policy by analogy | ForgeOS App IDs and bridge are bounded precedents | **RETAIN TEMPORARILY WITH MIGRATION SEAM** | Existing identifiers remain valid, but runtime record IDs differ from external content IDs. | Definition Registry, Campaign SDK, addons | Establish the External Content Identity contract without changing M2/M3 IDs. | M4 foundation |
| Third-party replacement/override may be decided per domain | No common override policy | **DEFER WITH EXPLICIT RESTRICTION** | Per-domain override semantics invite collisions and save instability. | Campaigns and addons | Overrides/replacements are forbidden until a separately approved compatibility contract exists. | Restriction now; policy before enabling overrides |
| Public APIs evolve additively within explicit versions | ForgeOS bridge/App API precedent | **RETAIN AND FREEZE** | Version checks and additive evolution protect consumers. | Future SDKs and addons | Publish versioned capability surfaces; deprecate before removal. | Every public API |
| Engine and mod package version are one implicit number | `FORGE.Version=0.5.0-dev`; `modDesc=0.4.1.0` | **RETAIN TEMPORARILY WITH MIGRATION SEAM** | They can represent different compatibility axes, but the current relationship is undocumented drift. | Packaging, APIs, support, releases | Adopt the Version Identity policy below; record both in every build. | Before M4 package/version change |
| Early planning documents remain safe current guidance | Roadmap, Startup Lifecycle, legacy prototype docs | **SUPERSEDE BEFORE GAMEPLAY DOMAINS** | Several contain stale campaign, Phone, draw-order, and milestone claims. | Contributors and all future planning | Reconcile or label material historical/superseded without deleting history. | This review and before M4 authorization |

## C. Proposed Foundation Contracts

### Subject Identity Contract

Future gameplay domains use a stable `subjectId`, not a device-local or
presentation-local player value. A subject is one of:

```text
player
organisation
system
```

The identity boundary resolves:

- runtime connection/player identity to a stable player subject;
- organisation membership and roles to organisation subjects;
- ownership references to subject IDs;
- an authority context to an authenticated actor subject; and
- permission decisions separately from ownership.

`player.local` remains unchanged inside frozen M2/M3 state. A compatibility
resolver maps it to the active local player subject only when a future domain
needs to interoperate with legacy local state. No migration may reinterpret
the historical literal as a globally stable player identifier.

New gameplay-domain persisted records must not use `player.local` as their
final ownership key. Stable subject identity and legacy mapping must exist
before those schemas commit.

### Gameplay Authority Request Contract

Every shared gameplay mutation is submitted conceptually as controlled data:

```lua
{
    requestId = "<stable idempotency identity>",
    actorSubjectId = "<authenticated subject>",
    operation = "<versioned operation id>",
    parameters = { ... },
    authorityContext = { ... }
}
```

The authoritative server-side domain boundary:

1. authenticates the actor supplied by transport rather than trusting payload;
2. resolves permissions and ownership;
3. validates controlled parameters;
4. executes the authoritative mutation;
5. returns a controlled domain result and detached outcome; and
6. publishes committed state/facts for replication and presentation.

Single-player executes through the same logical authority boundary in the
local authoritative process. Clients, applications, Hosts, notifications, and
campaign content never mutate shared gameplay truth directly. Network event
shapes and replication implementation remain separately reviewable.

### Game Time and Deadline Contract

One FORGE Time provider adapts the authoritative server's FS25 simulation time.
Its comparable value is a non-negative integer `simulationMinute`, derived
deterministically from the authoritative FS25 day counter and time-of-day.

- persisted deadlines are absolute `simulationMinute` values;
- durations are non-negative integer simulation minutes;
- overdue means `now >= deadline` unless a domain explicitly documents a
  different boundary;
- pause stops advancement because FS25 time stops;
- time acceleration advances deadlines at the same simulated rate;
- save/reload restores the same absolute comparison basis;
- clients may format time but never decide authoritative expiry;
- calendar labels are presentation data and do not replace comparable time;
- real-world wall clock and offline elapsed time are excluded.

If FS25 cannot supply a monotonic save-stable day/time basis, time-dependent
domain implementation must STOP for a revised clock architecture.

### Economic Authority Contract

Banking owns accounts, balances, ledger entries, and settlement. The bounded
economic identities are:

- namespaced currency ID;
- generated account ID;
- stable owner `subjectId`;
- generated transaction ID; and
- caller-supplied idempotency/request ID.

Amounts use integer minor units under the currency definition. Balance changes
occur only through authoritative ledger transactions. Transfers and project
settlements return controlled success/failure and never permit Projects,
Companies, progression, UI, or campaign content to write balances directly.

Companies may exist before Banking, but may only retain an optional account
reference until Banking creates/links the account. Projects that promise a
financial reward require Banking settlement; no temporary Project wallet or
shadow balance is permitted.

### Character and Progression Contract

One Character/Progression domain coordinates three separately owned
aggregates:

- qualifications: authoritative granted/revoked credentials;
- reputation: namespaced scores or standings with explicit scope; and
- experience/progression: versioned tracks and committed progress.

Other domains submit progression requests or query a detached eligibility
decision. They do not retain duplicate qualification/reputation/experience
truth. Project definitions may declare requirements using stable progression
definition IDs; Project instances retain only the detached decision evidence
required by their approved audit contract, not shadow progression fields.

### XML Definition and Campaign Ownership Contract

A Foundation Definition Registry owns discovery, dependency ordering,
identifier collision checks, schema dispatch, and registration freeze.

- trusted built-ins and campaign/addon packages provide XML definitions;
- each definition declares a namespaced external content ID and schema version;
- required dependencies are validated before registration;
- validated definitions become immutable detached runtime definitions;
- domain managers create and own mutable instances derived from definitions;
- campaign packs cannot execute authoritative mutation through data alone;
- Lua implements registered behavior types/adapters, not per-content authority;
- definitions cannot be replaced or overridden after freeze; and
- arbitrary filesystem scanning is not an authority or discovery contract.

This foundation precedes gameplay schemas. The later Campaign SDK packages the
approved schemas, validation guidance, tooling, and creator-facing APIs; it
does not retroactively invent domain schemas.

### Persistence Compatibility Contract

The persistence document version and each domain namespace schema version are
separate.

```text
schema version  = representation contract for one namespace
migration       = explicit version N to N+1 transformation
repair          = deterministic cleanup within the current schema
additive default = explicitly approved missing-field compatibility rule
discard         = controlled rejection of one invalid record where permitted
incompatible    = namespace cannot be exposed safely
downgrade       = runtime is older than persisted namespace schema
```

Rules:

1. Save Manager owns document loading, namespace registration, ordering, and
   atomic application orchestration; it does not invent domain migrations.
2. Each domain owns sequential detached migrators from every supported version
   to the next version.
3. Migration operates on a detached loaded candidate and never edits the XML
   source during load.
4. Repair runs only after schema compatibility/migration succeeds.
5. Missing older fields receive defaults only when the domain contract defines
   them; malformed present fields are not treated as absent.
6. Failure exposes no partially migrated namespace and blocks that domain from
   authoritative operation.
7. A future/unsupported schema is never downgraded or overwritten. The domain
   remains unavailable and the next save must preserve safety rather than
   erase unknown state.
8. The next successful normal save may serialize the upgraded representation.
9. Backup/recovery uses the FS25 save lifecycle unless a separately approved
   backup facility is introduced.

M2/M3 repair semantics remain unchanged. Future adapters may migrate only when
their owning schema explicitly adds a new version.

### Cross-Domain Coordination Contract

The initiating domain owns the primary decision and commit. Secondary effects
follow a declared deterministic order:

```text
validate request
    -> commit initiating domain
    -> publish committed fact
    -> request ordered secondary effects
    -> return detached integration outcomes
```

- event listeners cannot roll back the initiating commit;
- secondary failure cannot be misreported as primary failure after commit;
- each secondary outcome identifies its owning domain and controlled result;
- retry is opt-in, owner-defined, bounded, and requires idempotency;
- receivers reject or return the prior outcome for duplicate request IDs;
- events publish completed facts and are not mutation commands;
- re-entrant mutation of the same aggregate is rejected or queued according to
  its domain contract;
- reconciliation belongs to a named coordinator/owning domain; and
- no generic distributed transaction framework is introduced by default.

For project completion, Projects commits completion once, then requests
progression, Banking settlement, Company updates, and Communications in an
approved order. The returned project outcome reports each integration result
without fabricating rollback.

### External Content Identity and API Contract

External definition IDs use:

```text
<registered-owner>.<domain>.<local-name>
```

`forge` owns built-in IDs. Addon/campaign owner namespaces derive from a
registered mod/content identity. Runtime-generated IDs such as `message.1` are
not external definition IDs and retain their existing contracts.

- duplicate external IDs reject the conflicting registration group;
- registration order cannot select a winner;
- required dependencies name an owner/package plus compatible API/schema
  range;
- optional dependencies cannot change base-definition validity;
- missing/incompatible required dependencies reject the dependent package;
- load order is deterministic after dependency validation;
- replacement and override are forbidden until separately approved;
- public APIs expose an integer major contract version plus capability checks;
- additive fields/operations require older consumers to remain valid;
- deprecation is documented before removal; and
- removal or breaking reinterpretation requires a new major version and
  migration/compatibility review.

### Version Identity Contract

The current values represent two potentially valid but undocumented axes:

```text
FORGE.Version = 0.5.0-dev  -> framework/runtime compatibility identity
modDesc       = 0.4.1.0    -> FS25 installable package version
```

The discrepancy is historical drift because no release record currently maps
the two deliberately. Neither value is changed by this review.

Future policy:

- `FORGE.Version` is the authoritative framework/runtime semantic version and
  may include a prerelease suffix;
- `modDesc.xml` is the authoritative FS25 package/update version using the
  GIANTS-compatible numeric format;
- public bridge/App/domain API versions remain separate small integers;
- every build/release record maps framework version, package version, commit,
  schema versions, and package hash;
- a package-version change never silently changes a public API contract; and
- M4 cannot publish a new package/version until the mapping is approved and
  recorded.

## D. Dependency Graph

```text
Accepted M1-M3 Foundation
        |
        v
M4 Foundation Contracts and Runtime Seams
  - Subject Identity / Authority
  - Game Time
  - Definition Registry / External IDs
  - Persistence Migration Policy
  - Cross-Domain Coordination
        |
        v
M5 Character and Progression
        |
        v
M6 Companies and Organisations
        |
        v
M7 Banking and Economy
        |
        v
M8 Projects and Contracts
        |
        v
M9 Campaign SDK and Content Packs
        |
        v
Future Public Release Gate
```

Companies precede Banking because accounts require stable owners. Banking
precedes Projects because reward settlement requires one balance authority.
Progression precedes both because qualifications and reputation affect company
roles and project eligibility. The Definition Registry precedes all domain
schemas; the creator-facing Campaign SDK follows stable domains so it can
expose rather than invent those contracts.

## E. Revised M4-M9 Recommendation

This recommendation is pending review acceptance and is not yet applied to the
roadmap milestone table.

### M4 - Foundation Contracts and Runtime Seams

Implement only the approved stable identity/authority boundary, shared game
time, XML Definition Registry, persistence migration orchestration seam,
external identifier/dependency policy, and cross-domain request conventions.
It must include local-authoritative operation without claiming multiplayer
transport completion.

### M5 - Character and Progression

Own player character identity linkage, qualifications, scoped reputation,
experience/progression tracks, eligibility queries, persistence, and detached
presentation integration.

### M6 - Companies and Organisations

Own organisation identity, membership, roles, permissions, assets/references,
and company lifecycle. Financial data remains an optional Banking reference;
Companies do not own balances.

### M7 - Banking and Economy

Own currency definitions, accounts, owner linkage, balances, ledger entries,
transfers, idempotent settlement, audit history, and authoritative economic
results.

### M8 - Projects and Contracts

Own project definitions/instances, offers, acceptance, assignment, objectives,
progress, deadlines, completion/failure, eligibility consumption, company
responsibility, Banking settlement requests, and Communications outcomes.

### M9 - Campaign SDK and Content Packs

Expose stable XML schemas, definition validation, dependency declarations,
creator documentation/tooling, campaign assembly, and built-in example
content. Campaign content remains data; domains remain authoritative.

The former Public Release milestone moves beyond M9 and requires separate
renumbering/authorization after this recommendation is accepted. Completed
M1-M3 history is never renumbered.

## F. Migration Impact

### Existing contracts valid unchanged

- M1 persistence document version 1 and State Store namespace registration;
- M2 `forge.os` state, `player.local`, bridge, lifecycle, navigation,
  notification, Phone, and Laptop contracts within their bounded local scope;
- M3 `forge.communications` schema version 1, message IDs, application model,
  notification linkage, and Phone/Laptop presentation contracts;
- domain-specific ownership, detached models, and controlled result layering.

### Future adapters required

- legacy `player.local` to stable local player `subjectId` resolution;
- local authoritative calls to the common gameplay authority request port;
- FS25 time to canonical `simulationMinute`;
- domain definitions to immutable Definition Registry records; and
- future Banking balances to any approved FS25 base-money integration.

### Future migration required

No M2/M3 migration is authorized now. Migration is required only if a future
approved schema version moves legacy state into stable per-subject ownership or
adds versioned fields. Such migration belongs to the owning domain and must
preserve the version-1 meaning.

### Contracts that must not be reinterpreted

- `player.local` must not be declared globally unique or silently replaced;
- savegame-global state must not be described as per-player multiplayer state;
- notification metadata must not reconstruct domain ownership/linkage;
- existing runtime-generated IDs must not be treated as external content IDs;
- Host visibility/navigation must not become gameplay authority; and
- M3 partial integration outcomes must not be retroactively described as
  transactional rollback.

## G. Documentation Reconciliation

| Document | Finding | Accepted resolution/status |
|---|---|---|
| `docs/roadmap/Roadmap.md` | M3 was shown current/in progress; historical M1 backlog looked planned | M3 marked complete; M1.008-M1.010 classified; accepted M4-M9 order applied on 2026-08-20 |
| `docs/architecture/002_StartupLifecycle.md` | Legacy campaign/Phone sequence and incorrect Host order | Set Review v1.1, describe accepted ForgeOS/Communications startup and Laptop-then-Phone drawing, close obsolete questions through accepted contracts |
| `docs/architecture/003_PersistenceFormat.md` | Draft overlaps implemented persistence docs and assigns domain migration to Save Manager | Mark Superseded; point to authoritative persistence documents and this review's pending migration policy |
| `docs/persistence/*` | Uses historical `Stable` lifecycle term | Retain current implementation contracts for now; normalize lifecycle labels in a separate bounded documentation pass after this review acceptance |
| Communications architecture/definitions/design/state/app contract | Accepted documents retain "proposed" wording | Replace only obsolete maturity wording with accepted/implemented terminology; do not change contracts |
| Prototype README/architecture/testing documents | Describe unloaded campaign/Projects prototype | Add prominent Historical/Superseded notices; retain content as history |
| `prototype/.../modDesc.xml` description | Claimed first XML campaign and live Projects app | Separately authorized metadata-only correction applied on 2026-08-20; versions, sources, dependencies, registration, and runtime behavior unchanged |
| `CHANGELOG.md` | Stops at M1 in progress | Record completed M1-M3 summary without rewriting historical entries |
| `docs/README.md` | Missing this review and authority classifications | Add review link and explain superseded persistence/prototype documents |
| `FORGE.Version` / `modDesc.xml` | Undocumented version-axis mismatch | Values remain unchanged; M4.008 must approve and verify the mapping policy before either advances |

Historical review/evidence records remain immutable even when they describe an
earlier project state.

## H. Version Reconciliation

`0.5.0-dev` and `0.4.1.0` are not normalized by this review. The first is
runtime framework metadata; the second is the FS25 package update version.
Because the repository never approved this distinction, their current mismatch
is classified undocumented drift rather than a deliberate release mapping.

The Version Identity Contract above makes both values authoritative only for
their own axis and requires a traceable mapping in every future build record.
Before M4 changes either value, the Project Director must select the next
framework/package versions and the Chief Architect must confirm whether any
public API or schema version changes with them.

## I. Remaining Deferred Decisions

These decisions may remain unresolved under the stated restrictions:

- exact FS25 network-event/RPC encoding: no multiplayer-complete claim and no
  direct client mutation;
- client replication granularity/caching: clients consume detached snapshots
  and cannot become authoritative;
- dedicated-server Phone/Laptop UI: Hosts remain unavailable there unless
  separately implemented;
- external definition override/replacement: forbidden until approved;
- cross-mod cursor/focus ownership and general widgets: future domains use the
  current bounded pointer-only Hosts;
- Laptop windows, multi-app rendering, text entry, and physical interaction:
  future presentations must fit current Host contracts or STOP;
- real-world/offline time: prohibited by the single FS25 simulation clock;
- general distributed transaction framework: not required; domain-specific
  coordination and explicit partial outcomes apply;
- automated retry/reconciliation service: no retry unless a flow defines
  idempotency, owner, limits, and diagnostics;
- public addon gameplay-producer APIs: unavailable until versioned authority
  and dependency contracts are implemented; and
- final public-release numbering: deferred until the M4-M9 reorder is accepted.

## J. STOP Conditions Before M4

STOP before gameplay-domain implementation if any of the following remains
unresolved or would be bypassed:

1. No stable `subjectId` and legacy `player.local` compatibility boundary.
2. Gameplay mutations would call local managers without an authority request
   seam.
3. A time-dependent record would persist a domain-specific clock/deadline.
4. A non-Banking domain would own a balance or settle money directly.
5. Projects would own qualifications, reputation, or experience fields.
6. Gameplay definition schemas would be implemented before identifier,
   discovery, dependency, and schema-version policy.
7. A new persisted namespace lacks sequential migration/failure rules.
8. Cross-domain completion assumes rollback or unbounded retry.
9. Third-party IDs or overrides depend on registration iteration order.
10. New package/version metadata lacks a recorded framework/package/API/schema
    mapping.
11. M4 work depends on the stale roadmap/startup/prototype claims identified
    by this review.
12. Implementing the foundation would require reinterpreting frozen M2/M3
    state instead of adding an explicit adapter or migration.

## Review Outcome

The Project Director and Chief Architect accepted this review on 2026-08-20.
Its classifications, compatibility conclusions, STOP conditions, and M4-M9
dependency order are the approved planning basis. M4 remains unstarted until
its architecture and decomposition receive separate approval; this acceptance
does not authorize gameplay-domain implementation.
