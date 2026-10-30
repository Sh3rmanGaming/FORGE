# Legacy Player Identity Compatibility Contract

**Status:** Review
**Version:** 0.1
**Milestone:** M4.001 — Subject Identity and Legacy Compatibility

## Purpose

Specify exactly how future stable subject identity coexists with the frozen
M2/M3 `player.local` contracts.

## Frozen Legacy Contract

The following remains unchanged:

```text
ForgeOS local player ID:        player.local
Communications recipient scope: player.local
ForgeOS persisted player key:   player.local
Communications persisted key:   player.local
```

Within those subsystems, `player.local` continues to mean the one bounded local
runtime/savegame player supported by their accepted contracts. It is not
renamed, migrated, promoted to global identity, or described as authenticated
multiplayer identity.

## Compatibility Mapping

The Identity Service owns a private one-way compatibility resolution:

```text
resolveLegacyPlayerId("player.local")
    -> success, "subject.player.1"
```

The exact generated subject may differ if valid restored identity state already
contains the accepted binding. Consumers must query the resolver and must not
derive the subject ID from the legacy string.

The mapping is persisted only inside `forge.identity`. Existing M2/M3
namespaces receive no backlink and remain unaware of the subject ID.

## Directionality

Approved direction:

```text
legacy player key -> stable subject ID
```

Forbidden reverse reinterpretation:

```text
stable subject ID -> rename/rekey legacy ForgeOS or Communications state
```

Future gameplay domains store subject IDs only. They must not use the resolver
to make `player.local` their own persistence key.

## Bootstrap Rules

When `forge.identity` is absent on a valid existing M2/M3 save:

1. preserve all existing namespaces untouched;
2. allocate the initial system and player subject records through the Identity
   Service;
3. bind `legacyLocal/player.local` to the allocated player subject;
4. expose the mapping only after the identity state commits atomically in
   memory; and
5. serialize it during the next normal authoritative save.

Repeated initialization in the same or later runtime must restore the mapping
and must not allocate another player subject.

## Failure Rules

- Unknown legacy player value returns `notFound` or `invalidArgument` according
  to the approved operation matrix; it never creates a binding.
- A missing namespace permits bounded first bootstrap.
- Once identity state exists, missing/conflicting legacy binding is not repaired
  by allocating another player subject.
- Malformed, duplicate, or future-version identity state returns a controlled
  incompatible/not-available outcome.
- Failure cannot alter ForgeOS or Communications state.
- Identity unavailability blocks future gameplay-domain ownership operations;
  it does not block the frozen local-only M2/M3 presentation/message behavior.

## Consumer Rules

- M2/M3 components continue using their existing resolver/constants.
- M4.002 requests use stable subject IDs after actor binding.
- M5 and later domain state stores stable subject IDs only.
- Hosts and applications never call the compatibility persistence internals.
- A presentation adapter may display detached subject-associated data but does
  not resolve authority.

## Compatibility Verification

Implementation evidence must prove:

- exact literal preservation of `player.local`;
- unchanged ForgeOS and Communications persisted trees;
- deterministic first bootstrap on an existing M3 save;
- the same stable subject after save, complete shutdown, and reload;
- no duplicate subject on repeated initialization;
- future gameplay ownership uses subject ID rather than legacy key;
- identity failure does not corrupt or reinterpret M2/M3 behavior; and
- no reverse mapping is written into frozen namespaces.

## Explicit Non-Scope

- converting historical messages/notifications into per-subject records;
- per-player multiplayer ForgeOS or Communications state;
- account linking or cross-save identity;
- player profile/display-name migration;
- public identity lookup for addons; and
- multiplayer completion claims.
