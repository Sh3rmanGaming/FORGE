# FORGE Communications UX Architecture

**Status:** Approved
**Version:** 0.1
**Review Boundary:** M2/M3 Presentation Foundation reopening

## Purpose

Use Communications as the reference application for the FORGE OS presentation
language while preserving the accepted received-message domain, persistence,
actions, notification integration, and cross-device truth.

## PF.003 Transitional Laptop Compatibility Amendment

PF.003 retains the existing Communications model-v1 active-app Laptop renderer
as a bounded compatibility exception. The Desktop shortcut and launch sequence
are generic App Registry/lifecycle behavior; Communications receives no
hardcoded Desktop tile or launch rule.

The v1 renderer receives only the trusted Laptop application viewport. It does
not own Desktop, global identity/status, OS Home/Desktop, device Close, future
toast-safe geometry, or another shell region. It gains no feature, schema,
domain behavior, or new layout system and is not available to another app.

PF.007 must migrate Communications Laptop presentation to model-v2 and remove
this branch. PF.007 acceptance cannot retain it without a new architecture
review. PF.003 does not begin that migration.

## Product Identity

Communications represents formal or detailed correspondence: customer and
supplier enquiries, project correspondence, quotations, finance or regulatory
notices, insurance, structured business documents, and longer NPC/company
correspondence.

A future Messages application is conceptually distinct: short conversational
exchanges, NPC texting, immediate updates, and informal communication. Messages
is not implemented or registered by this amendment.

## Preserved Domain Contract

Unchanged:

- `forge.communications` application/domain identity;
- `player.local` bounded recipient identity;
- message IDs and `createdOrder`;
- source, sender display fallback, subject, body, channel, priority, metadata;
- read/unread and archive authority;
- linked notification ID and M3 partial-success semantics;
- SAVEGAME persistence/schema version 1;
- asymmetric message-to-notification read propagation;
- no reverse-link inference;
- declarative notification message-detail route;
- no outbound messaging, replies, deletion, attachments, or threads; and
- same authoritative message/read/archive truth across devices.

## Device Presentations

Existing presentation IDs remain:

```text
forge.communications.phone
forge.communications.laptop
```

Presentation Resolver already selects them independently. The amendment changes
composition, not application or message identity.

## Laptop Information Architecture

Target composition:

```text
Mailbox Navigation | Message List | Reading Pane
```

Initial bounded mailbox navigation:

- Inbox: active messages;
- Archive: archived messages, read-only selection and reading;
- app title and exact unread attention badge.

The Laptop may render list and selected message together while the logical
route remains `inbox` or `messageDetail`. A `messageDetail` model may include a
detached active-message list for the Laptop view; Phone need not receive or
render that composition.

Message rows show sender, subject, complete-authority preview clipped by Host,
unread treatment, and selection. The reading pane shows sender, subject, body,
and existing Mark Read/Archive actions where valid.

No date/time is displayed as authoritative because schema version 1 has only
`createdOrder`, which is not a timestamp. Adding dates requires later
Communications domain/schema review.

## Phone Information Architecture

```text
Communications
      -> Inbox
          -> Message
```

Phone uses a compact list and separate detail route. It retains Back, app Inbox,
Mark Read, Archive, missing-message, empty, unavailable, and error behavior.
It does not reproduce the Laptop three-region composition.

Archive browsing may be introduced as a read-only route/section using existing
archived records, but must not add unarchive or deletion implicitly.

## Notification Deep Link

The existing linked notification destination is sufficient:

```lua
{
    appId = "forge.communications",
    routeId = "messageDetail",
    parameters = { messageId = "message.27" }
}
```

ForgeOS activates this logical destination; Communications continues to render
the controlled missing-message state if the message was reclaimed. Notification
activation may mark the notification read after successful navigation but does
not mark the Communications message read.

## Attention Badge

Communications remains badge authority through its active unread count.
Presentation maps that exact count to semantic `unread` attention. Notification
Service and Hosts do not derive it. Archived unread records remain excluded.

## Archive, Starred, Categories, and Sent Assessment

| Feature | Decision | Reason |
|---|---|---|
| Archive mutation | Retain | Already authoritative and persisted |
| Archive mailbox/view | Additive presentation extension | Existing records can be queried without schema change |
| Starred | Defer | Requires new authoritative message state and schema migration |
| Categories | Defer | Requires category authority, validation, and schema design |
| Sent | Defer | Outbound Communications is explicitly absent |

The UI may reserve adaptable navigation composition but must not render fake or
disabled Starred/Sent/Categories entries as if implemented. No speculative
persisted fields are added.

## Future-Compatible Non-Commitments

The view composition should not block later categories, structured attachments,
contextual actions, reply choices, project requests, quotations, finance
records, supplier orders, search/filtering, or conversation threading. None is
defined, persisted, exposed, or implemented now.

## Model Amendment

The current Communications provider returns strict v1 inbox/detail models. The
bounded amendment may add v2 device-specific declarative views while keeping v1
compatibility during migration/testing.

Requirements:

- models remain detached and side-effect-free;
- Phone and Laptop may include different view composition for the same route;
- application actions remain the accepted declared action IDs;
- Host never calls Communications Service directly;
- clipping/reflow/scroll remains Host presentation behavior;
- newest-first visual ordering does not mutate authoritative ordering; and
- model/action failure preserves layered ForgeOS/domain outcomes.

## Persistence and Migration

No Communications schema/version change or save migration is required for the
approved UX subset. Selected message remains logical Navigation state;
mailbox/list geometry and scroll remain runtime-only. Archive view derives from
existing archived records.

## Verification

- exact shared message identity/read/archive state across devices;
- distinct Phone and Laptop layouts from detached models;
- Laptop mailbox/list/reading-pane behavior;
- Phone list/detail behavior;
- Inbox and Archive presentation using existing records;
- message and notification read asymmetry;
- deep link to exact message and missing-message fallback;
- exact app attention count;
- no Starred/Categories/Sent/schema fields;
- no model mutation, direct domain access, or inferred navigation;
- accepted-save restoration unchanged; and
- retained M3.002-M3.008 and full M1-M3 regression gates.

## PF.004 Transitional Phone Amendment

PF.004 replaces Communications-specific Phone Home/launcher behaviour with a
registry-derived generic shell but does not begin Communications Phone UX work.
The current model-v1 active-app renderer remains the sole grandfathered Phone
exception inside the trusted application viewport. It receives no feature, UX,
layout architecture, persistence, API, notification ownership, Home ownership,
or new consumer and is not moved into PF.002 or generalized.

PF.008 owns the Communications Phone model-v2 view, approved compact Inbox/detail
UX, and mandatory removal of this branch. PF.008 acceptance cannot retain it
without a new architecture review.
