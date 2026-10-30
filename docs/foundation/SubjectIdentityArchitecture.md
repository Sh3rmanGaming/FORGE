# FORGE Subject Identity Architecture

**Status:** Review
**Version:** 0.1
**Milestone:** M4.001 — Subject Identity and Legacy Compatibility

## Purpose

Define the stable identity boundary used by future gameplay domains while
preserving the literal and bounded M2/M3 meaning of `player.local`.

This document is an architecture proposal. It does not authorize production
implementation until explicitly approved.

## Player Outcome

A player's future progression, qualifications, company relationships, accounts,
Projects, rewards, and campaign state can refer to one stable subject across
save/reload and authoritative requests without depending on the Phone, Laptop,
local client process, or the historical `player.local` storage key.

## Scope

M4.001 defines:

- the subject identity space;
- subject categories and identifier scope;
- authoritative allocation and lookup ownership;
- the local-player compatibility seam;
- persistence shape for identity records and bindings;
- detachment, validation, and controlled outcomes; and
- the ports consumed later by M4.002 and gameplay domains.

M4.001 does not define:

- authentication transport or network event encoding;
- permissions, roles, or policy decisions;
- organisation membership or company rules;
- display profiles, character data, progression, accounts, or Projects;
- external content/provider identifiers;
- public addon-facing identity APIs;
- cross-save global accounts; or
- migration of ForgeOS or Communications state.

## Identity Concepts

The following concepts are intentionally separate:

| Concept | Meaning | Owner |
|---|---|---|
| Runtime player identity | The currently resolved local/session participant used by an existing bounded subsystem | Existing subsystem resolver |
| Principal binding | Authority-private evidence that a connecting participant maps to a subject | Future authenticated authority adapter |
| Subject identity | Stable save-lineage identity referenced by gameplay-domain records | Subject Identity Service |
| Organisation identity | Stable subject representing an organisation | Identity allocation; M6 owns organisation truth |
| Ownership identity | A domain field referring to a subject that owns a record/resource | Owning gameplay domain |
| Authority identity | Actor subject bound into an authoritative request | M4.002 Authority seam |
| Permission identity | Subject and contextual policy inputs used to decide an operation | Future owning policy/domain |
| Savegame-global state | Shared state belonging to one authoritative save lineage | Existing persistence system |

A value in one column must not be silently substituted for another.

## Subject Categories

M4.001 defines exactly three initial subject categories:

```text
player
organisation
system
```

- A `player` subject represents persistent player-owned gameplay state within
  one authoritative save lineage.
- An `organisation` subject provides identity only. M6 exclusively owns
  organisation creation policy, membership, permissions, and lifecycle rules.
- A `system` subject represents an approved FORGE-owned actor where a domain
  operation legitimately has no player or organisation actor.

Categories are not interchangeable. A subject's category is immutable after
allocation.

## Identifier Contract

Subject identifiers use:

```text
subject.<category>.<authority-owned-key>
```

Initial generated examples:

```text
subject.player.1
subject.organisation.1
subject.system.forge
```

Rules:

- identifiers are case-sensitive ASCII strings;
- generated player and organisation keys are positive unpadded decimal
  sequences owned by the Subject Identity Service;
- callers never select generated identifiers;
- generated sequences are independent per category;
- `subject.system.forge` is the only built-in system subject in M4.001;
- an identifier is unique within one authoritative save lineage;
- an allocated identifier is never reused, even if a future owner retires it;
- the map key and stored record `subjectId` must match; and
- subject IDs are runtime-record identifiers, not M4.005 external definition
  identifiers or cross-save account identifiers.

Save-lineage scope is deliberate. Cross-save/global platform accounts remain
outside M4.001 and may later bind to a save-lineage subject without changing
domain-owned subject references.

## Authoritative Ownership

One internal Subject Identity Service owns:

- allocation of generated subject identifiers;
- immutable subject type truth;
- lookup and detached enumeration;
- principal-to-subject binding records accepted through approved authority
  adapters;
- legacy-local compatibility resolution; and
- identity namespace persistence.

It does not own:

- authentication of network participants;
- permission decisions;
- gameplay-domain records belonging to a subject;
- organisation membership or status;
- player display names or profiles; or
- external content namespaces.

No Host, ForgeOS application, Communications component, XML provider, future
gameplay domain, or client may allocate a subject ID directly.

## Subject Record

The detached conceptual record is:

```lua
{
    subjectId = "subject.player.1",
    subjectType = "player",
    createdOrder = 1
}
```

The record contains identity truth only. It intentionally contains no mutable
display name, permission, company membership, progression, account, device,
route, or notification data.

`createdOrder` is a positive authority-owned integer used only for deterministic
restoration and enumeration. It is not a timestamp and must not be interpreted
as rank, seniority, or permission.

## Principal Binding Port

