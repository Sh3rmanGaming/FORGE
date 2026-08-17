# FORGE Communications Application Contract

**Status:** Approved
**Milestone:** M3.001 - Communications Architecture

## Purpose

Define the bounded application, presentation-model, badge, and action contract
used to present Communications through the existing Phone and Laptop Hosts.

## App Definition

```text
id:         forge.communications
ownerId:    forge
apiVersion: 1
devices:    phone, laptop
```

Proposed routes:

```text
inbox
messageDetail
```

`inbox` is the default route. `messageDetail` requires controlled parameters:

```lua
{ messageId = "message.<sequence>" }
```

Phone and Laptop declare separate presentation identities while using the same
domain state.

The exact built-in presentation identifiers are:

```text
forge.communications.phone
forge.communications.laptop
```

## Presentation Adapter API

Proposed additive Host-facing ForgeOS operations:

```lua
ForgeOS:getApplicationPresentationModel(deviceId, appId)
    -> detachedModel | nil

ForgeOS:performApplicationAction(deviceId, appId, actionId, parameters)
    -> ForgeOSResult, detachedOutcome | nil

ForgeOS:getApplicationBadge(deviceId, appId)
    -> nonNegativeInteger
```

These methods are approved Engine/Host presentation contracts, not cross-mod
addon APIs. They do not change App API version 1. Their location on the ForgeOS
facade table is an integration convenience and does not make them part of the
ordinary external application API surface.

## Model Envelope

```lua
{
    modelVersion = 1,
    appId = "forge.communications",
    presentationId = "...",
    routeId = "inbox" | "messageDetail",
    title = "Communications",
    badgeCount = 0,
    content = { ... },
    actions = { ... }
}
```

Every model is a detached controlled plain-data tree. Unknown fields are
rejected during M3 rather than passed through to Hosts.

## Inbox Content

```lua
content = {
    kind = "communications.inbox",
    emptyText = "No messages",
    rows = {
        {
            messageId = "message.1",
            subject = "Welcome",
            sender = "FORGE",
            preview = "Welcome to FORGE.",
            channel = "system",
            priority = "normal",
            unread = true,
            archived = false
        }
    }
}
```

Rows are oldest-to-newest in the model. Hosts may visually reverse or window
the list only if the presentation contract later specifies that policy.

## Detail Content

```lua
content = {
    kind = "communications.messageDetail",
    message = {
        messageId = "message.1",
        subject = "Welcome",
        sender = "FORGE",
        body = "Welcome to FORGE.",
        channel = "system",
        priority = "normal",
        unread = false,
        archived = false
    }
}
```

Unknown or reclaimed detail identifiers produce a valid not-found model with a
bounded return-to-inbox action; they do not expose domain failure details.

The exact not-found content is:

```lua
{
    kind = "communications.messageDetail",
    message = nil
}
```

Inbox `preview` is the complete authoritative message body without
transformation. Sender display uses `senderDisplayName` when present and
otherwise uses `source`. Visual clipping remains Host-owned.

## Declared Actions

Initial action identifiers:

```text
communications.openMessage
communications.markRead
communications.archive
communications.openInbox
communications.back
```

Each model lists only currently permitted actions:

```lua
{
    id = "communications.openMessage",
    label = "Open",
    parameters = { messageId = "message.1" }
}
```

Hosts render only known bounded controls and return the action identifier and
detached parameters. They do not resolve handlers.

## Navigation Mediation

The provider never receives Navigation Service. It may return a declarative
navigation request. Application Presentation Service validates the destination
against the active app's registered presentation, then invokes the existing
ForgeOS navigation facade.

Opening a message requests `messageDetail`. Opening inbox/home requests the
default `inbox` route. Back uses existing `goBack`. A failed navigation does not
roll back a completed domain mutation.

Successful archive from message detail requests the default inbox route.
Successful or idempotent `markRead` remains on message detail and returns no
route-changing navigation. A missing or reclaimed `openMessage` returns
`completed = false`, `domainResult = "notFound"`, and no navigation while the
adapter delivery result remains `SUCCESS`.

## Badge Contract

The badge is the number of active unread Communications records. Archived unread
records are excluded from the launcher badge. The count comes from
Communications, not Notification Service and not `notification.source`.

Badge acquisition is side-effect-free, detached by value, and returns `0` for
unavailable/no-readable-result conditions. Hosts must not infer diagnostic
classification from zero.

## Query Contract

Model acquisition is side-effect-free. It must not:

