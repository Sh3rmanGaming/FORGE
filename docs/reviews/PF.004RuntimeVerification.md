# PF.004 Runtime Verification

**Status:** Implemented, Verified, Visually Reviewed, Accepted and Frozen  
**Milestone:** PF.004 — Phone Shell  
**Date:** 2026-08-29

## Implemented scope

PF.004 provides the Host-owned compact Phone Home, registry-derived eligible
shortcuts, deterministic bounded paging, generic unresolved-icon fallback,
trusted standard/compact geometry profiles, protected shell/application
viewport boundaries, semantic shell chrome, OS Home, and the generic model-v2
PF.002 presentation path.

The permanent Phone notification feed, generic shell notification mutation,
hardcoded Communications launcher activation/hit region, four-app display cap,
oversized POC cards, and Active Surface/debug presentation are removed. The
existing active-app Communications model-v1 renderer remains the sole isolated
grandfathered exception inside the trusted viewport. PF.008 owns its model-v2
migration and removal.

No App Registry field, public API, persistence schema, PF.001/PF.002 semantic,
Phone placement, shared Host session, Communications schema/domain behaviour,
PF.005 attention, PF.006 notification, PF.008 UX, tutorial, mission, or Projects
architecture was introduced.

## Automated and static evidence

- complete retained FS25 development suite: passed;
- PF.004 Phone Host harness: passed;
- Phone Communications v1 integration: passed;
- synchronization before the operational package: 127 identical, with no
  divergent, missing, stale, or colliding files;
- test-order preflight: passed;
- `git diff --check`: passed, with pre-existing line-ending warnings only;
- operational archive has POSIX entry paths, one root `modDesc.xml`, Engine last
  in source order, and no DevelopmentTestBootstrap declaration;
- source search confirms no notification query/mutation, hardcoded launcher
  helper, four-app cap, Active Surface, or badge derivation in `PhoneHost.lua`.

The Phone Host harness covers empty, one, few, unavailable, missing-icon, and
13-app populations; six-cell standard and four-cell compact pages; incomplete
last page; pointer hover; press/release; release-outside cancellation; generic
open/activate/navigate; OS Home; clipping; outside-Phone pass-through; and
notification non-mutation. Standard geometry uses 1920x1080 at scale 1;
compact geometry uses 1280x1024 at scale 1.25.

The integration harness proves that Communications is projected from the App
Registry, opens through ordinary lifecycle/presentation resolution, retains its
model-v1 behaviour, and cannot create hit regions outside the trusted Phone
application viewport. Generic model-v2 behavior remains application-agnostic.
The retained PF.002 multi-Host tests cover bidirectional Phone/Laptop session
independence and input ownership.

## FS25 runtime evidence

- log: `evidence/PF.004-cycle1-runtime-log.txt`;
- SHA-256:
  `C16A6BD089C4CBFA385146724B34958041EE7A877F4D158E6F991FFE70FDFD42`;
- complete development suite passed at runtime;
- Phone Communications presentation integration passed;
- normal FORGE persistence save completed (`saveCount=1`);
- FS25 reported `Game saved successfully (savegame19)`;
- no unintended FORGE Lua call stack was observed in the verification segment.

Cycle 1 established implementation/test evidence but its forced final process
exit was rejected as clean-shutdown evidence.

### Verification-completion cycle 2

- log: `evidence/PF.004-cycle2-verification-completion-log.txt`;
- SHA-256:
  `BE59F79511C3CAEA1070A3624324FCF504B0A92C199D2D84ABEEDC942E6C20C9`;
- current operational package loaded without rebuilding;
- Engine startup completed and both production Hosts initialized;
- FORGE persistence saved normally (`saveCount=70`);
- FS25 reported `Game saved successfully (savegame3)`;
- LaptopHost shut down normally;
- PhoneHost shut down normally;
- ForgeOS stopped normally;
- Engine shutdown completed with zero event groups and all three state
  namespaces and persistence registrations cleared;
- FS25 recorded `Application quit`, not a forced-exit marker.

