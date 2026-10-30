# ForgeOS Application UX Contract

**Status:** Approved
**Version:** 0.1
**Review Boundary:** M2/M3 Presentation Foundation reopening

## Purpose

Define common behavioral expectations for FORGE applications while preserving
device-appropriate information architecture and domain ownership.

## Application Identity

Every application declares through the existing App Registry:

- stable App ID;
- display identity;
- icon identity;
- supported Hosts/devices;
- device-specific presentation declarations;
- logical routes and declared actions; and
- supported application/presentation protocol versions.

Application IDs and route IDs are not translated display strings.

## Ownership

Applications may:

- query approved detached domain/service models;
- format detached content for presentation;
- define device-specific view composition;
- own bounded runtime-only presentation state through the Host/view boundary;
  and
- expose user intent through declared actions into approved domain/service
  authority ports.

Applications may not:

- own unrelated gameplay truth;
- mutate domain state outside approved authority boundaries;
- access Host geometry, State Store, registries, or service internals directly;
- persist clipped strings, view trees, hit regions, or shadow domain values; or
- execute arbitrary drawing/input callbacks.

## Device Separation

```text
Phone layout != Laptop layout
```

Phone and Laptop presentations may choose different composition, density,
viewport, and local navigation controls. They use the same logical application,
domain identities, action meaning, and ForgeOS route destination.

Central design rule:

```text
same application + same logical data + same actions + same destination
does not require the same composition
```

## Logical Navigation

- Global logical destinations use Navigation Service routes and detached plain
  parameters.
- Routes may declare a bounded parameter schema in their existing App Registry
  declaration. Navigation validates that schema consistently for direct
  navigation, resume, and deep-link activation. Notification-actionable routes
  must declare one; legacy routes without one retain controlled-plain-data
  validation during transition.
- App-local controls may change local selection or invoke declared actions, but
  any state that must support back/resume/deep-link behavior belongs in a route
  or approved route parameter.
- Back uses Navigation history or an app action that returns declarative back.
- App Inbox/Home means the app's own root route.
- OS Home/Desktop closes the active app through lifecycle and is Host-owned.
- Apps do not implement a competing global navigation stack.

## Shell Separation

Applications do not duplicate:

- Laptop Desktop;
- Phone Home;
- global device status;
- global notification banner/toast presentation;
- global application launcher;
- OS Home/Desktop and device-close controls; or
- global pointer/input-mode hints.

The shell may delegate an explicitly documented viewport/header slot, but the
application cannot assume ownership from pixels alone.

## View Contract

Applications return a validated detached presentation model using an approved
protocol version. Interactive view elements reference declared action IDs and
controlled parameters. Hosts own drawing and hit regions; Application
Presentation Service owns provider invocation, validation, re-entrancy guards,
action mediation, and navigation outcomes.

## Attention Contract

Applications derive their own attention truth from the owning domain/service.
They may expose a controlled count and semantic state. Hosts display it but do
not persist, increment, cap, or reconstruct it from notifications.

## Visual Consistency

Applications share:

- semantic tokens;
- typography roles;
- spacing scale;
- icon family;
- interaction-state meaning;
- component behavior;
- motion principles;
- accessibility baseline; and
- navigation expectations.

They do not share one mandatory dashboard layout. Appropriate examples:

```text
Communications -> mailbox and reading workflow
Projects       -> project/work management
Banking        -> financial and ledger workflow
Companies      -> organisation management
Fleet          -> equipment-oriented workflow
Progression    -> character and eligibility presentation
```

## Failure Contract

- Empty, unavailable, and error are distinct controlled states.
- Model failure retains the last safe view where possible.
- Action failure performs no inferred navigation or local domain mutation.
- Missing deep-linked content renders the application's controlled unavailable
  state with valid navigation controls.
- A Host never fabricates gameplay records or action success.

## Input Contract

The bounded amendment retains primary-pointer release activation and same-
control press/release validation. Designs must define focus/disabled visuals for
future input methods, but controller/keyboard application navigation and text
entry remain deferred until separately approved.

## Persistence

Applications do not persist visual layout. Logical resume remains in ForgeOS
Navigation state. Domain/service state remains in its owner. Host view state is
runtime-only unless a separately approved preference contract explicitly says
otherwise.

## Reference Application

Communications is the initial reference application for the presentation
foundation. Its implementation proves shared semantics with different Phone
and Laptop composition. It does not define a universal application template.
