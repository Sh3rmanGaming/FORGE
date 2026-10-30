# ForgeOS Declarative Presentation Protocol

**Status:** Implemented, Verified, Accepted and Frozen  
**Protocol Version:** 2  
**Scope:** PF.001 bounded contract clarification

## Purpose

Define the exact controlled-data shape, component contracts, text-flow
vocabulary, and action references consumed by the future PF.002 validator and
shared Host renderer. This document defines protocol data only. It does not
implement validation, layout, rendering, input dispatch, or Host redesign.

## Canonical View Node

Every model-v2 `view` contains exactly one root node using this shape:

```lua
{
    component = "content.text",
    id = "optional.local.node.id",
    properties = {
        text = "Detached controlled text"
    }
}
```

The canonical top-level fields are:

| Field | Required | Contract |
|---|---:|---|
| `component` | yes | Exact value from `PresentationComponent` |
| `id` | no | Controlled identifier unique within this view; runtime presentation identity only |
| `properties` | no | Plain table containing only properties allowed by the component contract |
| `children` | by component | Contiguous plain array of canonical child nodes |

Unknown top-level fields are rejected. `component` cannot be inferred from
properties or children. `id` is never persisted and does not identify a domain
record, route, action, or authoritative object.

Nodes, properties, action references, and children must be detached controlled
plain data. Metatables, functions, threads, userdata, executable callbacks,
Host objects, service objects, and domain objects are invalid. Cycles and
shared mutable aliases are invalid. The limits in `PresentationLimit` apply to
the complete root tree.

Child policy has these exact meanings:

- `required`: `children` must be present and contain between the component's
  minimum and maximum child count;
- `allowed`: `children` may be omitted; when present it is a contiguous array
  within the component's minimum/maximum count; and
- `forbidden`: `children` must be absent. An empty child table is not accepted
  as a substitute.

## Property Value Rules

- `text` and `accessibleLabel` are strings bounded by `MAX_TEXT_LENGTH`.
- `iconId` is a controlled identifier; it is not a texture path or drawing
  callback.
- spacing, padding, gap, minimum, and maximum sizes use approved semantic size
  or spacing tokens only; raw pixel values are invalid.
- width/height modes, direction, alignment, distribution, grow, clipping, and
  overflow use their corresponding PF.001 definition values.
- `selected` and `disabled` are booleans.
- `count` is a non-negative integer and remains exact.
- `semanticState` uses `PresentationSemanticState`; it never carries a raw
  colour or style value.
- `actionReference` uses the controlled object defined below.

Absent properties use these protocol defaults:

| Concern | Default |
|---|---|
| Stack direction | `vertical` |
| Split direction | `horizontal` |
| Scroll direction | `vertical` |
| Alignment/distribution | `start` |
| Spacing/padding/gap | zero semantic space |
| Width/height | `auto` |
| Minimum/maximum size | no additional constraint |
| Grow | no weighted growth |
| Surface/border | none |
| Clipping | `bounds` |
| Overflow | `hidden` |
| Text role/alignment | `typography.body` / `start` |
| Selected/disabled | `false` |
| Semantic state | `none` |

`spacing` is separation requested around a node in its parent flow. `padding`
is the inset between a component's bounds and its content. `gap` is separation
between that component's children. Absence means zero; applications cannot
supply arbitrary numeric spacing.

## Text Flow

The exact text-flow properties are:

| Property | Values | Contract |
|---|---|---|
| `textWrap` | `none`, `word` | Whether text forms one unwrapped line or wraps at deterministic word boundaries |
| `maximumLines` | positive integer | Optional limit applied after wrapping; maximum `32` |
| `textOverflow` | `clip`, `ellipsis` | Visible treatment when text exceeds its line or bounds limit |

`MAXIMUM_TEXT_LINES = 32` is deliberately large enough for bounded help,
summary, and status content while preventing a component from requesting an
unbounded line layout. Long reading content remains possible by omitting
`maximumLines` inside a bounded Scroll component; `MAX_TEXT_LENGTH`, view-node
limits, and Host viewport clipping remain authoritative.

Defaults are:

```text
textWrap = none
maximumLines = omitted
textOverflow = clip
```

That combination is one unwrapped visual line clipped to its allocated bounds.
With `word`, line limiting occurs after wrapping. `ellipsis` modifies only the
rendered terminal visible line and never changes the detached source string.
Text flow does not permit rich text, markup, per-span styling, supplied font
metrics, arbitrary line height, or character-level drawing instructions.

## Action References

`actionReference` is a controlled object:

```lua
{
    target = "application",
    actionId = "communications.openMessage",
    parameters = {
        messageId = "message.27"
    }
}
```

or:

```lua
{
    target = "host",
    actionId = "osHome",
    parameters = {}
}
```

