# PF.002 Runtime Verification

**Status:** Implemented and Verified — Acceptance Required
**Milestone:** PF.002 - Declarative View Validation and Shared Host Renderer
**Date:** 2026-08-22

## Verified Scope

PF.002 implements the frozen model-v2 validation, detachment, shared layout and
render-plan pipeline, Host adapters, Host-owned hit regions, primary-pointer
activation, action mediation, bounded Scroll/text behavior, last-safe handling,
and independent Phone/Laptop runtime sessions. Model v1 remains operational.

No PF.001 vocabulary, public API version, persistence schema, application
conversion, shell redesign, final visual identity, or PF.003-PF.009 behavior is
included.

## Static and Package Evidence

- synchronization manifest: 127 files, all identical, no drift or collisions;
- test-order preflight: passed;
- runtime-package tooling regressions: 5 passed;
- development bootstrap: exactly one in verification package and Logger-first;
- verification package:
  `FS25_FORGE_Engine_PF.002-verification.zip`;
- verification/deployed SHA-256:
  `4184A4FC9A22EBF8999AF7E55832E5DE41C86D149B030D17F5F33CC3E240BE5F`;
- operational package:
  `FS25_FORGE_Engine_PF.002-operational.zip`;
- operational/deployed SHA-256:
  `8472BF9B8A3ED573DA57BA7BB99E71B98E69AE7147D31961A98D37C1A654D10F`;
- both archives passed declared-source, order, uniqueness, POSIX-path, and
  bootstrap-count validation.

## FS25 Accepted Cycle

- savegame: 3;
- log: `PF.002-cycle5-accepted-log.txt`;
- log SHA-256:
  `D04899503358CBBF09B4CA55C910DFDF54428E5B513AD0E8C79590E4C83EDF73`;
- PF.002 Presentation Renderer tests: passed;
- neutral Phone/Laptop presentation integration: passed;
- complete retained development suite: passed;
- unintended `Script error` / `LUA call stack`: none;
- FORGE persistence save: passed (`saveCount=65`);
- FS25 savegame save: passed;
- PhoneHost and LaptopHost normal shutdown: passed;
- Engine shutdown: passed with zero event groups and expected cleared
  registrations.

The neutral integration explicitly mutates Phone scroll/hover state and proves
Laptop is unchanged, then mutates Laptop scroll/pressed state and proves Phone
is unchanged. Application action activation remains on the originating Host.

## Rejected Verification Cycles

- Cycle 1 (`PF.002-cycle1-log.txt`) rejected because the PF.002 unit assertion
  incorrectly treated the Laptop's own zero Scroll entry as Phone mutation and
  retained Host tests exposed a missing shell Home region on the generic path.
- Cycle 2 (`PF.002-cycle2-log.txt`) rejected despite a passing suite because the
  neutral harness called the real GIANTS overlay backend outside draw.
- Cycle 3 (`PF.002-cycle3-log.txt`) rejected because an overlay test double used
  an invalid table handle and produced GIANTS argument call stacks.

All rejected evidence remains separate from the accepted cycle.

The accepted manual cycle emitted repeated controlled legacy Communications
`no model` warnings after simultaneous device interaction. The retained v1
Communications Host/application harnesses passed, no Lua error escaped, and the
warnings do not originate in the v2 renderer. Their legacy per-frame diagnostic
throttling remains a later maintenance recommendation, not a PF.002 contract or
acceptance claim.

## Persistence and Compatibility

PF.002 runtime sessions are not registered with State Store or Save Manager.
Scroll, hover, pressed state, geometry, clips, plans, hit regions, generations,
and last-safe views are discarded on Host/ForgeOS shutdown. The existing save
completed without schema/version change. Retained Communications v1 Host and
application integration harnesses passed.

## Acceptance Gate

Implementation and required verification are complete. Project Director and
Chief Architect acceptance is still required. PF.003-PF.009 remain
unauthorized.
