# ForgeOS Shared Host Renderer Architecture

**Status:** Approved  
**Version:** 0.1  
**Milestone:** PF.002 - Declarative View Validation and Shared Host Renderer

## 1. Purpose

Define the architecture that validates PF.001 model-v2 declarative views and
renders them through one shared presentation engine on Phone and Laptop.

This document is an architecture proposal. It does not authorize PF.002
implementation. The clarified and refrozen
[Declarative Presentation Protocol](ForgeOSDeclarativePresentationProtocol.md)
is immutable input to this design.

## 2. Required Outcome

PF.002 should establish this boundary:

```text
Domain / Service
      -> Application
      -> detached declarative view
      -> Application Presentation Service
      -> validation + action mediation
      -> Shared Host Renderer
      -> Host geometry/input
      -> rendered interface
```

Applications own detached composition and action intent. ForgeOS validates and
mediates. The shared renderer understands presentation semantics. Hosts own
device geometry, trusted rendering/input adapters, and shell composition.

The renderer must not understand messages, email, Projects, contracts,
invoices, accounts, companies, vehicles, employees, fields, jobs, or any other
gameplay concept. Application identity is diagnostic/context data only and
must never select a rendering branch.

## 3. Scope

### Included

- internal model-v2 provider delivery through Application Presentation Service;
- complete detached-data, envelope, node, component, property, action, and
  defensive-limit validation;
- shared semantic measurement, arrangement, text layout, clipping, rendering,
  hit-region generation, scroll state, and pointer activation;
- trusted Phone/Laptop presentation profiles;
- exact coexistence with model v1 during migration;
- controlled failures, last-safe-view behavior, diagnostics, tests, and runtime
  verification; and
- the bounded responsibility transfer required to stop future Host-specific
  application rendering.

### Excluded

- Phone or Laptop shell redesign;
- Communications conversion to model v2;
- notification banners/toasts, attention execution, or deep-link execution;
- text entry, selection focus, keyboard/controller application navigation;
- arbitrary application drawing, callbacks, custom widgets, CSS, raw style or
  geometry values;
- persistent UI state;
- public App API changes or third-party icon-registration APIs; and
- any gameplay-domain UI or behavior.

## 4. Authority and Ownership

| Concern | Owner |
|---|---|
| Domain truth | Owning gameplay/domain service |
| View composition and declared application actions | Application provider |
| Active app/presentation/route context | Lifecycle, Presentation Resolver, Navigation |
| Provider invocation, validation, detachment, re-entrancy, app-action mediation | Application Presentation Service |
| Component semantics, layout, token interpretation, text layout, render plan | Shared Host Renderer infrastructure |
| Safe viewport, density profile, draw primitives, pointer ingress, shell actions | PhoneHost/LaptopHost |
| Scroll, pressed, hover, last-safe view | Host-owned runtime view session |
| Persistence | Existing owning services only; PF.002 adds none |

The shared renderer never invokes application providers, Lifecycle, Navigation,
State Store, registries, or domain services. It receives only a validated view,
a trusted Host profile, a trusted rendering adapter, and runtime view state.

Shared renderer infrastructure means shared algorithms and contracts, not a
shared device session. PhoneHost and LaptopHost may be visible simultaneously.
Each independently owns its viewport, profile, validated-view generation,
last-safe view, scroll offsets, hover/pressed state, clips, render plan, and hit
regions. A refresh, failure, show, hide, action, or invalidation on one Host
must not clear, overwrite, advance, or reuse the other Host's runtime state.

Phone-over-Laptop presentation is intentional product behavior. The Phone may
remain a right-side companion overlay while the player uses gameplay or the
Laptop. Showing the Phone does not close, reset, navigate, or rebuild the
Laptop application; hiding it returns input naturally to the preserved Laptop
state. Exact placement and dimensions remain later Design Lead work. PF.002
preserves this capability without defining tutorial, Project, mission, or
cross-device orchestration behavior.

## 5. Model Entry and Provider Invocation

Application Presentation Service remains the sole model acquisition boundary.

```text
Host refresh request
    -> validate device/app/runtime/visibility/active lifecycle
    -> resolve presentation and current Navigation context
    -> obtain private registered provider
    -> enter per-device/app re-entrancy guard
    -> pcall provider.getModel(provider, detachedContext)
    -> always release guard
    -> branch on returned modelVersion
       -> v1: existing accepted validator
       -> v2: PF.002 declarative validator
    -> return detached validated model or nil
```