Only `target`, `actionId`, and `parameters` are allowed. `parameters` may be
omitted and then means an empty table. It follows the existing controlled plain
parameter limits. A reference contains no callback.

The model-v2 envelope's `actions` field is a contiguous array of unique action
reference descriptors offered by that view. Every interactive node's
`actionReference` must be structurally equal to exactly one descriptor in that
array.

For `target = "application"`:

- `actionId` must also be declared by the resolved presentation in App
  Registry;
- parameters must pass existing application/presentation controlled-parameter
  validation;
- activation returns through Application Presentation Service and
  `performApplicationAction()`; and
- the Host/renderer never calls a provider or domain service directly.

For `target = "host"`, `actionId` must be one of:

| Action | Existing owner and meaning |
|---|---|
| `osHome` | Host requests existing App Lifecycle `closeApp` for the active app and reveals device Home/Desktop |
| `deviceClose` | Host uses its existing device visibility adapter to hide/close that Host surface |

Applications may reference these actions but cannot register new Host actions.
`back` is intentionally absent: logical Back remains owned by Navigation or an
application action returning declarative back navigation. No command bus is
introduced.

Action references are resolved during model validation in this order:

```text
component supports interaction
        -> controlled actionReference shape
        -> approved target
        -> actionId approved for that target
        -> controlled parameters valid
        -> descriptor declared exactly once in envelope actions
        -> view accepted
```

Non-interactive components reject `actionReference`. Interactive components
require it. Disabled controls still require a valid descriptor but do not
activate it.

## Component Contract Matrix

Property names below are exact. Unknown properties are rejected.

| Component | Allowed properties | Required properties | Children | Interactive | Semantic states |
|---|---|---|---|---:|---|
| `layout.stack` | direction, alignment, distribution, spacing, padding, gap, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, surface, border, clipping, overflow | none | required 1-64 | no | none |
| `layout.row` | alignment, distribution, spacing, padding, gap, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, surface, border, clipping, overflow | none | required 1-64 | no | none |
| `layout.split` | direction, alignment, padding, gap, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, surface, border, clipping, overflow | none | exactly 2 | no | none |
| `layout.scroll` | direction, padding, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, surface, border, clipping, overflow | none | exactly 1 | no | none |
| `content.text` | text, accessibleLabel, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, textRole, textAlignment, clipping, overflow, textWrap, maximumLines, textOverflow, semanticState | text | forbidden | no | all presentation states |
| `content.icon` | iconId, accessibleLabel, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, clipping, semanticState | iconId | forbidden | no | all presentation states |
| `content.divider` | widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, border | none | forbidden | no | none |
| `content.emptyState` | text, iconId, accessibleLabel, padding, gap, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, surface, border, textRole, textAlignment, semanticState | content rule below | allowed 0-4 | no | none, attention, success, warning, error, information |
| `control.button` | text, iconId, accessibleLabel, actionReference, padding, gap, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, surface, border, textRole, textAlignment, selected, disabled, semanticState | actionReference + content rule | allowed 0-4 | yes | all presentation states |
| `control.iconButton` | iconId, accessibleLabel, actionReference, padding, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, surface, border, selected, disabled, semanticState | iconId, accessibleLabel, actionReference | forbidden | yes | all presentation states |
| `control.navigationItem` | text, iconId, accessibleLabel, actionReference, count, padding, gap, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, surface, border, textRole, textAlignment, selected, disabled, semanticState | actionReference + content rule | allowed 0-4 | yes | none, unread, attention, warning, error |
| `control.listRow` | accessibleLabel, actionReference, padding, gap, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, surface, border, selected, disabled, semanticState | actionReference | required 1-64 | yes | none, unread, attention, warning, error |
| `indicator.badge` | count, accessibleLabel, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, semanticState | semanticState | forbidden | no | all presentation states |
| `indicator.status` | text, iconId, accessibleLabel, widthMode, heightMode, minimumWidth, maximumWidth, minimumHeight, maximumHeight, grow, textRole, textAlignment, semanticState | semanticState + content rule | forbidden | no | all presentation states |

"All presentation states" means `none`, `unread`, `attention`, `success`,
`warning`, `error`, and `information`. Selected and disabled remain independent
boolean properties, not semantic-state aliases.

The content rule requires at least one visible/accessible content source:

- Empty State: `text`, `iconId`, `accessibleLabel`, or one child;
- Button and Navigation Item: `text`, `iconId`, `accessibleLabel`, or one child;
- Status: `text`, `iconId`, or `accessibleLabel`.

## Validation and Compatibility Boundary

PF.001 definition tests verify the exact identifiers, limits, component
contracts, and source order. PF.002 will implement structural/protocol
validation and rendering against this frozen contract.

Model v1 remains operational and unchanged. This clarification does not change
App API version 1, any persistence schema, presentation resolution, lifecycle,
Navigation, Hosts, Communications, or public addon APIs.
