# FORGE Communications Architecture

**Status:** Approved
**Milestone:** M3.001 - Communications Architecture

## Purpose

Define the ownership, dependency, lifecycle, and integration boundaries for the
FORGE Communications subsystem.

## Scope

M3 initially delivers one received-message inbox through the built-in
`forge.communications` application. Sending, replies, drafts, attachments,
threads, multiplayer delivery, and desktop/window architecture are excluded.

This Review document becomes an implementation contract only after explicit
architecture approval.

## Player Outcome

Players can receive durable communications, see an accurate unread badge, read
or archive a message on Phone or Laptop, and observe the same message state on
both devices after saving and reloading.

## Architectural Layers

```text
Gameplay producer
      |
      v
Communications Manager -------- owns message truth
      |
      +----> Notification facade (optional linked alert)
      |
      v
Communications Application ---- adapts domain state
      |
      v
ForgeOS Presentation Adapter -- validates and detaches
      |
      +------------------+
      v                  v
 PhoneHost           LaptopHost
```

Communications is a gameplay-domain subsystem outside ForgeOS. ForgeOS owns
device registration, application registration, lifecycle, navigation,
notifications, Host orchestration, and presentation transport. Hosts own layout
and normalized input handling. No layer may bypass the public or bounded
integration contract of the layer below it.

## Application Identity

The single built-in application identifier is:

```text
forge.communications
```

`forge.messages`, `mail`, and `messages` are historical or conceptual labels,
not additional M3 application identities. A message channel may distinguish
system, mail-like, or conversational presentation later without splitting
authoritative storage.

## Ownership

Communications Manager exclusively owns:

- message identifiers and ordering;
- message records and controlled metadata;
- read and archive state;
- unread-message counts;
- retention and restoration repair; and
- linkage from a message to an optional notification identifier.

ForgeOS exclusively owns:

- device and application registration;
- application lifecycle and active-app state;
- device-specific navigation and resume;
- notification records and notification read/dismiss state;
- Host visibility and input routing; and
- validation and delivery of detached presentation models.

Message content MUST NOT be stored in `forge.os`. Notification records MUST NOT
be used as message storage.

## Identity and Authority

M3 uses `player.local` as its only resolved player identity. This is an
intentional compatibility boundary, not a claim of multiplayer identity or
authority. Message creation is local-process and locally authoritative during
the initial implementation.

## Message Lifecycle

The initial lifecycle is deliberately monotonic:

```text
received/unread --> read
active          --> archived
```

Read and archive operations are independently idempotent. Archiving does not
implicitly mark a message read. Reading does not archive it. There is no public
deletion, editing, reply, send, draft, delivery acknowledgement, or unarchive
contract in the initial milestone.

## Notification Relationship

A successfully created message may request one linked ForgeOS notification.
The message is authoritative even when notification creation fails. M3.001
proposes committing the validated message first, then requesting its optional
alert. Alert failure retains the message without `notificationId` and is
reported as detached creation detail; it does not turn Notification Service
into message storage or require a cross-service transaction.

If notification creation succeeds but the subsequent linkage commit fails,
both authoritative records remain: Communications retains the message without
fabricating `notificationId`, and ForgeOS retains the notification. The
operation reports controlled linkage-failure detail and one diagnostic, does
not retry, and restoration never guesses a reverse link from notification
metadata. Reading that unlinked message cannot propagate read state to the
notification. This accepted partial outcome is not a transaction guarantee.

Approved asymmetric semantics are:

```text
read message       --> mark linked notification read
read notification  -X-> read message
dismiss notification -X-> archive or delete message
```

Notification targets determine alert presentation. Message state is shared
domain state. The linked notification route may request navigation to a
message-detail route, but the notification service does not execute navigation.

## Presentation Boundary

M3 introduces a bounded ForgeOS-owned Application Presentation Adapter. It is
not a general widget framework and does not make application controllers public.

The adapter:

- identifies the active registered application and resolved presentation;
- invokes only a privately retained, approved presentation provider;
- validates phase, lifecycle, device, route, model, action, and parameters;
- returns detached controlled data;
- contains provider failure;
- applies validated navigation requests through ForgeOS; and
- exposes no domain manager, registry, service, State Store, or callback to a
  Host.

The initial production provider is FORGE-owned and belongs to the
Communications application. Third-party provider registration is not introduced
by M3.001.

## Dependency Rules

- Communications may call the public ForgeOS notification facade.
- Communications App may query Communications through its bounded domain API.
- Presentation Adapter may coordinate public ForgeOS lifecycle/navigation
  operations and invoke the private approved provider.
- Hosts may call only their detached Host context.
- Communications may not call Host implementations.
- Hosts may not call Communications Manager directly.
- No executable reference crosses the cross-mod export bridge.

## Startup and Shutdown

Proposed startup order:

```text
State Store available
    -> Communications namespace registration/defaults
    -> Communications restoration and repair
    -> forge.communications application registration during REGISTRATION_OPEN
    -> ForgeOS registration freeze/runtime activation
    -> Host presentation queries when visible and active
```

Shutdown stops presentation acquisition first, releases runtime provider
references, and clears runtime Communications state after persistence has had
its normal save opportunity. It publishes no synthetic read/archive event.

## Failure Isolation

- Invalid producer data mutates nothing.
- Failed message creation consumes no message identifier.
- Model query failure returns no readable model and emits at most one controlled
  diagnostic for an unexpected internal failure.
- Action failure returns a deterministic result and performs no ForgeOS
  navigation request.
- Listener failure does not roll back committed message state.
- Restoration failure exposes no partially repaired inbox.

## Compatibility Boundary

After M3 acceptance, the public message schema, identifier semantics, operation
results, event payloads, persisted subtree, and presentation model version form
compatibility contracts. Private table layout and helper functions do not become
addon APIs merely because they implement those contracts.

## Explicit Non-Scope

- outbound sending, replies, drafts, attachments, and threads;
- remote delivery, multiplayer identity, authority, or replication;
- dedicated-server runtime verification;
- user deletion, trash, spam, or unarchive;
- arbitrary application/controller rendering;
- third-party presentation-provider registration;
- generic widgets or schema-driven UI;
- Laptop windows, taskbar, z-order, focus, or persistent geometry;
- text entry; and
- physical in-world Laptop interaction.

## Accepted Review Decisions

1. The additive Host-facing ForgeOS presentation methods and layered action
   result protocol are approved as Engine/Host adapter contracts.
2. An addon-facing message-producer API is deferred beyond M3.002.
3. The message-authoritative, non-transactional notification sequence and its
   bounded partial-link outcome are approved.