Provider protocol version 1 and App API version 1 remain unchanged. Internal
model version 2 is a presentation-model format, not a new public provider or
cross-mod API version.

Providers are invoked only during an approved refresh/query cadence or after a
completed user action. No provider callback occurs during measurement, draw,
pointer hit testing, or scrolling.

The existing operation guard remains keyed by device and app. Re-entry from a
provider into model query or action delivery for the same key fails as
controlled unavailability. Guard release must occur after both successful and
failed protected calls.

The device key is mandatory: a Phone query cannot suppress a valid Laptop
query for the same application. This independence does not permit unbounded
recursion or concurrent mutation of provider/domain truth; providers remain
side-effect-free adapters over their owning services.

## 6. Detachment and Validation

Validation builds a new canonical copy while traversing the provider result.
The provider-owned input is never stored or normalized in place.

### 6.1 Envelope validation

Model v2 accepts only the frozen envelope fields. Required values are
`modelVersion`, `appId`, `presentationId`, `routeId`, `title`, `view`, and
`actions`; `attention` is optional.

- `modelVersion` must equal 2.
- app, presentation, and route identity must exactly match the resolved query
  context.
- title and attention use frozen PF.001 bounds and semantics.
- actions must be a contiguous array no larger than `MAX_ACTIONS`.
- unknown fields, sparse arrays, non-string map keys, non-finite numbers,
  metatables, functions, threads, userdata, cycles, and shared mutable aliases
  are rejected.

### 6.2 Tree validation

The validator performs one depth-first traversal with counters checked before
descending or allocating child results.

- node shape is exactly `component`, optional `id`, optional `properties`, and
  component-governed `children`;
- node IDs, when present, are controlled identifiers unique within the view;
- component must exist in `PresentationComponentContract`;
- child policy and exact cardinality come from that contract;
- depth, total nodes, children per node, and text lengths use
  `PresentationLimit`;
- properties must be present in the component's exact allow-list;
- every required property and conditional content source must be satisfied;
- interactive descendants inside another interactive node are rejected; and
- non-interactive nodes cannot carry `actionReference`.

The nested-interaction restriction prevents ambiguous ownership without adding
a protocol field. Composite interactive controls may contain visual/layout
children, but never another Button, Icon Button, Navigation Item, or List Row.

### 6.3 Semantic property validation

Each property is validated by category:

- direction, alignment, distribution, size mode, grow, clipping, overflow,
  wrapping, text overflow, and text alignment use their frozen enums;
- spacing/padding/gap use spacing tokens;
- minimum/maximum sizes use `PresentationSizeToken`;
- surface, border, text role, and semantic state use their correct token/state
  categories rather than any arbitrary token;
- minimum constraints may not resolve conceptually above maximum constraints;
- weighted sizing requires a frozen grow weight on the weighted axis;
- `maximumLines` is a positive integer no greater than 32;
- count is an exact non-negative integer;
- selected/disabled are booleans; and
- icon IDs and accessible labels satisfy their frozen controlled-data rules.

An approved token from the wrong category is invalid. For example, a spacing
token cannot be supplied as a surface.

### 6.4 Actions

Every action descriptor and node reference is validated during model
validation. The reference must structurally match exactly one unique envelope
descriptor.

- application action IDs must exist in the resolved presentation's registered
  action declarations;
- Host action IDs must be exactly `osHome` or `deviceClose`;
- parameters use the existing controlled parameter depth/entry rules;
- disabled interactive controls still require a valid action but cannot
  activate; and
- unresolved actions prevent the whole v2 model reaching the renderer.

The renderer therefore receives action descriptors that are structurally safe,
but action ownership and current availability are rechecked at activation time.

## 7. Trusted Host Presentation Profile

PhoneHost and LaptopHost each supply a trusted immutable profile for one draw
pass. It contains:

- application viewport in Host coordinates;
- density scale and safe bounds;
- concrete size and spacing token metrics;
- typography role metrics and font identity;
- semantic surface/text/accent/border colors;
- border widths, icon sizes, minimum hit sizes, and scroll step;
- a renderer-owned ellipsis glyph/fallback; and
- a private built-in icon catalog/resolver.

Profiles are ForgeOS implementation data, never application data. Applications
cannot see or override concrete metrics, fonts, colors, icon assets, clipping
functions, or draw primitives.

