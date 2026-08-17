# FORGE Communications Definitions

**Status:** Verified
**Milestone:** M3.001 - Communications Architecture

## Purpose

Define the stable identifiers, enumerations, result values, events, and
validation terminology proposed for the initial Communications subsystem.

## Namespace and Identity

```text
State namespace: forge.communications
Application ID:  forge.communications
Player ID:       player.local
Message ID:      message.<unpadded decimal sequence>
```

Examples: `message.1`, `message.2`, `message.145`.

Every successful creation consumes one identifier. Failed creation consumes
none. Removed-by-repair or reclaimed records may create gaps. A valid stored
next-sequence value is never reconstructed downward from retained records.

## Message Channel

Initial controlled values:

```lua
SYSTEM = "system"
MAIL = "mail"
MESSAGE = "message"
```

Channels classify presentation; they do not create separate stores,
applications, delivery protocols, or sender authority.

## Message Priority

```lua
NORMAL = "normal"
IMPORTANT = "important"
```

Priority affects bounded presentation only. It does not bypass retention,
authority, lifecycle, or validation.

## Communications Result

Proposed domain results:

```text
success
invalidArgument
invalidDefinition
notAvailable
notFound
capacityExhausted
stateError
notificationCreationFailed
notificationLinkageFailed
internalError
```

Message creation may return detached detail describing the optional linked
notification result. Notification failure does not change an otherwise
successful message-domain result. Presentation-adapter operations map domain
outcomes to existing `ForgeOSResult` values and return domain outcome separately;
no existing M2 result meaning is changed.

`notificationCreationFailed` and `notificationLinkageFailed` are bounded
integration-detail values. They do not replace the authoritative main result of
a successfully committed message.

## Communications Events

Proposed completed events:

```text
communication.messageCreated
communication.messageRead
communication.messageArchived
```

Events publish only after authoritative commit. Payloads are detached plain
data containing the message identifier and the minimum changed state. No event
contains a controller, provider, service, Host, or full mutable record.

## Message Definition

Required producer fields:

```text
source
subject
body
channel
recipient
```

Optional producer fields:

```text
senderDisplayName
priority
metadata
notification
```

Generated fields:

```text
id
playerId
createdOrder
read
archived
notificationId
```

## Validation Rules

- Definition must be a table.
- `source` uses the existing non-empty/no-whitespace identifier rule.
- `subject` is a non-empty string.
- `body` is a string and may be empty.
- `channel` is one approved Message Channel value.
- `recipient` must equal the currently supported `player.local` identity.
- `senderDisplayName`, when present, is a non-empty string.
- `priority`, when absent, defaults to `normal`; when present it must be an
  approved Message Priority value.
- `metadata`, when present, uses controlled plain-data rules.
- `notification`, when present, is a controlled declarative notification
  request and may target only registered devices.
- Unknown fields are not retained.

Controlled plain data rejects functions, userdata, threads, non-finite numbers,
cycles, shared-reference graphs, metatables, non-string table keys, runtime/UI
objects, Hosts, controllers, providers, and other executable references.

## Notification Request

The proposed nested request contains:

```text
title          optional; defaults to message subject
body           optional; defaults to empty summary
severity       required when notification is present
persistence    required and must be savegame initially
targetDevices  required true-valued device set
```

The Communications layer supplies `source`, controlled metadata linking the
message identifier, and a declarative route to the Communications detail
surface. Producers cannot override that linkage.

## Operation Precedence

`createMessage`:

1. outer argument shape;
2. scalar schema;
3. channel/priority/recipient;
4. metadata controlled data;
5. notification request shape/data;
6. service availability;
7. registered notification targets;
8. retained-capacity availability;
9. identifier allocation;
10. staged message preparation;
11. authoritative message commit;
12. optional linked-notification request and link commit;
13. completed events.

### M3.005 notification integration

M3.005 replaces the temporary M3.003 deferral with the approved message-first
notification sequence. `createMessage` returns:

```text
CommunicationsResult, messageId | nil, detachedIntegrationDetail | nil
```

No notification request returns no detail. A requested notification returns
the actual ForgeOS result and notification identifier, when one was created.
The optional `integrationResult` is `notificationCreationFailed` or
`notificationLinkageFailed`; either partial integration outcome retains
Communications `success` and the committed message identifier.

Communications creates the notification with source `forge.communications`,
metadata `{ communicationsMessageId = messageId }`, and the declarative
`forge.communications` / `messageDetail` route whose parameters contain that
message identifier. An absent notification title defaults to message subject;
an absent notification body defaults exactly to `""`. Explicit strings are
preserved unchanged.

`markMessageRead` and `archiveMessage`:

1. identifier validation;
2. service availability;
3. retained-message existence;
4. idempotence;
5. authoritative commit;
6. optional linked-notification propagation for read;
7. completed event.

## Query Semantics

Proposed read-only queries remain primitive:

- `getMessage(invalid/unknown/unavailable)` returns `nil`;
- `getMessages(invalid/unavailable)` returns `{}`;
- `getUnreadCount(unavailable)` returns `0`;
- successful record/list results are detached;
- lists are oldest-to-newest by `createdOrder`.

As with M2 query APIs, callers do not infer diagnostic classification from an
empty query value.

## Implemented M3.002 Definition Package

The M3.002 implementation provides:

```text
CommunicationsNamespace.STATE = forge.communications
CommunicationsAppId.COMMUNICATIONS = forge.communications
MessageChannel
MessagePriority
CommunicationsResult
CommunicationsEvent
```

`FORGE.CommunicationsValidation` provides the approved identifier rule and a
pure controlled-data validation/detachment helper. It owns no state and performs
no logging, events, persistence, message validation, or domain operations.
