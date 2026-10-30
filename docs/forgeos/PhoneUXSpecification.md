# FORGE OS Phone UX Specification

**Status:** PF.004 Implemented, Verified, Visually Accepted and Frozen  
**Version:** 0.2  
**Owner:** UI/UX Design Lead and ForgeOS Presentation Architecture  
**Implementation:** Not Authorized

## Product model

Phone is a persistent right-side companion operations device for quick access,
short interactions, contextual information, messages, lightweight actions, and
future guidance while the player continues gameplay or Laptop work. It is not a
miniature Laptop.

Phone Home is a compact registry-derived launcher with an empty top-edge PF.006
seam. An active application replaces the Home interior with its trusted compact
viewport. Phone and Laptop may be visible simultaneously but remain independent
Hosts and sessions. Future guidance may instruct work performed elsewhere;
Phone does not control Laptop state or own tutorial, Project, mission, or
progression truth.

## Home

- Present compact icon-led shortcuts with restrained labels and deliberate gaps.
- Preserve useful negative space rather than filling the screen with a dashboard.
- Populate only eligible App Registry entries through accepted resolution.
- Use deterministic bounded pages as population exceeds the current profile.
- Never shrink icons, labels, gaps, or hit targets below approved minima.
- Use a generic icon fallback plus textual identity when optional art is absent.
- Show a controlled empty/unavailable state without fabricating applications.
- Do not show debug surface/presentation IDs or a permanent notification list.

One app remains compact at the deliberate first anchor. A few apps grow the
cluster in reading order. Normal and larger populations use trusted-profile
capacity and deterministic paging; an incomplete page keeps its negative space.

## Active application

The launcher interior is replaced by the trusted application viewport. Compact
views favour progressive disclosure—list to detail—rather than Laptop multi-pane
composition. Shell identity/status, OS Home, Close, safe margins, and the future
banner seam remain distinct and cannot be drawn by applications.

Generic model-v2 applications use PF.002. The existing Communications model-v1
Phone renderer is a temporary PF.008-bound compatibility exception and receives
only the application viewport. Its present UX is not future visual authority.

## Back, application Home, OS Home, and Close

- Application Back follows accepted Navigation/application action semantics.
- Application Home/Inbox returns to an application route and keeps it active.
- OS Home closes the active app through App Lifecycle and reveals Phone Home.
- Device Close uses the existing Phone visibility adapter and is not navigation.

No second Phone navigation stack, minimise, task switcher, or multiple-active-
application model is introduced.

## PF.005 attention seam

Shortcuts reserve a semantic attention anchor. PF.004 does not determine truth,
unread derivation, count, severity, label, persistence, colour, or refresh.
Communications-specific badge logic is not the future generic model. PF.005 owns
attention behaviour and visual acceptance.

PF.005 presentation: the Phone shows the state shape and exact count defined in
the Design System (`99+` above 99) in the reserved anchor at the shortcut's
top-right corner. The badge starts slightly larger than the Laptop badge, must
not obscure icon recognition, and stays inside the protected shell geometry.
The Phone reads attention only through the private Host context function
`getApplicationAttention`. Final dimensions are set at PF.005 runtime
verification.

## PF.006 notification seam

Reserve an empty, clipped top-edge layer that can later overlay Home or active
application content without occupying either viewport. PF.004 does not specify
queues, capacity, timing, motion, sound, expiry, activation, deep links,
read/dismiss mutation, severity, or content. Generic Phone surface input never
mutates notification truth. PF.006 owns all such behaviour.

## Scrolling, pointer, and compact information

Validated application content uses PF.002 bounded Host-owned scrolling and text
semantics inside the app viewport. Shell launcher paging is separate runtime
state. Primary press claims a current visible control; activation occurs only on
release within the same logical region. Release outside cancels. Phone claims
overlapping input before Laptop while visible. Controller/keyboard navigation
and text entry are not PF.004.

## Safe geometry and runtime evaluation

Trusted profiles derive frame/screen safe bounds, status, empty banner seam,
launcher or app viewport, navigation/Close, pointer hints, clipping, and hit
targets from actual viewport metrics and UI scale. Concept pixels do not define
coordinates. Evaluation uses actual right-side dimensions over bright, dark,
busy, and machinery scenes, over gameplay and Laptop, at representative scales.

## Visual direction

Use the approved concept for modern, professional, restrained industrial
character: compact icons, clear identity, modest chrome, strong hierarchy,
readable type, restrained accent, and meaningful negative space. Phone shares
semantic tokens, typography roles, icon family, borders, interaction semantics,
and FORGE identity with Laptop—not Laptop composition.

Avoid oversized cards, generic panels, dashboards, permanent feeds, debug text,
unnecessary headings, hardcoded RGB, and desktop layouts scaled smaller. Final
mark, icons/fallback, token values, typography, geometry, spacing, PF.005 badge,
PF.006 banner/sound/motion, and final polish remain Design Lead decisions.

## Transient state

Launcher page, projected layout, hover/focus/press, hit regions, trusted profile,
viewport, clipping, resolved assets, and application render-session state are
runtime-only. No Phone UI tree, shell layout, or notification-presentation state
is persisted.

## POC behaviour superseded by PF.004

- hardcoded Communications activation and Communications-only launcher hit area;
- four-application cap;
- permanent notification feed and generic-surface read/dismiss mutation;
- ACTIVE SURFACE and presentation-identity debug content;
- oversized application cards, hardcoded RGB, and undocumented fixed geometry;
- Communications-specific badge projection as the future model.

The Communications v1 active-app renderer is retained only as the isolated
PF.008 transition. Existing lifecycle, shared domain truth, independent route
and PF.002 session state, pointer semantics, and Phone-over-Laptop ordering remain.

## Verification

Verify registry projection; bounded population growth; icon/unavailable fallback;
Home/app/Home and navigation distinctions; trusted clipping; model-v2 neutrality;
v1 containment; primary release/cancel; Phone occlusion; independent sessions;
absence of permanent notification feed/mutation; PF.005/PF.006 seams only;
actual-size readability; representative scenes/scales; unchanged public API,
persistence, domain, Notification, lifecycle, and Navigation ownership.

The complete design and traceability are in
[FORGE OS Phone Shell Architecture](ForgeOSPhoneShellArchitecture.md).
