# FORGE OS Design System

**Status:** Approved
**Version:** 0.1
**Owner:** UI/UX Design Lead with Project Director and Chief Architect approval

## Purpose

Define a semantic visual and interaction language that makes FORGE applications
recognisably part of one operations system without forcing identical layouts.

This specification freezes roles and usage principles, not the current POC
palette, final typography assets, or final art direction.

## Design Character

FORGE OS is modern professional agricultural, logistics, and industrial
operations software. It should feel premium, capable, restrained, and readable.

Principles:

- clarity before decoration;
- strong information hierarchy;
- restrained industrial character;
- premium rather than flashy;
- consistency without template sameness;
- complexity only when the task requires it;
- readable at expected FS25 sizes and backgrounds;
- input-method awareness;
- accessible contrast and non-color cues;
- meaningful, brief motion; and
- negative space as an information tool.

Avoid generic SaaS dashboards, oversized tablet controls on Laptop, excessive
rounded cards, sci-fi ornament, decorative noise, and one dashboard template
reused for every application.

## Semantic Token Principle

Application UI references semantic tokens. It does not hardcode brand colors,
surface RGB values, independent padding, or unrelated font sizes.

Token roles remain stable while approved theme values may evolve centrally.

### Surfaces

```text
Surface.Background   Host wallpaper/base environment
Surface.Primary      Main application workspace
Surface.Secondary    Navigation/list/supporting region
Surface.Elevated     Toast, banner, dialog, floating control
Surface.Selected     Selected row/tab/navigation surface
Surface.Disabled     Unavailable/disabled surface
```

### Text

```text
Text.Primary
Text.Secondary
Text.Muted
Text.Disabled
Text.Inverse
```

Text roles must meet approved contrast targets against their intended surfaces.
Muted text cannot be the only carrier of required information.

### Brand and Accent

```text
Accent.Primary
Accent.Secondary
```

The POC orange/amber is provisional. Accent values require later visual
approval. Brand accent does not automatically mean selected, unread, warning,
new, important, or actionable.

### Semantic State

```text
Semantic.Success
Semantic.Warning
Semantic.Error
Semantic.Information
Semantic.Unread
Semantic.Attention
```

Every semantic state uses at least one non-color cue such as icon, label,
weight, border, or shape.

Application attention uses these fixed meanings:

- `none`: no application-level attention;
- `unread`: new or unread content exists;
- `attention`: action or awareness is requested without inherent warning or
  error;
- `warning`: a degraded, approaching-risk, or caution condition; and
- `error`: a failed or blocked condition requiring awareness.

Attention count is independent of severity. A warning without a count and an
unread state with an exact count are both valid. Hosts do not infer a stronger
state from count, accent color, or notification volume.

### Borders

```text
Border.Subtle
Border.Standard
Border.Active
Border.Focus
```

Borders are thin and deliberate. Focus and active states remain distinguishable
from decorative dividers.

### Spacing

```text
Spacing.XS
Spacing.SM
Spacing.MD
Spacing.LG
Spacing.XL
Spacing.XXL
```

The Design Lead will approve device-relative concrete values during PF.001.
Applications choose from the scale and may not invent near-duplicate spacing
without a documented component need.

### Typography

```text
Display
Heading1
Heading2
Heading3
Body
BodyStrong
Label
Caption
Numeric
```

- Display is rare and shell/empty-state oriented.
- Headings establish nested information structure.
- Body is the default readable content role.
- BodyStrong marks emphasis or unread state without changing meaning.
- Label names controls and compact metadata.
- Caption is supporting, never essential-only, information.
- Numeric uses stable alignment for financial/status values.

Concrete font family, size, weight, tracking, and line-height values remain a
Design Lead deliverable and require runtime readability approval.

## Icon System

- One coherent family with deliberate stroke/fill rules.
- Icons remain legible at Phone and Laptop minimum sizes.
- App icons have stable identity, simplified silhouettes, and active/inactive
  treatments.
