# FORGE Subject Identity Definitions

**Status:** Review
**Version:** 0.1
**Milestone:** M4.001 — Subject Identity and Legacy Compatibility

## Purpose

Define the controlled vocabulary proposed for M4.001. These definitions become
an implementation contract only after explicit approval.

## Namespace and Version

```text
State namespace: forge.identity
Schema version:  1
```

The identity schema version is independent of `FORGE.Version`, the GIANTS
package version, ForgeOS versions, Communications versions, public API
versions, and later domain schemas.

## Subject Types

```text
player
organisation
system
```

Subject type values are lower-case, case-sensitive, and immutable for an
allocated subject.

## Subject Identifier Forms

```text
Generated player:       subject.player.<unpadded-positive-decimal>
Generated organisation: subject.organisation.<unpadded-positive-decimal>
Built-in system:         subject.system.forge
```

Validation rules:

- value is a string;
- value contains only lower-case ASCII letters, decimal digits, and dots;
- value contains no whitespace;
- generated decimal sequences contain no sign, padding, fraction, or exponent;
- generated sequence is greater than zero;
- category segment matches the stored `subjectType`;
- only approved built-in system identifiers are accepted; and
- the complete identifier is unique in the authoritative identity namespace.

The service, not the caller, selects generated identifiers.

## Binding Kinds

Initial binding kinds:

```text
legacyLocal
authorityPrincipal
```

`legacyLocal` accepts only the frozen compatibility key `player.local` during
M4.001. `authorityPrincipal` is reserved for an approved authenticated adapter;
its key schema is private to that adapter and is not defined by caller data.

## Subject Record Definition

```lua
{
    subjectId = string,
    subjectType = SubjectType,
    createdOrder = positiveInteger
}
```

No unrecognized or mutable domain/profile fields are retained in the detached
public record.

## Result Definitions

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

Meanings:

- `success`: requested identity operation completed authoritatively.
- `invalidArgument`: controlled input failed validation.
- `notFound`: valid subject or binding does not exist.
- `notAvailable`: operation is valid but unavailable in the current lifecycle
  or lacks an approved owning adapter.
- `bindingConflict`: principal/key or subject is bound incompatibly.
- `identityConflict`: duplicate or contradictory identity records exist.
- `incompatibleState`: persisted schema/state cannot be safely interpreted.
- `internalError`: unexpected implementation failure.

An identical existing binding is idempotent `success`, not a separate result.
The operation-result precedence is defined by Subject Identity Architecture.

## Diagnostic Source

M4.001 proposes the bounded Logger source:

```lua
FORGE.Definitions.LogSource.IDENTITY = "Identity"
```

Adding it belongs to the separately approved M4.001 definitions implementation
scope. Using `UNKNOWN` or a fabricated raw source is forbidden.

Diagnostics may include:

- controlled operation name;
- subject ID where already validated;
- binding kind without raw binding key;
- schema version; and
- controlled result category.

Diagnostics must not include credentials, tokens, raw authenticated principal
objects, or mutable service state.

## Ordering and Sequences

- `createdOrder` is a positive integer unique among retained subject records.
- `nextCreatedOrder` is greater than every retained `createdOrder`.
- `nextPlayerSequence` is greater than every retained generated player suffix.
- `nextOrganisationSequence` is greater than every retained generated
  organisation suffix.
- enumeration orders by `createdOrder`, then `subjectId`.
- conflicting duplicate groups are rejected as groups; iteration order never
  selects a winner.

## Controlled-Data Rules

- input tables are copied before validation where retained;
- returned tables are newly detached;
- unsupported value types, functions, userdata, threads, and cyclic tables are
  invalid;
- raw principal keys remain private binding data; and
- failure never returns an authoritative mutable reference.

## Compatibility Constant

M4.001 references but does not redefine:

```lua
FORGE.Definitions.ForgeOSPlayerId.LOCAL == "player.local"
```

No new Subject Identity definition aliases or replaces that ForgeOS constant.

## Non-Definitions

This document does not define:

- display names;
- roles or permissions;
- character, company, account, Project, or campaign IDs;
- external provider/definition IDs;
- platform account identifiers;
- network message formats; or
- public addon API versions.