All PF.001 tokens used by a validated view must resolve in the active profile.
A missing internal mapping is an infrastructure/configuration failure, not an
application fallback opportunity. Unknown icon IDs likewise fail controlled
render preparation. PF.002 defines no public icon registration API; initial
catalog entries are trusted built-ins only.

## 8. Layout Model

Layout uses two deterministic passes over the validated tree:

1. **Measure bottom-up:** determine bounded desired sizes from content,
   children, properties, and parent constraints.
2. **Arrange top-down:** assign final rectangles, clip rectangles, scroll
   extents, paint order, and hit geometry.

Intermediate values must remain finite and non-negative. Calculations use Host
logical units; only the trusted Host adapter converts to GIANTS normalized
screen coordinates. Child iteration always follows declarative array order.

### 8.1 Size modes

- `content`: natural content/child size, clamped by min/max and parent bounds;
- `auto`: natural size when bounded, with container behavior determined by its
  children;
- `fill`: available size on that axis after parent padding/gaps;
- `weighted`: share of remaining bounded parent space using grow weight 1-4.

In an unbounded measurement axis, `fill` and `weighted` fall back to bounded
content measurement rather than creating infinite size.

Min/max tokens are resolved before arrangement. `min > max` is rejected during
validation. Natural size is clamped to min/max. If aggregate child minimums
exceed available space, minimums remain authoritative and the parent's
clipping/overflow policy determines visibility; negative sizes or silent model
mutation are forbidden.

Weighted allocation reserves padding, gaps, and non-weighted children first.
It distributes non-negative remainder by grow weight, clamps children that hit
min/max, and redistributes the remaining space iteratively. Stable child order
breaks any numeric tie.

### 8.2 Spacing and alignment

- spacing is outer separation requested by a node in its parent flow;
- padding is the component's inner inset;
- gap is inserted once between adjacent children;
- outer spacing is additive; no CSS-style margin collapse occurs;
- alignment controls cross-axis placement (`start`, `center`, `end`,
  `stretch`); and
- distribution controls main-axis leftover space after sizes/gaps
  (`start`, `center`, `end`, `spaceBetween`).

`spaceBetween` with fewer than two children behaves as `start`. Stretch obeys
the child's min/max and never overrides a fixed maximum.

### 8.3 Stack and Row

Stack follows its declared direction, defaulting to vertical. Row is always
horizontal. Each measures children in order, adds padding/gaps/outer spacing,
allocates weighted remainder, then applies alignment and distribution.

Neither component creates application semantics, selection, or navigation.

### 8.4 Split

Split has exactly two children and defaults to horizontal. It partitions its
bounded primary axis after padding and gap:

- explicit content-sized children reserve their clamped desired size;
- flexible auto/fill/weighted panes divide remaining space;
- absent explicit grow weights use equal weight; and
- supplied grow weights produce the approved bounded ratio.

If both panes request content and overflow, their measured sizes remain and the
Split overflow/clip rules apply. Split does not create windows, resizable
dividers, z-order, or drag behavior.

### 8.5 Scroll

Scroll has exactly one child. The child is measured unbounded only along the
declared scroll axis and bounded along the cross axis. The Scroll component's
arranged rectangle is its viewport.

- `overflow = scroll` enables wheel scrolling and runtime offset;
- hidden overflow keeps offset zero and clips overflowing content;
- visible overflow can paint outside only when clipping is also `none`;
- the effective scroll range is `max(0, contentExtent - viewportExtent)`; and
- every model refresh and viewport change clamps the existing offset.

Long reading content uses a word-wrapped Text node without `maximumLines`
inside a bounded Scroll with scroll overflow. The authoritative text remains
complete and unchanged.

"Unbounded" child measurement is an axis constraint, not unlimited work. The
validator has already enforced the complete PF.001 tree depth, node, child,
text-length, action, and parameter limits before layout begins. Text layout
processes no more than the frozen `MAX_TEXT_LENGTH` source and produces only
finite line records needed to measure content and build the current clipped
render plan. Layout never creates provider nodes, repeats a subtree to fill
space, or relaxes any defensive limit. A finite Host viewport bounds visible
geometry and hit-region generation even when content extent is larger.

Nested scroll containers are allowed only within global depth/node limits. A
wheel event targets the deepest eligible Scroll under the pointer that can move
in the requested direction, then bubbles outward if that Scroll is already at
its boundary.

## 9. Clipping and Overflow

