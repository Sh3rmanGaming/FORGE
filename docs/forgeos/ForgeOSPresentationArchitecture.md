# FORGE OS Presentation Architecture

**Status:** Approved
**Version:** 0.1
**Review Boundary:** M2/M3 Presentation Foundation reopening

## Purpose

Define the long-term presentation boundary shared by ForgeOS Hosts and logical
applications without moving gameplay truth into ForgeOS, applications, view
models, or UI state.

This document is not an implementation contract until the bounded Presentation
Foundation amendment receives explicit architecture approval.

## Architectural Finding

The existing ForgeOS foundation is structurally sound:

- App Registry owns one controlled logical application registration;
- Presentation Resolver already selects distinct Phone and Laptop
  presentations for that application;
- App Lifecycle Service already enforces one active app per device;
- Navigation Service already owns logical routes, parameters, bounded history,
  back behavior, and per-device resume state;
- Notification Service already owns notification records, targeting,
  persistence, read/dismiss state, and declarative destinations; and
- application providers already adapt authoritative state into detached models
  and declared actions.

The bounded amendment is needed because the POC Hosts hardcode application
rendering and permanent notification feeds. That approach cannot scale to the
future application ecosystem without making each Host a growing collection of
application-specific UI code.

## Preserved Ownership

| Concern | Owner |
|---|---|
| Gameplay/service truth | Owning gameplay domain or service |
| Logical application registration | App Registry |
| Device-specific presentation selection | Presentation Resolver |
| Application lifecycle and one-active-app invariant | App Lifecycle Service |
| Logical route, parameters, history, and resume | Navigation Service |
| Notification records/read/dismiss/targeting | Notification Service |
| Domain-to-presentation adaptation | Application provider |
| Shell, viewport, layout execution, drawing, hit testing, transient input | Device Host |
| Semantic visual language and bounded components | ForgeOS Presentation Foundation |
| Final palette/assets and UX specification | Approved Design Lead process |

## Presentation Flow

```text
Gameplay / Service State
          |
          v
Application Provider
  detached model + declared actions
          |
          v
Application Presentation Service
  validation + action mediation
          |
          v
Versioned Declarative View
        /   \
       v     v
 PhoneHost  LaptopHost
 compact     workspace
```

Applications never supply draw callbacks. A view is controlled plain data,
validated before it reaches a Host. Hosts interpret only approved component,
token, layout, and action identifiers.

## Device-Specific Presentation

The existing exact-device Presentation Resolver contract is retained:

```text
same App ID
same logical domain/service state
same logical route and destination
same declared domain actions
        |
        +---- phone presentation ID ---- compact composition
        |
        +---- laptop presentation ID --- desktop/workspace composition
```

Visual structure, viewport density, navigation chrome, and information
hierarchy may differ. Domain truth, message/project/account identity, and action
meaning may not.

No app duplicates authoritative data merely to support a second Host.

### Simultaneous Phone and Laptop presentation

Phone-over-Laptop presentation is intentional product behavior rather than a
temporary compatibility case. Phone is a right-side companion overlay that may
remain visible over central gameplay or a Laptop workspace. Phone and Laptop
therefore may be presented simultaneously, subject to their existing device
visibility and input-occlusion ownership.

Each Host retains independent lifecycle/presentation context and independent
runtime view-session state. Showing Phone does not close, reset, navigate, or
invalidate Laptop. Hiding Phone returns interaction naturally to the preserved
Laptop or gameplay state. Shared renderer infrastructure shares validation,
layout, rendering, and interaction semantics; it does not share scroll,
hover, press, last-safe, geometry, clipping, density, hit-region, or generation
state between devices.

Exact Phone width and placement, Laptop/Phone visual composition, palette,
typography, icons, notification appearance, and Communications layout remain
later Design Lead or separately gated decisions. PF.002 preserves the Host
seams needed for those decisions without selecting them.

A future tutorial, onboarding, Project, or mission system may present
instructions through an approved application/service path while progression is
derived from approved events or domain facts. Phone does not directly control
Laptop application state. PF.002 neither defines nor implements that future
system.

