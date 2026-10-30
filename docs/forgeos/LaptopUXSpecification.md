# FORGE OS Laptop UX Specification

**Status:** Approved
**Version:** 0.2
**Owner:** UI/UX Design Lead and ForgeOS Presentation Architecture

## Product Model

The Laptop is intentionally a single-active-application desktop environment,
not a multi-window desktop simulation.

```text
Laptop
├── Desktop
│   ├── FORGE OS identity
│   ├── application shortcuts and badges
│   ├── minimal system/device status
│   └── future PF.006 toast-safe region
└── Active Application
    ├── app-specific workspace
    ├── app-specific logical navigation
    └── Host-owned return-to-desktop control
```

## Desktop

- Use the full safe Laptop surface with substantial negative space.
- Present stable app icons/shortcuts rather than large generic dashboard cards.
- Reserve a consistent badge anchor for existing compatible badge presentation
  and future PF.005 attention without creating attention truth in PF.003.
- Keep FORGE OS identity, device/system status, and control hints restrained.
- Wallpaper/background supports atmosphere but cannot compromise readability.
- Desktop is Host-owned and is not an application route.

## Application Workspace

- The active app replaces the Desktop workspace while retaining bounded global
  Laptop chrome.
- Exactly one app is active per existing App Lifecycle Service semantics.
- App composition may use dense multi-region layouts appropriate to Laptop.
- No overlapping windows, resize/move, taskbar, z-order, or multiple rendered
  apps are introduced.
- The application viewport respects shell safe areas and toast occlusion rules.

## Navigation Semantics

- **Back** changes logical application history through ForgeOS/app actions.
- **Home/Desktop** closes the active app through App Lifecycle Service and
  reveals Desktop.
- **Close Laptop** hides/closes the device Host through the existing adapter and
  is distinct from application Back or Desktop.
- A separate minimise state is not introduced.

## Application Icons and Badges

- Icons use the approved app identity and common icon family.
- Badge placement is consistent and must not obscure icon recognition.
- Exact counts remain exact semantic values; visual fitting may adapt type size.
- Badge truth is queried from the app/domain attention provider, never counted
  from notifications by LaptopHost.
- PF.005: the badge shows the state shape and exact count defined in the
  Design System (`99+` above 99). It is anchored at the icon's top-right corner,
  is smaller than the Phone badge, and does not obscure icon recognition. The
  Laptop reads attention only through the private Host context function
  `getApplicationAttention`. Final dimensions are set at PF.005 runtime
  verification.

## Future PF.006 Toast-Safe Region

- PF.003 reserves intentional lower-right Laptop geometry only.
- The region avoids the primary shortcut cluster and essential shell controls.
- In an active workspace it may intersect only a bounded non-critical edge of
  the application viewport.
- Visible Phone geometry and input ownership take priority where they overlap.
- PF.003 does not create, queue, time, animate, dismiss, activate, or otherwise
  present a toast and does not mutate notification read state or deep-link.
- The legacy permanent Desktop notification feed is superseded and does not
  constrain the new composition.

## Pointer and Control Hints

- Existing F6 pointer-mode ownership remains with Engine.
- Controls activate on primary release within the pressed logical control.
- Secondary application semantics remain deferred.
- Hints are contextual and do not dominate the Desktop.
- Controller/keyboard app focus remains deferred; design must leave visible
  focus treatment possible.

## Responsive Geometry

- Layout uses normalized safe-area constraints and semantic spacing.
- Desktop icon grids and app workspaces use deterministic breakpoints approved
  through runtime testing, not message/item count.
- Ultra-wide, 16:9, and narrower supported aspect ratios retain readable line
  lengths and do not stretch content across the entire display unnecessarily.
- App-specific minimum region widths determine collapse/reflow behavior.
- The Phone may remain visible over the Laptop and must render above it.

Exact geometry is selected by the trusted Laptop Host profile after FS25 visual
trials. The approved concept establishes proportion and hierarchy, not pixel
coordinates. If a supported viewport cannot meet the minimum readable profile,
the shell uses a controlled unavailable result rather than unsafe clipping.

## PF.003 Visual Direction

The approved PF.003 concept directs a modern, professional, restrained
operations-computer character: compact shortcuts, substantial wallpaper and
negative space, dark low-glare layering, fine borders, modest radii, restrained
chrome, dense application workspace, and selective amber/orange emphasis.
Desktop shortcuts remain clustered in a deliberate region as the registry grows
rather than expanding into a full-screen mobile grid.

Wallpaper is a fixed shell-owned milestone asset with a semantic background
fallback and an approved semantic readability scrim where required. PF.003 adds
no wallpaper selection, preferences, customization, or persistence.

The concept mark supplies geometric identity and placement direction only. It
is not a production asset and must not be traced or recreated in Lua. Final
mark, icons, typography, palette, wallpaper, and numerical breakpoints remain
Design Lead/Project Director/Chief Architect decisions as applicable.

All depicted application catalogs, records, notifications, balances, updates,
tutorials, and Communications functionality are illustrative. Broad future
terminology remains Projects rather than Contracts; legitimate narrow uses of
contract are unchanged.

## Shortcut Population and Overflow

Desktop shortcuts project eligible Laptop applications from App Registry using
existing `displayName` and optional `iconId` metadata. No Host-owned catalog or
application identifier branch is permitted. One app remains compact at the
cluster origin; a few apps fill stable cells; larger populations use a bounded,
deterministic overflow page/scroll treatment inside the shortcut region.
Visible work is bounded by the current shell page and controls. PF.003 does not
invent a public maximum application count.

An unresolved icon uses the common generic-application fallback plus the app's
text label. The fallback infers no domain meaning, fabricates no artwork, and is
visually distinct from disabled/unavailable state.

## Transient State

Desktop hover/pressed state, shortcut page/offset, app scroll offsets, and
geometry are runtime-only. Future toast queues/animations remain PF.006.
Existing logical route resume remains owned by Navigation Service. Hide/show
during one active route may retain safe transient state; Host restart clears it.

## POC Behavior Superseded by Proposed UX

- permanent right-side notification text feed;
- large generic application card panel;
- hardcoded orange as immutable brand color;
- direct Communications drawing embedded as the long-term Host extension model;
  and
- sparse active-app surface that behaves as a scaled Phone list.

The accepted lifecycle, full-screen single-app surface, Home control,
Laptop-before-Phone draw order, and pointer occlusion are retained.

## Verification

- Desktop/app transition and one-active-app behavior;
- Home versus Back versus device Close;
- app icons, generic fallback, and the reserved attention anchor;
- future-toast safe-region geometry and absence of PF.006 behavior;
- application viewport and safe margins at approved resolutions;
- Phone overlay draw/input precedence;
- pointer press/release/cancel semantics;
- runtime-only state reset; and
- no window-management or gameplay authority.