The layout pass produces an effective clip rectangle by intersecting every
ancestor clip with the node's bounds where required.

- `clipping = bounds` clips paint and hit geometry to component bounds;
- hidden and scroll overflow always establish an effective bounds clip;
- visible overflow escapes only when clipping is `none` and ancestor clips
  permit it;
- an empty clip omits paint and hit regions for that subtree; and
- clipping state is pushed/popped by trusted renderer code and cannot leak
  between sibling branches or into Host shell rendering.

Hit regions use the same effective clips as pixels; invisible/clipped portions
cannot activate.

## 10. Text Layout

Text measurement uses the trusted Host rendering adapter and resolved
typography role. Applications cannot provide metrics.

### 10.1 Unwrapped text

`textWrap = none` creates one visual line. If it exceeds its allocated width:

- `clip` draws only the visible safe portion; and
- `ellipsis` finds the longest UTF-8-safe prefix whose measured width plus the
  profile ellipsis fits.

### 10.2 Word wrapping

Word wrapping:

- treats CRLF as one explicit line break and lone CR/LF as explicit breaks;
- preserves source text and horizontal whitespace for measurement/rendering;
- prefers a break before the next word/whitespace run;
- safely breaks an individual overlong run at a UTF-8 code-point boundary; and
- never edits the model string.

`maximumLines` applies after wrapping. When content is omitted by width,
explicit line breaks, maximum lines, or viewport bounds, ellipsis affects only
the terminal visible line when requested. The renderer never writes the clipped
result back to the model or view session.

Text with zero usable width produces no glyph draw and no escaping error.
Measurement and truncation have bounded iteration proportional to the frozen
text length; binary search may be used for fitted prefixes.

## 11. Semantic Token and State Rendering

The renderer resolves semantic meaning through the Host profile, not raw
application style.

- surfaces, borders, text roles, spacing, sizes, and typography map only through
  their category-specific tokens;
- semantic states map to Success, Warning, Error, Information, Unread, or
  Attention roles;
- `none` adds no semantic emphasis;
- unread may select strong typography and unread accent but never derives
  message/domain meaning; and
- count remains independent and exact.

Visual channels have deterministic precedence:

1. disabled controls suppress activation and use disabled surface/text roles;
2. runtime pressed state affects surface/border only;
3. selected state affects selected surface/active border;
4. semantic state affects semantic accent/indicator/emphasis; and
5. base component roles fill remaining channels.

A selected warning remains both selected and warning. Accent.Primary is never
substituted for semantic warning/error/unread meaning.

## 12. Render Plan and Paint Order

Arrangement produces an ephemeral render plan containing resolved primitives,
clip operations, paint ordinals, scroll extents, and hit regions. It contains
no provider callbacks or mutable domain references.

Paint order is deterministic depth-first order:

- a component background/border paints before its children;
- children paint in declared array order;
- later siblings paint above earlier siblings; and
- no application-supplied z-index exists.

The renderer backend is a trusted ForgeOS adapter exposing bounded operations
equivalent to surface, border, text, icon, clip push/pop, and measurement. It is
not an application callback interface.

### 12.1 Frozen component rendering semantics

The shared renderer interprets every component generically:

- Stack, Row, Split, and Scroll arrange children according to section 8;
- Text contributes measured glyph lines and no children;
- Icon contributes one catalog-resolved semantic icon box;
- Divider contributes a non-interactive rule using its resolved border role;
- Empty State arranges icon, text, then declared children in a bounded centered
  vertical flow;
- Button arranges icon, text, then declared children; Navigation Item arranges
  icon, text, declared children, then trailing count; List Row arranges its
  declared children; these control flows are horizontal and create one
  action-bearing region for their own bounds;
- Icon Button renders its icon and uses its required label as non-visible
  accessibility data while creating one action-bearing region;
- Badge renders its exact count when present plus semantic emphasis; and
- Status arranges icon then text with semantic emphasis.

Missing optional content consumes no space. `accessibleLabel` never implicitly
creates visible text. Component padding encloses its internal flow and gap is
inserted only between adjacent present items.

Internal ordering of approved text, icon, count, and child content is selected
only by component identifier. It never depends on app ID, route ID, action ID,
text content, or a gameplay record. Final concrete metrics, palette,
typography, icon artwork, and shell composition remain trusted profile and
Design Lead concerns.

## 13. Hit Regions and Pointer Activation