M4.001 defines a private binding port for a future authenticated authority
adapter:

```text
resolveBoundSubject(bindingKind, authorityPrincipalKey)
bindSubject(bindingKind, authorityPrincipalKey, subjectId)
```

The binding key is supplied only by an approved authority adapter. It must not
come from caller-controlled request parameters.

Binding rules:

- one `(bindingKind, authorityPrincipalKey)` maps to at most one player subject;
- one player subject may have only the binding relationships explicitly allowed
  by a later approved authentication policy;
- rebinding, account linking, merging, and splitting are deferred and forbidden
  initially;
- bindings are authority-private and are not exposed in detached subject
  records; and
- absence of a stable multiplayer principal provider is a STOP for multiplayer
  identity acceptance, not a reason to use a client nickname, connection index,
  device, or `player.local` as a substitute.

M4.002 consumes the resolved actor subject. It owns request actor binding and
execution semantics; M4.001 does not authenticate requests.

## Local Authoritative Bootstrap

For the accepted single-local-player compatibility path:

1. Identity state restores from `forge.identity` when present and valid.
2. If no identity namespace exists, the authoritative local-server path
   allocates the first player subject as `subject.player.1`.
3. It records the private legacy-local binding from the literal
   `player.local` compatibility key to that subject.
4. The mapping remains stable for the save lineage and is written during the
   next normal save.
5. Existing ForgeOS and Communications state remains stored and queried under
   `player.local` exactly as before.

This is additive bootstrap of a new namespace. It is not migration of
`forge.os`, `forge.communications`, or their player maps.

## Lifecycle

```text
source files load
        |
        v
Identity definitions available
        |
        v
Save Manager provides detached forge.identity candidate
        |
        v
Identity Service validates/restores or performs bounded absent-state bootstrap
        |
        v
Legacy compatibility binding becomes resolvable
        |
        v
M4.002 may bind authoritative actors to subject IDs
        |
        v
Normal save serializes authoritative identity state
        |
        v
shutdown clears runtime references
```

Identity must be available before future gameplay-domain restoration because
their ownership fields reference subject IDs.

## Persistence Ownership

M4.001 proposes the domain-specific namespace:

```text
forge.identity
```

Conceptual schema version 1:

```lua
{
    schemaVersion = 1,
    nextCreatedOrder = 3,
    nextPlayerSequence = 2,
    nextOrganisationSequence = 1,
    subjects = {
        ["subject.system.forge"] = {
            subjectId = "subject.system.forge",
            subjectType = "system",
            createdOrder = 1
        },
        ["subject.player.1"] = {
            subjectId = "subject.player.1",
            subjectType = "player",
            createdOrder = 2
        }
    },
    bindings = {
        legacyLocal = {
            ["player.local"] = "subject.player.1"
        }
    }
}
```

The system subject may be created during new/absent-state bootstrap. Sequence
repair must consider every retained generated identifier and created order.
Duplicate/conflicting identity records are never resolved by iteration-order
winner selection.

Until M4.004 is implemented, M4.001 supports only absent state and schema
version 1. A future schema, malformed subject identity, conflicting binding, or
identity collision returns a controlled incompatible/not-available outcome and
must not silently regenerate identities. Silent regeneration could orphan every
future domain reference.

## Controlled Operations

The initial internal contract is conceptually:

```text
getSubject(subjectId) -> result, detachedSubject|nil
listSubjectIds(subjectType?) -> result, detachedIds|nil
resolveLegacyPlayerId(legacyPlayerId) -> result, subjectId|nil
resolveBoundSubject(bindingKind, authorityPrincipalKey) -> result, subjectId|nil
allocateSubject(subjectType) -> result, subjectId|nil
bindSubject(bindingKind, authorityPrincipalKey, subjectId) -> result
```

Constraints:

- queries return detached controlled plain data;
- enumeration is deterministic by `createdOrder`, then `subjectId`;
- `allocateSubject(organisation)` provides identity only and is unavailable to
  general callers until M6 supplies an approved organisation creation port;
- `allocateSubject(player)` is available only to an approved authority/bootstrap
  adapter;
- system-subject allocation is not public; and
- no operation accepts a caller-selected generated subject ID.

Allocation consumes its category sequence and `createdOrder` only after the
subject record commits successfully. Failed allocation consumes neither.

Binding the same key to the same subject is idempotent and returns `success`
without another mutation or event. Binding that key to a different subject, or
violating an approved one-to-one rule, returns `bindingConflict`.

## Controlled Results

M4.001 proposes these domain results:

```text
success
invalidArgument
notFound
notAvailable
bindingConflict
identityConflict
incompatibleState
internalError
```

Expected absence or rejection is a controlled result, not an escaping Lua
error. Unexpected failures emit one controlled Identity diagnostic and return
`internalError` without exposing mutable service state.