## Versioned Declarative View Protocol

The amendment should add a bounded view protocol alongside the accepted legacy
presentation-model protocol.

Conceptual envelope:

```lua
{
    modelVersion = 2,
    appId = "forge.communications",
    presentationId = "forge.communications.laptop",
    routeId = "messageDetail",
    title = "Communications",
    attention = { count = 3, state = "unread" },
    view = { ...approved declarative component tree... },
    actions = { ...declared application actions... }
}
```

Rules:

- protocol v1 remains valid during bounded migration and retained regressions;
- protocol v2 adds declarative composition rather than arbitrary code;
- every node type and property is allow-listed and depth/count bounded;
- layouts use semantic tokens and constraints, not gameplay objects or draw
  callbacks;
- interactive nodes reference a declared application action or a Host-owned
  shell action by identifier;
- Hosts create ephemeral geometry/hit regions from the detached view;
- action activation still flows through `performApplicationAction()`;
- application outcomes still use declarative navigation mediated by ForgeOS;
- providers cannot access Host objects, draw functions, input devices, State
  Store, Navigation internals, or mutable domain state through the view; and
- invalid views fail through the existing controlled model-failure path.

The canonical node and action-reference shapes, component contracts, text-flow
vocabulary, and Host action allow-list are frozen by the
[ForgeOS Declarative Presentation Protocol](ForgeOSDeclarativePresentationProtocol.md).
PF.002 must consume that contract without adding component fields or semantic
values implicitly.

Applications compose approved components using approved semantic properties,
tokens, and bounded constraints. They cannot provide arbitrary drawing
instructions, arbitrary style values, arbitrary pixel geometry, or executable
layout behavior. PF.001 owns the allow-listed vocabulary for direction,
alignment, distribution, spacing, padding, gap, size modes and constraints,
grow weighting, surfaces, borders, text roles/alignment, clipping/overflow,
selection, disabled state, and semantic state. This is deliberately not CSS or
a general browser layout engine.

Initial implementation should support only components required by the shells,
notifications, and reference Communications UX. Text entry, dialogs, complex
forms, data grids, drag/drop, controller focus, and third-party custom
components remain deferred until separately approved.

## Initial Component Boundary

The bounded initial vocabulary may contain:

```text
Layout.Stack
Layout.Row
Layout.Split
Layout.Scroll
Content.Text
Content.Icon
Content.Divider
Content.EmptyState
Control.Button
Control.IconButton
Control.NavigationItem
Control.ListRow
Indicator.Badge
Indicator.Status
```

This is not a generic window manager or arbitrary widget plugin system. It is a
controlled presentation vocabulary. Applications remain free to compose these
elements differently or use a later approved domain-specific component.

## Host Responsibilities

PhoneHost and LaptopHost own:

- device shell and global chrome;
- Home/Desktop launcher composition;
- safe area and application viewport;
- interpretation of the validated declarative view;
- semantic token resolution;
- layout, clipping, drawing, and bounded scrolling;
- transient hover/focus/pressed/scroll state;
- hit-region creation from currently rendered controls;
- primary pointer press/release semantics;
- input occlusion and delegation already owned by Engine/ForgeOS;
- session-local notification banner/toast queues; and
- Host-owned Home/Desktop and device-close controls.

Hosts do not own:

- gameplay or application-domain state;
- application route meaning;
- unread/attention truth;
- notification records;
- application lifecycle state;
- persisted UI trees or hit regions; or
- direct domain/service access.

PF.002 refines "interpretation" into shared presentation infrastructure plus
trusted per-device adapters. The shared renderer owns component semantics,
measurement, arrangement, text layout, token/state interpretation, and render-
plan construction. Each Host continues to own its viewport/profile, backend,
pointer ingress, input occlusion, shell actions, and independent runtime view
session. This is responsibility factoring, not a transfer of device state into
a global renderer.

## Shell Responsibilities

The shell is Host-owned and outside application view models. It provides:

- FORGE OS/device identity;
- Home/Desktop launcher and application icons;
- global status and control hints where justified;
- active-application viewport;
- OS Home/Desktop action;
- device-close behavior;
- transient notification region; and
- semantic theme/token context.

Applications must not redraw or impersonate shell-owned regions.

## Home, Back, and Close Semantics

- **Application Back** uses Navigation Service history or an approved app action
  that returns declarative back navigation.
- **OS Home/Desktop** closes the active application through the existing App
  Lifecycle Service and reveals the Host Home/Desktop.
- **Application Inbox/Home** remains an app action and never means OS Home.
- **Device Close** hides/closes the Host presentation through the existing
  device/Engine adapter; it does not redefine application navigation.
- **Minimise** is not a distinct M2/M3 state. A future minimise concept must be
  separately defined; the initial shell uses OS Home/Desktop.

## Notification Presentation Flow

```text
Notification Service commits record / transient creation
                 |
                 v
NOTIFICATION_CREATED completed event
                 |
                 v
Notification Presentation Coordinator
  validate target devices + derive presentation cue
              /      \
             v        v
 Phone banner          Laptop toast
 Host session queue    Host session queue
```

The proposed internal Notification Presentation Coordinator:

- consumes only completed Notification Service events/snapshots;
- never becomes notification authority;
- sends a detached presentation cue to each eligible operational Host;
- deduplicates one logical sound cue per notification creation;
- performs no persistence mutation;
- owns no permanent feed/history; and
- clears on ForgeOS shutdown.

Each Host owns animation time, stacking, clipping, hit regions, and expiry for
its own transient cue. Cue expiry does not read, dismiss, delete, or mutate the
notification record.

Notification sound uses an approved semantic cue identifier. Asset production,
mixing, and final sound family remain deferred to Design Lead approval.

### As implemented in PF.006

- `NotificationPresentationCoordinator` (internal) subscribes to the completed
  `NOTIFICATION_CREATED` event once ForgeOS is runtime-active and unsubscribes on
  shutdown. It holds a bounded pending list per device (16) and requests one
  sound cue per notification. Hosts take their cues through the private Host
  context function `takeNotificationCues`; there is no new public ForgeOS API.
- `NotificationCueView` (shared) owns each Host's session-only queue, timing,
  drawing and tap handling. Phone: one banner at a time, up to three waiting
  with a `+n` pill, five seconds each, shown even while the Phone is closed.
  Laptop: up to three stacked toasts, six seconds each, shown only while the
  Laptop is open; when full, the oldest leaves first.
- While a banner or toast shows, pointer mode (F6) can be entered even if no
  device is open, so a cue can be tapped.
- A tap calls the private Host context function `activateNotification`, which
  reaches `NotificationActivationService`. The Phone shows itself after a
  successful navigation.
- The base-game interface sound used for cues is a provisional placeholder; the
  first cue's sound outcome is written to the log.

## Notification Deep Linking

Existing notification destinations already contain:

```lua
{
    appId = "...",
    routeId = "...",
    parameters = { ... }
}
```

The amendment adds one ForgeOS-owned activation operation; it does not add a
second route system:

```text
activateNotificationDestination(deviceId, notificationId)
    preflight notification existence and target device
    preflight registered app and presentation availability
    preflight route existence and route-parameter schema
    openApp
    activateApp
    navigate using Navigation Service
    mark notification read only after complete navigation success
```

The current Navigation Service validates route existence and controlled plain
parameters, while the presentation adapter contains Communications-specific
validation for `messageDetail.messageId`. That hardcoded validation is not a
safe generic deep-link boundary. Add an optional declarative parameter schema
to the existing App Registry route declaration, for example:

```lua
messageDetail = {
    parameters = {
        messageId = { type = "identifier", required = true }
    },
    allowAdditionalParameters = false
}
```

Navigation Service enforces the declared schema for ordinary navigation,
resume restoration, and notification activation. Legacy routes without a
schema retain their existing controlled-plain-data behavior during transition.
Any route exposed as an actionable notification destination must declare its
parameter schema. This is an additive validation seam, not a second router or
application-specific Host rule.

