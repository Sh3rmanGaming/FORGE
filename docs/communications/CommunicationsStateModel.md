# FORGE Communications State Model

**Status:** Approved
**Milestone:** M3.001 - Communications Architecture

## Purpose

Define the proposed authoritative runtime and persisted representation of the
initial Communications inbox.

## Namespace

Communications uses a distinct State Store and Save Manager namespace:

```text
forge.communications
```

It MUST NOT store message content beneath `forge.os`.

## Authoritative Shape

```lua
{
    schemaVersion = 1,
    players = {
        ["player.local"] = {
            messages = {
                ["message.1"] = {
                    id = "message.1",
                    playerId = "player.local",
                    source = "forge.example",
                    subject = "Welcome",
                    body = "Welcome to FORGE.",
                    channel = "system",
                    priority = "normal",
                    senderDisplayName = "FORGE",
                    metadata = {},
                    createdOrder = 1,
                    read = false,
                    archived = false,
                    notificationId = "notification.10"
                }
            },
            messageNextSequence = 2
        }
    }
}
```

`messages` is an identifier-keyed map. The map key must equal record `id`.
`createdOrder` is the positive integer sequence used to allocate the record and
defines deterministic ordering. `messageNextSequence` is the next positive
integer allocation value.

Absent optional fields are omitted rather than stored as `nil` placeholders.

## Runtime and Persisted State

All initial Communications messages are SAVEGAME records. Read, archived, and
linked notification identifier state persists with the record. Presentation
models, selection, scroll position, Host visibility, pointer state, and
device-specific navigation do not belong in this namespace.

## Capacity

The inbox is bounded. The private initial capacity may be 256 records but is
not a public compatibility definition.

When capacity is required:

1. reclaim the oldest archived record;
2. otherwise reject creation;
3. never silently reclaim an active unread or active read record.

Capacity rejection consumes no identifier and mutates no notification state.
The capacity policy is frozen only after M3 implementation acceptance.

M3.003 implements the private initial capacity as 256 records. This literal is
an implementation parameter, not an addon-facing or persistence compatibility
definition.

## Atomic Mutation

Every state-changing operation stages a detached namespace copy, validates the
complete candidate, then calls `StateStore:replaceNamespace` once. Failed
replacement changes neither authoritative message state nor sequence.

For a creation requesting a notification, M3.001 proposes an explicitly non-
transactional cross-service boundary: commit the message, request the optional
notification, then commit `notificationId` only when notification creation
succeeds. Failure retains the authoritative message without a link and returns
detached notification-result detail. No rollback-by-assumption or general
cross-service transaction is introduced.

If notification creation succeeds and this final linkage replacement fails,
the message remains without `notificationId` and the ForgeOS notification
remains intact. Communications emits one controlled diagnostic, reports the
linkage failure in detached detail, performs no automatic retry, and never
repairs the link by inspecting notification metadata.

The M3.005 integration definition uses notification source
`forge.communications`, metadata key `communicationsMessageId`, and a
declarative `forge.communications` `messageDetail` route carrying `messageId`.
These notification-owned values are never scanned to reconstruct missing
Communications linkage during restoration.

## Older State

The following are valid older-state conditions:

- namespace absent;
- `players` absent;
- `player.local` absent;
- `messages` absent; or
- `messageNextSequence` absent.

They initialize logically as an empty inbox and next sequence `1` without
disturbing unrelated namespaces or player records.

## Restoration Validation and Repair

Repair is staged and deterministic:

- discard malformed records;
- discard unsafe controlled data;
- discard records for unsupported player identities;
- discard every member of a duplicate message-id conflict group;
- discard every member of a duplicate `createdOrder` conflict group;
- never select a winner using Lua iteration order;
- normalize survivors by `createdOrder` for query output;
- preserve valid read/archive state and notification linkage;
- repair next sequence upward above every surviving `createdOrder` and valid
  stored sequence requirement;
- preserve unrelated namespace/player data;
- publish no Communications lifecycle event during repair;
- emit one concise development repair diagnostic; and
- expose no partially repaired state after failed replacement.

## Compatibility

After M3 acceptance, schema version 1, the namespace location, map
representation, record keys, boolean state representation, ordering, and
sequence semantics form a persistence compatibility boundary. Breaking changes
require schema review, migration/compatibility handling, persistence tests,
runtime restoration verification, and documentation review.

Additive optional fields must not reinterpret previously valid values.

## Save/Reload Requirements

Verification must prove:

- unread/read/archive state across a hard restart;
- identifier continuity with retained gaps;
- linked notification identity restoration;
- Phone and Laptop observe the same restored domain state;
- device navigation remains independently restored by ForgeOS; and
- malformed repair does not disturb `forge.os` or unrelated state.