- Semantic icons never rely on color alone.
- Badges attach at a defined corner/safe offset without obscuring identity.
- Icons include accessible labels wherever meaning is not already textual.
- Placeholder text glyphs are not final icon assets.

## Interaction States

Every interactive component specifies applicable states:

```text
default
hover/focus
selected
pressed
disabled
unread/new
warning
error
```

Hover and focus share hierarchy but are not assumed to be the same input state.
Pressed is transient. Selected represents persistent view choice, not pointer
press. Disabled controls do not activate and explain unavailable actions where
the information architecture requires it.

## Motion

- Motion communicates appearance, dismissal, hierarchy, or state change.
- Phone banners enter from the top edge; Laptop toasts enter from the lower
  right notification region.
- Motion duration and easing use semantic motion tokens approved in PF.001.
- Animation must not delay authoritative actions.
- Reduced-motion behavior must remain possible.
- Decorative looping animation is prohibited in the initial foundation.

## Shared Component Guidance

### Buttons and Icon Buttons

Use for explicit actions. Primary emphasis is limited to the most important
available action. Destructive actions require distinct semantics and, where
consequential, confirmation.

### List Rows and Navigation Items

Support default, hover/focus, selected, unread, disabled, warning, and error
states. Rows expose the whole intended hit region and activate only on accepted
release semantics.

### Badges and Status Indicators

Badges represent application-provided attention models. They do not derive
truth from Host notification counting. Status indicators use semantic state and
accessible text.

#### PF.005 attention badge decisions

Decided by the project owner for PF.005:

| State | Shape cue |
|-------|-----------|
| `none` | no badge |
| `unread` | round badge showing the exact count |
| `attention` | `!` in a circle |
| `warning` | triangle |
| `error` | square containing an X |

- A count above 99 displays as `99+`. The displayed text is a visual
  compression only; the authoritative value is never altered.
- `warning`, `error`, and `attention` may display without a count. When one
  carries a count, a small count badge in the same colour sits immediately left
  of the state shape; the count never replaces the shape.
- Badge shapes are generated image assets with anti-aliased rounded corners
  (white shape, any glyph baked in dark), tinted at draw time by the semantic
  token for the state. The count text is rendered by the Host. If an overlay
  cannot be created, the Host falls back to flat rectangles so a badge is still
  shown. New image assets are permitted for PF.005; final artwork refinement
  remains open.
- The accessible label is carried in the model but not drawn.
- No badge animation is used; any later motion needs its own reduced-motion-
  compatible decision.
- Phone badges start slightly larger than Laptop badges. Final dimensions and
  token values are set from in-game screenshots at PF.005 runtime verification.

### Tabs

Use only for peer views within one logical route/area. Tabs do not replace
global Navigation Service routes where history/deep linking is required.

### Separators and Cards

Separators clarify structure. Cards are used only for meaningful grouped
objects, not as a default wrapper around all content.

### Scrollbars

Scrollbars communicate position where geometry permits. Scroll state is Host
runtime state unless an approved application preference contract says otherwise.

### Empty, Loading, Unavailable, and Error States

Each is distinct:

- Empty: valid result contains no records.
- Loading: bounded asynchronous work is underway.
- Unavailable: required service/model cannot currently be acquired.
- Error: controlled operation failed and recovery guidance may be offered.

No fake records are used as placeholders.

### Notification Banner and Toast

Show source/application identity where valid, title, bounded body summary,
semantic severity, and action affordance only when a valid destination exists.
Expiry does not imply read or dismissal.

### Deferred Components

Text inputs, selectors, dialogs, confirmation prompts, tooltips, attachment
cards, complex tables, forms, drag/drop, and controller-focused variants are
specified later when a real approved application requires them. Their absence
must not be filled with one-off incompatible controls.

Deferred does not mean unconstrained:

- text inputs and selectors will require persistent labels, visible
  focus/validation/error states, and an approved text-entry/focus architecture;
- dialogs and confirmation prompts will require explicit modal ownership,
  cancel/escape behavior, and use only for consequential decisions;