All reasonably available side-effect-free validation completes before
`openApp()` or any other lifecycle mutation. Preflight does not reserve state
and cannot guarantee later success. The layered activation detail identifies
the terminal outcome as `validationFailed`, `openFailed`, `activationFailed`,
`navigationFailed`, `readUpdateFailed`, or `success`, together with the last
completed activation stage. `readUpdateFailed` means navigation succeeded but
the secondary notification-read update did not. No outcome fabricates
atomicity or rolls back completed lifecycle/navigation work.

The sequence stops immediately on failure and offers no cross-service rollback.
Failure leaves the notification record and current application/navigation state
as defined by each already-completed lifecycle step. The detailed layered result
and partial-outcome contract must be approved before implementation.

Activation never marks linked Communications or gameplay-domain state read.
Notification dismissal remains unrelated to domain archive/delete/read state.

## Application Attention and Badges

Badge truth remains application/domain-derived and side-effect-free. Hosts
never count notifications or domain records.

The current integer `getApplicationBadge()` contract remains compatible. The
private, optional controlled attention query
(`ApplicationPresentationService:getAttention()`) is implemented and frozen with
PF.002. PF.005 completes its Host projection; it does not add the query. The
attention model is:

```lua
{
    count = 3,
    state = "unread",       -- none | unread | attention | warning | error
    accessibleLabel = "3 unread messages"
}
```

Rules:

- `count` is optional or a non-negative integer;
- `state` is semantic, not a color;
- `none` means no application-level attention;
- `unread` means new or unread content exists;
- `attention` requests user action or awareness without inherently indicating
  warning or error;
- `warning` means a degraded, approaching-risk, or caution condition;
- `error` means a failed or blocked condition requiring awareness;
- `count` is independent of state and may be absent for every state;
- absent/unavailable attention returns `{ state = "none" }`;
- providers derive current truth on query; Hosts do not persist it;
- legacy badge `0` maps to `{ state = "none", count = 0 }`;
- a legacy badge greater than zero maps to `unread` with the exact count;
- notification source does not imply application ownership; and
- no `99+` domain cap changes the semantic value.

The attention model is an additive internal/provider extension. Public API
versioning must be reviewed before external exposure.

### PF.005 Host route (private)

PF.005 keeps attention private. Each Host reads attention only through the
Host-internal context that ForgeOS builds per device, by adding one function,
`getApplicationAttention(appId)`, beside the existing `getApplicationBadge`. It
calls the Application Presentation Service directly and returns the detached
attention model. Consequences:

- no new method on the public `FORGE.ForgeOS` table;
- no App Registry field, App API version change, or persistence change;
- no new provider protocol version; the provider method stays optional and the
  legacy `getBadge` mapping above applies when it is absent;
- Hosts display the returned state and exact count and never derive, count,
  cache, or persist attention; and
- Phone and Laptop project the same authoritative application truth
  independently.

Malformed semantic output fails closed to `{ state = "none" }` and is not
concealed by the legacy fallback.

### PF.005 presentation rules

Each state carries a non-colour cue (see the Design System):

- a count above 99 is shown as `99+`; the authoritative value is unchanged;
- `warning` and `error` may appear without a count;
- the accessible label stays in the model and is not drawn, because the FS25
  backend offers no presentation path for it; and
- no badge animation is introduced.

## Persistence Boundaries

No presentation-foundation amendment requires a persisted schema change:

- design tokens and final theme values are source/assets;
- view trees are detached runtime values;
- Host layout, animation, hover, pressed, focus, scroll, notification queues,
  and geometry are session-local;
- existing ForgeOS app/route resume remains authoritative and unchanged;
- existing notification state remains authoritative and unchanged; and
- existing Communications state remains authoritative and unchanged.

Future user theme/accessibility preferences require a separate state contract.

## Input Boundary