The cycle emitted repeated controlled `Phone Communications model acquisition
failed: no model` warnings between the successful save request and normal
shutdown. The Phone application had rendered successfully for the captured
evidence. No Lua call stack, shutdown failure, schema change, or persistence
failure accompanied the warnings. They are recorded as an unexpected diagnostic
for later Communications/PF.008 review; no production change was authorized or
made during verification completion.

## Visual evidence

- `evidence/PF.004-restore-check.png`: compact one-app Phone Home with generic icon
  fallback over the Laptop Desktop;
- `evidence/PF.004-phone-active-over-laptop-desktop.png`: grandfathered Communications
  active within the trusted Phone viewport over the Laptop Desktop;
- `evidence/PF.004-menu-check.png`: Phone active application and restrained shell chrome
  coexisting with the Laptop Desktop.
- `evidence/PF.004-verification-phone-home-over-gameplay.jpg`: required truthful Phone
  Home composition over normal exterior gameplay with Laptop hidden; SHA-256
  `1F9417B2DC2FA2F30B70DDD51DF8FA10A96317B38D6B8EFF3B2F74428CCB4DF4`;
- `evidence/PF.004-verification-phone-active-over-gameplay.jpg`: truthful grandfathered
  Communications active application over the same gameplay context with Laptop
  hidden; SHA-256
  `B854C40ADD8A899D555455D1B60889124FC987DFB6DAECA68D0E9ACD41A68348`.

These images demonstrate right-side placement, compact hierarchy, useful
Laptop visibility, minimal chrome, absence of the permanent notification feed,
and the Host-owned viewport boundary. The actual registry contains one eligible
Phone application, so no production applications were fabricated for an
overflow screenshot; the 13-app paging case is automated evidence.

The required gameplay-only Home composition and the optional active-app
composition are now proven at actual Phone size. Dark/night, second physical
resolution, machinery context, and Phone-active over Laptop-active remain later
integrated visual checks. The supplied high-fidelity concept remains
visual-direction authority; these screenshots are implementation evidence only.

## Packaging and deployment

- verification package: `FS25_FORGE_Engine_PF.004-verification.zip`;
- verification/deployed SHA-256:
  `D0BA8FA3A74622871F67FB376B08D757B9376335678A6959D27DE82AD1F5A4A1`;
- operational package: `FS25_FORGE_Engine_PF.004-operational.zip`;
- operational/deployed SHA-256:
  `CF4F38FD2E7B7A02B13A30C59CA9F55CA607591F4F7162BE58BA28300848C5E7`.

The operational archive and deployed FS25 package hashes match. The bootstrap
source remains in the package as retained test source but is not declared by
operational `modDesc.xml`, so it cannot auto-run in the operational deployment.

## Acceptance boundary

The Project Director, Design Lead, and Chief Architect accepted and froze PF.004
on 2026-08-30 at operational/deployed SHA-256
`CF4F38FD2E7B7A02B13A30C59CA9F55CA607591F4F7162BE58BA28300848C5E7`.
Acceptance freezes the companion composition, right-side placement, shell
hierarchy, registry-derived launcher, trusted application viewport, navigation
and input ownership, independent Host sessions, and removal of the permanent
notification feed and generic shell notification mutation.

Acceptance does not freeze exact palette or spacing values, typography, FORGE
mark, application/fallback icon artwork, final application composition,
attention appearance, or notification appearance as final art. The approved
high-fidelity concept remains visual-direction authority for open visual gates.

The 17 controlled Communications model-v1 acquisition warnings remain recorded
for PF.008 investigation without an assumed cause. PF.008 remains the mandatory
owner of Communications Phone model-v2 migration and deletion of the
grandfathered renderer. Dark/night, machinery, second physical resolution,
Phone-active over Laptop-active, and truthful large-population runtime captures
remain appropriate integrated PF.009 verification targets rather than PF.004
blockers.

PF.005-PF.009 implementation remains unauthorized, and M4.001 remains paused.