Interactive arranged nodes create Host-owned hit regions containing:

- clipped rectangle;
- node ID or deterministic structural path;
- view generation;
- paint ordinal;
- detached validated action descriptor; and
- enabled/disabled state.

Overlap selects the highest paint ordinal under the pointer. Nested interactive
nodes are invalid, so no parent/child action competition exists. Disabled
regions do not activate; the Host may still claim their visible UI area to
prevent gameplay input passing through.

Primary pointer flow is:

```text
press
  -> hit-test current plan in reverse paint order
  -> record region identity + generation + action signature
  -> Host claims its UI region

release
  -> hit-test current plan again
  -> require same region, generation, enabled state, and action signature
  -> otherwise cancel
  -> mediate validated action exactly once
```

Leaving the original region, model generation change, route/app change, Host
hide, or secondary-button input cancels activation. Draw and hover never invoke
actions. PF.002 adds no keyboard/controller focus system.

## 14. Action Mediation

### Application actions

The Host forwards the validated descriptor to existing Application
Presentation Service mediation. The service rechecks active device/app,
resolved presentation, declared action, parameters, and re-entrancy before
calling the provider. Declarative navigation outcomes remain applied through
Navigation. Adapter or domain failure leaves the current model/state visible
and causes no inferred mutation.

### Host actions

The Host mediates only the frozen allow-list:

- `osHome`: recheck that the pressed view still belongs to the current active
  app, then request existing lifecycle `closeApp` and reveal Home/Desktop;
- `deviceClose`: use the existing Host/device visibility adapter.

Applications cannot register Host actions. Back is not a Host action; it remains
Navigation/application-owned. No generic command bus is introduced.

## 15. Runtime View Session and Scrolling

Each Host owns one runtime-only view session per active presentation context.
The context key includes device, app, presentation, route, and a deterministic
fingerprint of detached route parameters. State contains:

- last validated safe model for that exact context;
- current render generation;
- scroll offsets keyed by unique node ID or structural path;
- pressed/hover region identity; and
- throttled diagnostic state.

On same-context refresh, safe scroll offsets survive and clamp to new extents.
Route parameters changing within the same route create a different context and
cannot display stale detail content.

Session state clears on app/presentation/route-context change, app close, Host
restart/shutdown, or ForgeOS restart. Host hide/show may preserve it when the
same app and route context remain active. Nothing is persisted to `forge.os`,
Communications, or any gameplay namespace.

Sessions are per Host/device even when both Hosts resolve the same app and
route. Their context keys and generations live in separate Host-owned
containers; equality of app, presentation, route, or parameters never merges
them. Phone overlay visibility therefore cannot invalidate Laptop scroll,
pressed, hover, last-safe, geometry, clipping, profile, hit-region, or
generation state. Input occlusion remains Host orchestration: the uppermost
visible Host receives overlapping pointer input, while non-overlapped Laptop
or gameplay input follows the existing routing rules.

## 16. Invalid Models and Last-Safe View

Only a fully validated/detached model becomes safe.

- provider exception, re-entry, invalid model, unknown component/property,
  invalid token/icon, limit breach, or render-plan failure never replaces the
  safe view;
- a safe view may be reused only for the exact current context key;
- without a safe view, the Host renders a bounded shell-owned unavailable state;
- no invalid subtree is rendered partially;
- no navigation, lifecycle change, action, or domain mutation is inferred; and
- refresh follows existing bounded Host cadence rather than retrying every draw.

Repeated equivalent diagnostics are throttled per context/failure signature.
A successful validated refresh clears that suppression. Lua/provider errors are
contained and no stack trace is allowed to escape through Host draw/input.

## 17. Defensive Limits

PF.002 enforces every frozen PF.001 limit before rendering:

- maximum view depth 12;
- maximum nodes 512;
- maximum children per node 64 plus component-specific cardinality;
- maximum text length 8192;
- maximum text lines 32 when supplied;
- maximum actions 128;
- maximum parameter depth 8;
- maximum parameter entries 128; and
- maximum route parameters 32 where applicable.

The component property allow-list is also the maximum property count for that
component. Traversal stops immediately at the first violation and does not
attempt repair, truncation, partial acceptance, or best-effort rendering.

## 18. Model-v1 Compatibility

Model v1 remains accepted by the current validator and legacy Host presentation
path. PF.002 adds a model-version branch; it does not reinterpret v1 content as
v2 or synthesize declarative nodes from Communications records.