The first amendment retains accepted primary-pointer release semantics and
Phone-over-Laptop occlusion. The design system defines visual focus/disabled
states so later controller/keyboard support is not visually blocked, but it does
not implement a focus manager, text input, or controller navigation.

## Error and Availability Behavior

- A missing/invalid view retains the last valid route/model when safe.
- Without a prior view, the Host renders a bounded shell-owned unavailable
  state.
- Adapter/action failure does not infer navigation or mutate local domain state.
- Notification presentation failure does not change notification creation.
- Invalid deep-link destination does not fabricate a route or domain record.
- No Lua stack trace escapes the controlled diagnostic boundary.

## Prohibited Crossings

- Host or view state becoming gameplay truth;
- application draw callbacks or arbitrary code during Host draw;
- direct Host access to domain services, registries, or State Store;
- view nodes carrying mutable service/domain objects;
- a second App Registry, Navigation Service, or Notification Service;
- notification source-to-app inference;
- permanent notification feeds on Phone Home or Laptop Desktop in this scope;
- generic windows, z-order, resize/move, or multi-app rendering; and
- presentation schema migration solely for visual redesign.

## Verification Requirements

- legacy v1 presentation models remain controlled during transition;
- v2 view validation, bounds, detachment, and action references;
- distinct Phone/Laptop view composition for one app/route/data identity;
- Host shell/application ownership and primary-release behavior;
- one-active-app lifecycle and OS Home/Desktop behavior;
- transient banner/toast timing without notification mutation;
- deep-link success and each partial failure step;
- attention derivation and stale-value prevention;

## PF.003 Laptop Shell Reconciliation

PF.003 defines Laptop Desktop and global Laptop chrome as Host-owned shell
composition. The Desktop projects only registry applications that resolve as
available for Laptop, using existing identity/display metadata. An active
application replaces the Desktop workspace and receives the majority of a
trusted Host-derived viewport through the frozen PF.002 adapter. It cannot draw
or create hit regions in shell-owned identity, status, Home/Desktop, Close,
safe-margin, or future-toast-safe geometry.

The shell may arrange compact shortcuts, wallpaper/readability treatment,
identity, bounded status, contextual hints, and Host controls. It must not
understand application-domain concepts, render application content, maintain a
hardcoded app catalog, or branch on an app identifier. Dense application
composition remains generic PF.001/PF.002 work inside the delegated viewport.

PF.003 reserves lower-right geometry for future PF.006 Laptop toasts but adds no
toast behavior. It reserves a shortcut badge anchor for existing compatibility
and future PF.005 attention but creates no attention truth. Phone retains draw
and input priority in overlapping right-side geometry. Phone and Laptop keep
independent PF.002 sessions in both Desktop and Application Active states.

The complete boundary, geometry model, migration plan, and traceability are in
[FORGE OS Laptop Shell Architecture](ForgeOSLaptopShellArchitecture.md).
- no save-schema change and accepted-save compatibility;
- complete retained M1-M3 suite; and
- FS25 player-visible verification at expected resolutions/aspect ratios.

## PF.004 Phone Shell Reconciliation

PF.004 defines Phone Home and global Phone chrome as Host-owned companion-shell
composition. Home projects only registry applications eligible and resolvable
for Phone using existing metadata. An active app replaces the launcher interior
and receives a trusted Host-derived viewport through PF.002. It cannot draw or
create hit regions in identity/status, top-edge PF.006 seam, OS Home, Close,
safe-margin, or hint geometry.

The launcher uses deterministic profile-bounded pages, not a four-app domain
limit or shrinking grid. PF.005 attention and PF.006 banner behaviour remain
future seams only; PF.004 creates no attention or notification truth and generic
Phone shell input performs no notification mutation.

Phone remains a right-side independent Host over gameplay and Laptop. It claims
overlapping input first but shares no runtime presentation state. The sole
Communications v1 active-app exception is isolated inside the app viewport until
PF.008; generic model-v2 presentation remains application-agnostic. See
[FORGE OS Phone Shell Architecture](ForgeOSPhoneShellArchitecture.md).