Exact Lua identifiers and result representation belong in the separately
approved implementation definitions contract.

Default validation precedence is:

1. invalid argument or uncontrolled data;
2. Identity lifecycle unavailable;
3. unknown subject/binding;
4. subject-type or binding-policy mismatch;
5. identical idempotent binding success;
6. binding or identity conflict;
7. authoritative commit success; and
8. unexpected internal failure.

An operation-specific contract may omit inapplicable steps but may not reorder
them without explicit architecture approval.

## Detachment and Privacy

- Every returned table is newly detached.
- Mutating a returned record cannot change authoritative identity state.
- Principal binding keys are never returned by ordinary subject queries.
- Diagnostics use controlled subject IDs and result categories; raw platform
  credentials, tokens, or mutable authentication objects are prohibited.
- Display names are presentation/profile data and never identity authority.

## Compatibility With M2 and M3

M4.001 must not modify or reinterpret:

- `FORGE.Definitions.ForgeOSPlayerId.LOCAL = "player.local"`;
- ForgeOS `players["player.local"]` persistence and runtime state;
- Communications `players["player.local"]` persistence and recipient rules;
- existing notification/message IDs or linkages;
- Phone/Laptop navigation, badge, lifecycle, or presentation state; or
- any accepted M2/M3 public or persistence version.

The only bridge is:

```text
legacy runtime/storage identity "player.local"
        |
        v
private compatibility resolver
        |
        v
stable save-lineage subject "subject.player.1"
```

Reverse inference is forbidden: a future subject ID must not be written into
old player maps or used to rename their keys.

## Multiplayer Boundary

This architecture prepares for multiplayer but does not claim multiplayer
identity completion.

Before multiplayer acceptance, a later approved adapter must prove:

- a server-authenticated stable principal source;
- deterministic reconnect/reload binding;
- join/leave behavior;
- duplicate-session policy;
- privacy-safe persistence and diagnostics;
- server-only allocation and binding; and
- client receipt of detached subject identity without authority escalation.

If FS25 cannot provide the required stable principal source, work must STOP for
multiplayer identity and return for architecture review. It must not fall back
to nickname, connection order, device identity, or client-selected IDs.

## Verification Requirements

Architecture-approved implementation must prove:

- exact subject categories and identifier validation;
- server-owned deterministic allocation;
- no caller-selected generated ID;
- immutable type and non-reuse;
- detached queries and private bindings;
- `player.local` resolves through the compatibility seam;
- existing M2/M3 state remains byte/meaning compatible;
- absent identity state bootstraps once;
- save/reload restores identical subject and binding;
- sequence continuation does not collide;
- malformed/future/conflicting state does not regenerate identity;
- organisation identity allocation remains unavailable without its future owner;
- no Host, app, XML provider, or client becomes identity authority; and
- retained M1-M3 regression suites continue to pass.

Definitive persistence evidence requires an FS25 save, complete shutdown, new
process, and reload when M4.001 reaches implementation verification.

## STOP Conditions

STOP if implementation would:

- change the value or meaning of `player.local`;
- migrate or rename M2/M3 player maps;
- treat a display name, connection index, device, or client parameter as stable
  identity;
- expose raw principal binding keys through public queries or diagnostics;
- allow client/caller-selected subject IDs;
- make Identity own permissions, organisation rules, progression, accounts, or
  Projects;
- silently regenerate missing/conflicting identities after the namespace has
  existed;
- require a ForgeOS or Communications schema/version change;
- expose a public addon API before M4.005; or
- claim multiplayer identity without runtime proof of a stable authenticated
  principal source.

## Deferred Decisions With Restrictions

- Exact FS25 multiplayer principal source: deferred to the authority/transport
  adapter; no multiplayer identity claim until proven.
- Cross-save/global account linking: deferred; subject IDs are save-lineage
  scoped and must not be presented as global accounts.
- Account merge/split/rebinding: deferred and initially forbidden.
- Subject retirement/deletion: deferred; allocated IDs cannot be reused or
  silently removed.
- Organisation creation policy: deferred to M6; M4.001 supplies identity only.
- Public addon identity API: deferred to M4.005 versioning and exposure review.

These restrictions make the decisions safe to defer without forcing later
gameplay domains back onto `player.local`.

## Exit Criteria

M4.001 architecture is ready for implementation approval only when:

1. subject categories, scope, format, and allocation ownership are approved;
2. the principal binding port and multiplayer STOP boundary are approved;
3. absent-state bootstrap and `forge.identity` schema are approved;
4. the legacy compatibility contract is approved without M2/M3 reinterpretation;
5. controlled operations/results and privacy boundaries are approved;
6. tests and hard-restart evidence requirements are approved; and
7. no downstream gameplay domain or M4.002 authority execution has been
   implemented.