During migration:

- model v2 uses the shared renderer exclusively;
- model v1 continues existing accepted Phone/Laptop behavior;
- current Communications-specific Host drawing remains a bounded legacy path
  until PF.007/PF.008 replace its providers/views;
- the shared renderer contains no Communications branch; and
- public App API version 1 remains unchanged.

Legacy removal requires later accepted migration evidence and is not PF.002.

## 19. Responsibility Transfer

| Current responsibility | PF.002 destination | Remains with Host |
|---|---|---|
| v2 structural/property/action validation | Application Presentation Service + declarative validator | no |
| v2 component measurement/arrangement | shared layout engine | safe viewport/profile input |
| text wrapping/ellipsis | shared text layout | trusted font measurement adapter |
| semantic colors/typography/spacing | shared token resolver | device profile values |
| active-app declarative content draw | shared renderer | invoke within shell app viewport |
| declarative hit-region construction/order | shared renderer plan | pointer ingress and region ownership |
| declarative scroll extents/clamp | shared session/layout | wheel input and runtime session ownership |
| application action execution | Application Presentation Service | forward validated intent |
| OS Home/device close | no generic renderer execution | Host/lifecycle/visibility adapters |
| launcher, header, frame, footer, wallpaper | no transfer | Host shell |
| notification presentation | deferred PF.005/PF.006 | current Host baseline |
| model-v1 Communications drawing | no PF.002 transfer | temporary legacy path until PF.007/PF.008 |

PF.002 therefore establishes the scalable v2 path without pretending the later
shell and Communications migrations have already occurred.

## 20. Device Adaptation

Phone and Laptop share validation, component semantics, layout algorithms,
text rules, paint order, action behavior, and state lifecycle. They may provide
different:

- viewport dimensions/aspect ratios;
- density and size/spacing metrics;
- typography metrics;
- minimum hit sizes and scroll steps;
- icon sizes and concrete semantic palette; and
- composition supplied by the application provider.

The same logical application/data/action destination does not require the same
view tree. Device-specific providers may compose Phone navigation flow and
Laptop split-pane flow using the same frozen vocabulary.

Phone's normal product posture is a right-side companion overlay that may
coexist with central gameplay and with a visible Laptop workspace. Laptop
remains an independently stateful workspace beneath it. PF.002 fixes neither
the Phone's exact width/position nor either device's final visual composition;
it requires only that the Host profile and adapter can supply those later
approved geometries without changing renderer semantics.

Split remains a bounded two-child primitive. Applications can nest Split with
other frozen layout primitives to form multiple regions. The renderer knows
only child order, direction, bounds, and weights; it does not know whether a
region represents navigation, reading, Projects, Banking, Companies, Fleet,
Progression, or any other domain concept.

## 21. Diagnostics and Controlled Failure

PF.002 uses existing `LogSource.PRESENTATION_PROTOCOL` for validation/layout/
render diagnostics and existing Host sources for shell/input delivery failures.
No new public result enumeration is required.

Diagnostics identify stage, device, app, presentation, route, node ID/path when
safe, and controlled reason category. They must not dump mutable provider/domain
objects, full potentially sensitive message bodies, or executable stack state.

Existing `getApplicationPresentationModel()` remains model-or-nil; no public API
signature changes. Internal validator tests may return existing ForgeOS result
categories plus private diagnostic detail, but that detail is not exposed as a
new addon contract.

## 22. Verification Strategy

### Automated tests

- exact v1/v2 branching and v1 regressions;
- envelope/node/property/component validation;
- cycles, aliases, sparse arrays, metatables, unsupported types, unknown fields;
- every defensive limit and off-by-one boundary;
- component child/content/interaction contracts;
- token-category validation and missing profile/icon mapping;
- min/max, fill/content/auto/weighted allocation and overflow;
- Stack, Row, Split, Scroll measurement/arrangement;
- alignment, distribution, spacing, padding, gap;
- clipping intersection and empty clips;
- UTF-8-safe measurement, word wrap, explicit breaks, maximum lines, clip,
  ellipsis, zero width, and long bounded content;
- semantic state/selected/disabled/pressed precedence;
- paint and reverse-hit order;
- press/release same-control, release outside, generation cancellation,
  secondary ignored, disabled suppression, exactly-once activation;
