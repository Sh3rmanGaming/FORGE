# PF.001 Runtime Verification

**Status:** Clarification Verified, Accepted and Refrozen
**Milestone:** PF.001 - Contracts, Tokens and Protocol Definitions
**Verification Date:** 2026-08-22

## Purpose

Record the FS25 load-order and definition-harness evidence for the bounded
PF.001 presentation vocabulary. This verification does not claim a renderer,
Host redesign, notification presentation coordinator, route-schema execution,
or any PF.002-PF.009 behavior.

## Verified Baseline

- Baseline commit: `e5c5d16bf3e07050a17939281da41c79a03d37ec`
- Branch: `development`
- Farming Simulator 25: `1.21.1.0`
- GIANTS Engine Runtime: `10.0.0 (47901)`
- FORGE package version: `0.4.1.0`
- Verification save: savegame 20 (test use; PF.001 changes no persisted state)
- Synchronization inventory: Engine 12, Tests 47, ForgeOS 46,
  Communications 12; total 117
- Synchronization result: 117 identical; zero divergent, missing, stale, or
  colliding paths

## Verification Package

- Archive: `FS25_FORGE_Engine_PF.001-verification.zip`
- ZIP entries: 141
- Declared source files: 112
- Development bootstrap entries: one, after Logger and before runtime services
- SHA-256:
  `C3242038D2488C81AFADF4ECC5E0E12AA96F064073E12D3C30E49985F0AB541B`
- Deployed SHA-256: identical
- Deployment:
  `C:\Users\sheri\OneDrive\Documents\My Games\FarmingSimulator2025\mods\FS25_FORGE_Engine.zip`

The archive validator passed, `modDesc.xml` was present at the ZIP root,
`Engine.lua` remained last, and the archive contained no duplicate or
backslash-path entries.

## Runtime Evidence

- Log:
  `C:\Users\sheri\OneDrive\Documents\My Games\FarmingSimulator2025\log.txt`
- Log SHA-256:
  `A8FC0F0E5D82BEF596976530AFBEF013AF3043EA836AA606BAEE2985466292D6`
- Log size: 281,303 bytes
- Log timestamp: 2026-08-22 19:31:06 +08:00

Relevant evidence:

- line 564: development verification mode enabled;
- line 1247: complete retained development suite started;
- lines 1249-1250: ForgeOS Definitions harness started and passed;
- line 1891: complete retained development suite passed;
- line 2177: operational ForgeOS runtime became active;
- line 2207: persistence saved normally; and
- line 2239: Engine shutdown completed with event groups, state namespaces,
  and persistence registrations cleared.

The retained suite intentionally emits controlled negative-path errors and
warnings. The log also contains unrelated external-mod warnings and the
historically accepted Communications log-source normalization described by
M3.003. Controlled Host model-unavailable warnings occurred during late
interaction/shutdown. None caused a harness failure, Lua stack failure,
persistence failure, or incomplete Engine shutdown.

## PF.001 Contract Verified

The harness proved exact presence and absence checks for:

- presentation model versions 1 and 2;
- bounded component and semantic property identifiers;
- layout directions, alignment, distribution, size modes/tokens, grow weights,
  clipping, overflow, and text alignment;
- semantic surface, text, accent, state, border, spacing, typography, and
  motion token identifiers without concrete palette values;
- envelope, action-reference, attention, and route-schema fields;
- application and Host-shell action targets;
- exact attention states and legacy badge-state mapping;
- route-parameter types;
- notification banner, toast, sound, activation-stage, and layered result
  vocabulary;
- positive integer protocol limits; and
- PF.001 diagnostic log sources.

PF.001 did not change `ForgeOSVersion.APP_API`, persisted schema versions,
ForgeOS/Communications state, lifecycle, Navigation execution, Hosts, or public
addon APIs.

## Operational Restoration

The Development Test Bootstrap source entry was removed after runtime evidence
capture. Bootstrap source remains available as development infrastructure and
Logger's default remains false.

- Operational archive: `FS25_FORGE_Engine_PF.001-operational.zip`
- ZIP entries: 141
- Declared source files: 111
- Bootstrap entries: zero
- Operational SHA-256:
  `56E6AEAB3CB688FF5DCEE990CE8415835FE39592B03274408F4DEE9CA7049352`
- Deployed SHA-256: identical

Operational package validation, synchronization identity, and test-order
preflight passed. `Engine.lua` remains last.

## Conclusion

PF.001 implementation and definition/load-order verification are complete. The
Project Director and Chief Architect accepted and froze PF.001 on 2026-08-22.
The accepted operational package fingerprint remains:
`56E6AEAB3CB688FF5DCEE990CE8415835FE39592B03274408F4DEE9CA7049352`.
PF.002 implementation is not authorized and has not begun.

## Bounded Clarification — 2026-08-22

After the original acceptance, the PF.002 architecture audit found that the
frozen vocabulary did not yet define a canonical node discriminator, bounded
text-flow controls, or an unambiguous action-reference object. The Project
Director and Chief Architect approved a narrowly bounded PF.001 clarification.

The original verification and package fingerprints above remain historical and
must not be replaced or presented as evidence for the clarification.

The clarification implementation adds:

