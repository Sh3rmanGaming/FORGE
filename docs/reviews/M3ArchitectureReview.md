# FORGE M3 Architecture Review

**Status:** Approved
**Milestone:** M3 - Communications

## Purpose

Record the M3.001 Communications architecture direction, review boundary,
remaining decisions, and authorization state without claiming implementation.

## Approved Direction

The Project Director and Chief Architect approved M3.001 documentation work on
2026-08-11 with these bounded directions:

- one built-in `forge.communications` application;
- Communications owns messages, inbox, read, archive, and badge truth;
- ForgeOS retains OS infrastructure ownership;
- initial identity is `player.local`;
- received messages only, with no deletion/editing/outbound semantics;
- SAVEGAME-backed bounded storage, monotonic identifiers, archived-first
  reclamation, unread protection, and deterministic repair;
- linked notifications remain alerts rather than message storage;
- reading a message may mark its linked notification read, never the reverse;
- dismissing a notification does not archive/delete its message;
- bounded detached presentation models and controlled actions;
- Phone/Laptop shared message state with independent navigation/presentation;
  and
- Laptop window/desktop architecture remains excluded.

These directions authorize specification, not M3.002 implementation and not an
automatic freeze of every low-level proposal.

## Review Set

- [Communications Architecture](../communications/CommunicationsArchitecture.md)
- [Communications Component Design](../communications/CommunicationsComponentDesign.md)
- [Communications Definitions](../communications/CommunicationsDefinitions.md)
- [Communications State Model](../communications/CommunicationsStateModel.md)
- [Communications Application Contract](../communications/CommunicationsAppContract.md)

## Proposed M3 Decomposition

1. M3.001 - Communications Architecture
2. M3.002 - Communications Definitions
3. M3.003 - Communications Manager
4. M3.004 - Communications Application Contract
5. M3.005 - Notification Integration
6. M3.006 - Phone Communications UI
7. M3.007 - Laptop Communications UI
8. M3.008 - End-to-End Verification and Polish

## Accepted Review Decisions

### Presentation adapter

The three proposed Engine/Host-facing ForgeOS methods, model
version 1 envelope, provider protocol, action outcome, result mapping,
side-effect-free query rule, re-entrancy guard, and declarative navigation
mediation are approved. These are additive integration contracts and do not alter existing
M2 method meanings.

### Notification creation boundary

The message-authoritative sequence is approved: commit the
message, request the optional alert, and retain a link only on alert success.
State Store provides no general cross-service transaction; alert failure leaves
the message readable and returns detached notification-result detail.

If notification creation succeeds but linkage commit fails, both records remain
without a fabricated Communications link. One controlled diagnostic and
detached failure detail are required; retry and restoration inference are
forbidden.

### Producer acquisition

M3 may use an in-process FORGE-owned producer and test-only fixture boundaries.
An external addon-facing Communications acquisition/public producer API is
deferred and must not be inferred from the ForgeOS export bridge.

### Action result layering

The layered result is approved: `ForgeOSResult` classifies the
new adapter operation, while a successfully invoked provider returns a detached
`completed/domainResult` outcome. This avoids treating controlled domain
rejection as callback failure and does not reinterpret existing M2 results.

## Non-Freeze Scope

- external producer API until explicitly approved;
- multiplayer/dedicated-server runtime behaviour;
- outbound delivery and conversations;
- arbitrary/third-party application rendering;
- generic widgets;
- source-derived badges;
- Laptop desktop/windows/focus/text input; and
- physical Laptop interaction.

## Implementation Gate

The Project Director and Chief Architect approved M3.001 on 2026-08-11. M3.002
Communications Definitions may proceed within its definitions-only scope. M2
remains closed and frozen within its accepted scope.

## M3.002 Implementation Status

The definitions-only implementation now provides the approved Communications
namespace/application identifiers, Message Channel, Message Priority,
Communications Result, Communications Event, and pure validation/detachment
helper. The component harness is loaded by the development test runner and all
authoritative files have synchronized prototype copies.

The authoritative [M3.002 Runtime Verification](M3.002RuntimeVerification.md)
records a passing FS25 development-suite gate and restored operational package.

## M3.002 Milestone Acceptance

The Project Director and Chief Architect accepted M3.002 on 2026-08-15. It is
authored, architecture-reviewed, approved, implemented, and verified.

The bounded freeze covers:

- `CommunicationsNamespace.STATE`;
- `CommunicationsAppId.COMMUNICATIONS`;
- Message Channel;
- Message Priority;
- Communications Result, including secondary notification failure detail;
- Communications Event;
- stable identifier validation; and
- controlled-data validation and detachment rules.

The freeze does not include message storage, Communications Manager,
persistence operations, message creation/read/archive, notification execution,
presentation providers or execution, UI, external producer APIs, multiplayer,
or outbound communications. M3.003 – Communications Manager is the next
implementation boundary and remains unstarted.