- tooltips may supplement but never contain information required to understand
  or operate a control;
- attachment and domain-object cards must expose stable object identity and
  declared actions without fabricating unsupported domain behavior; and
- complex tables, forms, and drag/drop must preserve keyboard/controller and
  accessibility paths before implementation.

No deferred component enters the shared renderer through an application-local
special case. It requires its own bounded contract and Design Lead review.

## Accessibility Baseline

- readable contrast at runtime over actual FS25 scenes;
- text scaling/layout tolerance within bounded Host geometry;
- semantic state never color-only;
- safe clipping that preserves action identity;
- accessible labels for icons and attention counts;
- meaningful pointer hit areas;
- reduced-motion-compatible design; and
- no critical information conveyed only by transient notification presentation.

## Device Adaptation

Phone and Laptop share tokens and component meaning, not necessarily dimensions
or composition. Phone favors progressive disclosure and compact navigation.
Laptop favors denser multi-region task work within one active application.

## Governance

## PF.003 Laptop Visual Interpretation

The approved PF.003 concept is authoritative for Laptop visual direction, not
for application/domain functionality or exact pixels. Laptop should read as a
modern, professional, purpose-built agricultural/logistics operations computer:

- compact desktop shortcuts concentrated in a deliberate region;
- substantial wallpaper and negative space;
- restrained identity, status, and control chrome;
- dark low-glare surfaces, fine borders, modest radii, and limited elevation;
- dense active-application workspace rather than oversized dashboard cards;
- selective amber/orange emphasis through semantic brand/accent/action roles;
  and
- strong hierarchy without oversized headings or universal containers.

Wallpaper is a fixed shell-owned asset for PF.003 with
`Surface.Background` fallback. Approved semantic scrims or surface treatments
may protect contrast over bright, dark, or detailed imagery. Readability takes
priority over unmodified wallpaper appearance. Wallpaper selection,
customization, and persistence are outside PF.003.

The concept's geometric FORGE mark is identity-character and placement guidance
only. It is not a production asset and must not be traced, procedurally recreated,
or approximated in Lua. The same asset boundary applies to final application and
generic-fallback icons. A fallback icon conveys only generic application
identity, remains paired with the textual app name, and is not the disabled cue.

`Accent.Primary` remains distinct from unread, selected, attention, warning,
and error. Every interaction or semantic state retains a non-colour cue.
Exact palette, typography assets, artwork, wallpaper treatment, shortcut sizes,
and geometry breakpoints remain subject to runtime visual trials and Design Lead
approval.

PF.003 avoids sci-fi HUD, cyberpunk, glossy gaming UI, retro technology,
generic SaaS dashboard composition, mobile UI enlarged onto a monitor, and
excessive card decoration.

- Design Lead proposes token values, component specifications, assets, and UX
  acceptance criteria.
- Chief Architect approves architectural behavior and Host/application
  ownership.
- Project Director approves product direction and final art choices.
- Implementation must consume semantic tokens rather than copying provisional
  POC values.
- Token changes require visual regression review but should not require domain
  or application logic rewrites.

## PF.004 Phone Visual Interpretation

Phone uses the approved concept's modern, professional, restrained industrial
identity at actual right-side companion scale. It shares semantic tokens,
typography roles, icon family, fine borders, modest radii, restrained accent,
interaction semantics, and FORGE identity with Laptop while using a distinct
compact composition.

Home favours icon-led shortcuts, restrained labels, deliberate gaps, useful
negative space, minimal shell chrome, and a small readable status region. Visual
compactness does not reduce semantic hit areas or minimum readable type. Generic
fallback artwork carries no domain meaning and remains distinct from disabled.

Avoid oversized cards, dashboards, permanent information panels, debug text,
hardcoded RGB, or a Laptop layout scaled down. Final mark, icons/fallback,
palette values, typography, numerical geometry, launcher spacing, PF.005
attention, PF.006 banner/motion/sound, and final polish remain Design Lead gates.