- canonical `component`, `id`, `properties`, and `children` node fields;
- exact component property/child/interaction/semantic-state contracts;
- `none`/`word` text wrapping and `clip`/`ellipsis` text overflow;
- optional positive `maximumLines`, bounded at 32;
- exact `application` and `host` action targets;
- an action-reference object using `target`, `actionId`, and `parameters`;
- Host action identifiers `osHome` and `deviceClose`; and
- explicit preservation of Navigation/application-owned Back behavior.

Clarification runtime evidence, verification archive hash, log hash,
operational archive hash, deployed hash, synchronization inventory, and
refreeze decision will be appended after the dedicated verification run.
PF.002 remains paused and no PF.002 runtime implementation is included.

### Clarification verification package prepared

- Archive: `FS25_FORGE_Engine_PF.001-clarification-verification.zip`
- ZIP entries: 147
- Declared source files: 118
- Development bootstrap entries: one, after Logger
- Synchronization inventory: Engine 12, Tests 47, ForgeOS 52,
  Communications 12; total 123
- Synchronization result: 123 identical; zero divergent, missing, stale, or
  colliding paths
- SHA-256:
  `22EDAD8F806EA84191AE7E30CA93EFA5E820E59E8AD88C622CE3C040070EC9E9`
- Deployed SHA-256: identical
- Deployment:
  `C:\Users\sheri\OneDrive\Documents\My Games\FarmingSimulator2025\mods\FS25_FORGE_Engine.zip`

Static runtime-package validation, source/load-order preflight, synchronization
verification, `Engine.lua`-last enforcement, and all five packaging-tool
regression tests passed before deployment. FS25 runtime evidence and
operational restoration remain pending.

### Failed clarification verification run 1

- Verification save: savegame 3
- Log SHA-256:
  `81BF5C81CD5BD16901993CE9A0018B861CB205142D51129E23B05EC9BE48B5BE`
- Log timestamp: 2026-08-22 20:11:35 +08:00
- Package SHA-256:
  `22EDAD8F806EA84191AE7E30CA93EFA5E820E59E8AD88C622CE3C040070EC9E9`
- line 1256: ForgeOS Definitions harness started;
- line 1257: harness rejected an invalid `indicator.badge` content-source
  contract; and
- line 1899: retained suite completed with reported failures.

Save and shutdown still completed cleanly at lines 2201-2207. The failure was
caused by clarification test/definition data assigning Status content sources
to Badge. The failed run is rejected as acceptance evidence and is retained
here rather than overwritten. The bounded correction moves that conditional
content rule to `indicator.status`; it changes no approved protocol decision.

### Clarification verification package r2 prepared

- Archive: `FS25_FORGE_Engine_PF.001-clarification-verification-r2.zip`
- SHA-256:
  `B551F71A21BBDD6BC954B98FE6284570212D508F26E45BD1A0BBA13826206741`
- Deployed SHA-256: identical
- Synchronization result: 123 identical; zero divergent, missing, stale, or
  colliding paths
- Development bootstrap entries: one, after Logger

The corrected package passed source/test ordering, archive validation,
`Engine.lua`-last enforcement, synchronization verification, diff checking,
and all five packaging-tool regression tests before deployment. Runtime
verification was then completed using savegame 3.

### Successful clarification verification run 2

- Verification save: savegame 3
- Verification package SHA-256:
  `B551F71A21BBDD6BC954B98FE6284570212D508F26E45BD1A0BBA13826206741`
- Deployed verification SHA-256: identical
- Log SHA-256:
  `CBDB603E7DF7EA38883B98F9C6F7DA0D3951574E66979F20B7D63F7024570A42`
- Log size: 276,189 bytes
- Log timestamp: 2026-08-22 20:17:30 +08:00

Relevant evidence:

- line 559: development verification mode enabled;
- line 1239: complete retained development suite started;
- lines 1241-1242: ForgeOS Definitions harness started and passed;
- lines 1885-1886: end-to-end integration and complete retained suite passed;
- lines 2187-2188: persistence and savegame 3 save completed normally; and
- line 2193: Engine shutdown completed with event groups, state namespaces,
  and persistence registrations cleared.

No test-harness failure, reported-suite failure, escaped Lua stack trace, or
incomplete shutdown marker was present. Existing intentional negative-path
diagnostics and unrelated external-mod/texture warnings remained within the
historically accepted retained-suite baseline.

### Clarified operational restoration

The Development Test Bootstrap entry was removed after successful evidence
capture. Bootstrap source remains development infrastructure and Logger's
default remains false.

- Operational archive:
  `FS25_FORGE_Engine_PF.001-clarification-operational.zip`
- ZIP entries: 147
- Declared source files: 117
- Bootstrap entries: zero
- Operational SHA-256:
  `6DF733D93FE6446606CB21DF8DB8090993DD1B87BDCB1E9FC417068E3E4BDBC3`
- Deployed SHA-256: identical

Operational archive validation, source/test ordering, synchronization identity,
and `Engine.lua`-last enforcement passed. The clarification is implemented and
verified.

### Clarification acceptance and refreeze

The Project Director and Chief Architect accepted and refroze the clarified
PF.001 contract on 2026-08-22. The current Presentation Foundation definition
baseline is the clarified protocol with operational fingerprint:
`6DF733D93FE6446606CB21DF8DB8090993DD1B87BDCB1E9FC417068E3E4BDBC3`.

The original PF.001 acceptance/fingerprint, rejected clarification run 1,
successful clarification run 2, and current operational package remain separate
evidence stages in this record. PF.002 architecture may resume; PF.002
implementation remains unauthorized.