- mark messages read;
- archive messages;
- mutate navigation;
- create notifications;
- change lifecycle; or
- retain Host/request references.

Unexpected provider/model failure returns `nil` and one controlled diagnostic.

## Action Result Mapping

```text
invalid argument/model parameters -> INVALID_ARGUMENT
ForgeOS not runtime active         -> NOT_AVAILABLE
device/app not registered          -> NOT_REGISTERED
app not active/eligible            -> NOT_AVAILABLE
action not declared                -> INVALID_ARGUMENT
provider domain rejection          -> SUCCESS plus completed=false/domainResult
provider exception/invalid outcome -> CALLBACK_FAILED
adapter internal failure           -> INTERNAL_ERROR
navigation failure after action    -> underlying ForgeOS navigation result
success                            -> SUCCESS plus detached outcome
```

This layered result protocol is intentional for the new action API:
`ForgeOSResult` classifies whether ForgeOS safely delivered and mediated the
request, while the detached outcome classifies the owning domain decision. It
does not reinterpret or add an M2 ForgeOS result.

## Phone Presentation

- one full-screen Communications surface inside Phone shell;
- inbox and detail routes;
- rounded launcher card may open the app after the action contract exists;
- back/home, read, and archive controls;
- no text entry or outbound composition.

M3.006 retains the Phone shell/header and replaces the Home interior while
Communications is active. The Host displays inbox rows newest-first through a
fixed four-row viewport, owns transient inbox/detail scroll offsets, and resets
the route-specific offset on route change. Launcher and ordinary notification
content are hidden while active.

Communications controls activate on primary-button release only when press and
release resolve to the same currently rendered Host-owned hit region. Inbox
rows invoke `communications.openMessage`; detail controls invoke only the
declared back, inbox, mark-read, and archive actions. Pointer wheel buttons move
the applicable bounded viewport. Keyboard/controller application navigation,
focus, text entry, and generic widget/controller execution remain deferred.

Phone clipping is deterministic and presentation-only: sender and subject are
single-line ellipsized values, preview is at most two visual lines, and detail
body draws only its scrolled viewport. Detached models are never reordered or
mutated. Missing detail renders `Message unavailable`; absent models render a
bounded unavailable state while a safe last model for the same route may remain
visible.

## Laptop Presentation

- one Communications surface inside the existing Laptop Host;
- inbox and detail routes;
- no windows, taskbar, z-order, movable geometry, or multi-app rendering;
- F8 remains development/fallback device activation only.

M3.007 retains the existing Laptop shell, header, footer, cursor behavior, and
Host chrome while replacing the Home interior with Communications content.
The normal launcher and notification panel are hidden while Communications is
active. A Host-owned Laptop Home control closes the current active application
through Lifecycle Service and is distinct from `communications.openInbox`.

Laptop inbox rows render newest-first through a deterministic fixed viewport.
The Host owns runtime-only inbox and detail scroll offsets, deterministic
Laptop-specific clipping, viewport selection, and hit regions without mutating
the detached model. Route changes, application closure, and Host restart reset
the applicable offsets; same-route hide/show may retain them.

The bounded M3.007 Laptop geometry uses six visible inbox rows, 64-character
sender/subject clipping bounds, two preview lines at 72 characters per visual
line, and thirteen detail-body lines at 88 characters per visual line. These
are deterministic Host presentation values, not Communications content limits.

Laptop application controls use primary-button release after press and release
within the same logical control. Rows and detail controls invoke only their
declared Communications actions through the presentation adapter. Badge truth
comes exactly from `getApplicationBadge`; notification state is not used to
derive it. Missing messages and adapter/model failures remain controlled and
cannot cause fabricated state or inferred navigation.

M3.007 application interaction is pointer-only. Keyboard/controller focus,
text entry, arbitrary controller execution, desktop/window architecture, and
multi-app rendering remain deferred.

## Cross-Device Semantics

Both Hosts query the same message records and badge truth. Read/archive changes
are immediately observable on both. Navigation and presentation remain
device-specific and independently persisted through ForgeOS.

## Security and Containment

Models/actions contain no executable reference. Providers receive no Host,
Engine, registry, State Store, or navigation object. Action parameters follow
controlled plain-data rules. Provider invocation is guarded against re-entrancy
and unexpected errors.

## Non-Generalization

This contract does not define arbitrary widgets, app-supplied drawing,
controller execution, third-party providers, text input, windowing, modal
ownership, drag/drop, animation, or persistent presentation geometry.