- application and Host action mediation;
- scroll clamp, nesting/bubbling, reset/preserve lifecycle;
- provider exception/re-entry and no callback during draw;
- last-safe exact-context reuse and stale-route-parameter rejection; and
- proof the renderer has no application/domain identifier branches.

### Integration tests

A neutral development-only synthetic provider supplies model v2 on Phone and
Laptop. It proves different trusted geometry/density profiles, rendering,
scrolling, hit regions, application action delivery, `osHome`, `deviceClose`,
failure containment, and v1 coexistence. It contains no gameplay fixture and
creates no public API.

### FS25 runtime verification

- reviewed development package and deployed hash identity;
- complete retained M1-M3/PF.001 suite;
- neutral v2 view visibly rendered on Phone and Laptop;
- primary pointer press/release and action evidence;
- bounded long-text Scroll and clipping evidence;
- same model remains detached after render/scroll;
- controlled invalid-provider/model evidence without escaped stack failure;
- v1 Communications remains operational;
- normal save and complete FS25 shutdown;
- operational bootstrap removal, package validation, and new operational hash.

No persistence cycle is required because PF.002 state is explicitly runtime-
only, but restart must prove scroll/pressed/last-safe state does not persist.

## 23. Acceptance Criteria

PF.002 may be proposed for acceptance only when:

1. valid neutral model-v2 views render through the same shared renderer on
   Phone and Laptop;
2. exact PF.001 validation rejects every malformed/oversized case safely;
3. layout, text, clipping, scrolling, token resolution, state rendering, paint
   order, and hit regions are deterministic and tested;
4. actions activate once through their owning mediation path;
5. last-safe behavior never crosses app/presentation/route-parameter context;
6. v1 remains operational and retained regressions pass;
7. no renderer branch names Communications or any application/gameplay domain;
8. no PF.001 vocabulary, persistence, or public API changed;
9. FS25 runtime/load-order/shutdown evidence passes; and
10. the operational package is restored and separately fingerprinted.

## 24. STOP Conditions

Stop before PF.002 implementation if it would require:

- a new component, property, token, action type, layout primitive, protocol
  field, or changed PF.001 semantic;
- application-specific renderer logic;
- arbitrary application drawing/style/geometry/callback execution;
- public API or persistence changes;
- Host access to domain services or model mutation;
- a generic command bus, widget plugin system, focus architecture, or window
  system;
- Communications conversion or shell redesign inside PF.002; or
- weakening model-v1 compatibility or retained regression coverage.

## 25. PF.002 Requirement Traceability

| Required design subject | Authoritative section |
|---|---|
| 1. Provider invocation | 5 |
| 2. Detached-model acquisition | 5, 6 |
| 3. Structural/component validation | 6.1, 6.2 |
| 4. Semantic-property validation | 6.3, 6.4 |
| 5. Measurement/arrangement | 8 |
| 6. Stack/Row/Split/Scroll | 8.3-8.5 |
| 7. Grow/min/max/bounded sizing | 8.1 |
| 8. Spacing/padding/alignment | 8.2 |
| 9. Clipping/overflow | 9 |
| 10. Text/wrap/maximum-lines/ellipsis | 10 |
| 11. Bounded long-content Scroll | 8.5 |
| 12. Semantic token resolution | 7, 11 |
| 13. Semantic-state rendering | 11 |
| 14. Host-owned hit regions | 13 |
| 15. Overlap/z-order | 12, 13 |
| 16. Primary-pointer validation | 13 |
| 17. Application action mediation | 14 |
| 18. Frozen Host-action mediation | 14 |
| 19. Runtime-only view/scroll state | 15 |
| 20. Provider re-entrancy | 5 |
| 21. Invalid models | 16 |
| 22. Last-safe view | 15, 16 |
| 23. Defensive limits | 17 |
| 24. Model-v1 migration | 18 |
| 25. Host responsibility transfer | 19 |
| 26. Phone/Laptop adaptation | 4, 20 |
| 27. Diagnostics/controlled failures | 16, 21 |
| 28. Automated tests | 22 |
| 29. FS25 runtime verification | 22 |
| 30. Acceptance criteria | 23 |

This proposal changes no PF.001 component, property, token, state, action,
field, limit, or semantic meaning.

## PF.002 — APPROVED; IMPLEMENTATION VERIFIED, ACCEPTANCE REQUIRED

This architecture and its companion component design are approved. PF.002 is
implemented and verified, but Project Director and Chief Architect acceptance
is still required. PF.003-PF.009 remain unauthorized.
