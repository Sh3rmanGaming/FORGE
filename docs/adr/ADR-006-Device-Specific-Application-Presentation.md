# ADR-006 - Device-Specific Application Presentation

**Status:** Accepted
**Date:** 2026-08-22

## Context

One logical application may need a compact Phone flow and a denser Laptop
workspace over the same authoritative data and route destination.

Phone is also intentionally a right-side companion overlay. It may coexist
with central gameplay or a visible Laptop workspace so instructions or compact
application information need not displace the player's primary task.

## Options Considered

1. Require one identical layout on every device.
2. Create separate logical apps/domain state per device.
3. Use the existing Presentation Resolver to select distinct controlled views.

## Decision

Select option 3. App ID, domain truth, logical destination, and action meaning
remain shared. Exact-device presentation IDs may produce different declarative
composition. Hosts own pixels and transient view state.

Phone and Laptop may be visible simultaneously. Each Host owns an independent
presentation/view session; shared renderer infrastructure shares semantic
algorithms, not device runtime state. Showing or hiding Phone does not
implicitly close, reset, navigate, or invalidate Laptop.

## Consequences

Presentation Resolver remains unchanged. Applications do not duplicate domain
state, and layout parity is not mistaken for behavioral parity.

Applications compose only approved components with approved semantic
properties, tokens, and bounded constraints. Arbitrary style values, pixel
geometry, drawing instructions, and CSS-like extensibility are prohibited.

Phone-over-Laptop input continues through Host-owned occlusion and device input
routing. Exact Phone geometry and final Phone/Laptop visual composition remain
Design Lead work. A future tutorial or gameplay system may present Phone
instructions and observe approved events/domain facts, but Phone does not
directly control Laptop application state. ADR-006 does not define that future
system.

PF.002's shared renderer must therefore remain stateless with respect to device
ownership. Scroll, hover, pressed state, last-safe view, viewport, clipping,
density/profile, hit regions, and generation/invalidation remain isolated per
Host.
