# Presentation Foundation Project Pause Handoff

**Status:** Project Paused  
**Pause Date:** 2026-08-30  
**Purpose:** Resume reference for a future Codex or other AI engineering agent

## Read this first

The FORGE Presentation Foundation project is intentionally on hold. Do not
infer authorization to continue from the existence of plans, implementation
files, tests, packages, or unfinished roadmap items.

Before resuming work, re-read:

1. `AGENTS.md`;
2. `docs/style/EngineeringProcess.md`;
3. `docs/EngineeringCharter.md`;
4. accepted ADRs and frozen Presentation Foundation contracts;
5. the latest Project Director / Design Lead / Chief Architect instruction;
6. this handoff; and
7. current `git status` and the complete relevant diff.

The repository has a large pre-existing dirty worktree containing accepted
milestone work, historical evidence, packages, screenshots, and unrelated
artifacts. Preserve it. Do not stage, commit, push, tag, reset, delete, rename,
move, clean, or discard anything without explicit authorization.

## Current milestone state

| Batch | State | Resume rule |
|---|---|---|
| PF.001 | Implemented, verified, accepted and frozen | Do not change vocabulary or semantics |
| PF.002 | Implemented, verified, accepted and frozen | Do not change shared renderer architecture |
| PF.003 | Implemented, verified, visually accepted and frozen | Do not change Laptop shell without a new gate |
| PF.004 | Implemented, verified, visually accepted and frozen | Do not change Phone shell without a new gate |
| PF.005 | Architecture/UX documentation plan proposed; approval not yet recorded | Do not create PF.005 architecture documents or implementation until explicitly approved |
| PF.006-PF.009 | Unauthorized | Do not begin |
| M4.001 | Paused | Do not resume implicitly |

The exact safe resume point is:

```text
PF.004 accepted and frozen
        ↓
PF.005 architecture/UX documentation plan returned
        ↓
WAITING FOR EXPLICIT PLAN APPROVAL
```

PF.005 production implementation is not authorized.

## Accepted operational fingerprints

- PF.001 clarified/refrozen operational fingerprint:
  `6DF733D93FE6446606CB21DF8DB8090993DD1B87BDCB1E9FC417068E3E4BDBC3`
- PF.002 operational fingerprint:
  `8472BF9B8A3ED573DA57BA7BB99E71B98E69AE7147D31961A98D37C1A654D10F`
- PF.003 operational package SHA-256:
  `AE46B6233E40B9D0D272DBF2213589C9F3A2D512D383D6F0BF7E6D6E6B4558D1`
- PF.004 operational and deployed SHA-256:
  `CF4F38FD2E7B7A02B13A30C59CA9F55CA607591F4F7162BE58BA28300848C5E7`
- PF.004 verification-completion runtime log SHA-256:
  `BE59F79511C3CAEA1070A3624324FCF504B0A92C199D2D84ABEEDC942E6C20C9`

Do not rebuild an accepted package merely to produce a new hash.

## PF.004 final verification evidence

Authoritative record:

- `docs/reviews/PF.004RuntimeVerification.md`
- `docs/reviews/evidence/PF.004-cycle2-verification-completion-log.txt`
- `docs/reviews/evidence/PF.004-verification-phone-home-over-gameplay.jpg`
- `docs/reviews/evidence/PF.004-verification-phone-active-over-gameplay.jpg`
- `FS25_FORGE_Engine_PF.004-operational.zip`

The accepted runtime cycle proved Engine startup, PhoneHost and LaptopHost
initialization, normal gameplay, persistence save, successful FS25 save,
LaptopHost shutdown, PhoneHost shutdown, ForgeOS stop, Engine shutdown, and
ordinary application quit. It contained no forced exit, Lua call stack,
runtime-method failure, save failure, or shutdown failure.

Seventeen controlled `Phone Communications model acquisition failed: no model`
warnings remain deliberately recorded. They did not block PF.004 acceptance.
Do not alter PF.004 solely to suppress them. PF.008 architecture must investigate
whether they disappear with the Communications model-v2 migration or reveal a
separate lifecycle issue; do not assume the cause.

## Frozen structural boundaries

Preserve all of the following:

- independent Phone and Laptop presentation sessions;
- one active application per device;
- registry-derived Laptop and Phone launchers;
- Host-owned shell and trusted application viewport boundaries;
- generic model-v2 presentation through PF.002;
- right-side Phone companion placement;
- Phone input priority inside overlapping Phone geometry;
- Laptop interaction outside Phone geometry;
- no permanent Laptop or Phone notification feed;
- no generic shell notification read/dismiss mutation;
- no application/domain-specific generic renderer behavior;
- unchanged public API versions and persistence schemas.

Grandfathered compatibility remains bounded:

- PF.007 owns Communications Laptop model-v2 migration and removal of the
  Communications-specific Laptop model-v1 renderer.
- PF.008 owns Communications Phone model-v2 migration and removal of the
  Communications-specific Phone model-v1 renderer.
- No new application may use either compatibility branch.

## PF.005 validation findings

PF.005 concerns application attention, not notifications.

Frozen PF.001/PF.002 contracts already provide the necessary vocabulary and
validation foundation:

- states: `none`, `unread`, `attention`, `warning`, `error`;
- exact optional non-negative count;
- optional accessible label;
- `indicator.badge` and `indicator.status`;
- semantic tokens and non-colour cue requirements;
- detached model-v2 `attention` validation.

Current compatibility path:

```text
Communications unread truth
        ↓
provider:getBadge()
        ↓
ApplicationPresentationService:getBadge()
        ↓
ForgeOS:getApplicationBadge()
        ↓
Laptop integer badge
```

Phone currently reserves attention geometry but does not present the generic
attention model. Laptop currently renders the compatible integer badge.

The proposed PF.005 architecture should add a private optional semantic
attention provider/query, validate and detach its result, map the existing
integer badge only when the semantic method is absent, and project the same
authoritative application/domain truth independently through both Hosts.

Important proposed rules awaiting architecture-plan approval:

- notifications never establish attention truth;
- Hosts never count notifications or domain records;
- count and semantic state are independent;
- legacy `0` maps to `none`; positive legacy count maps to `unread` with the
  exact count;
- malformed semantic output fails closed and is not concealed by legacy
  fallback;
- no persisted Host attention cache;
- no application-specific Host branch;
- visual count compression must not alter the authoritative exact value;
- final badge artwork remains a Design Lead decision.

## Proposed PF.005 documentation package

The last returned plan proposed these files, but it has not yet been approved:

1. `ForgeOSApplicationAttentionArchitecture.md` (new)
2. `ForgeOSPresentationArchitecture.md`
3. `ForgeOSComponentDesign.md`
4. `ForgeOSDesignSystem.md`
5. `ForgeOSDefinitions.md`
6. `ForgeOSAppContract.md`
7. `ForgeOSStateModel.md`
8. `LaptopUXSpecification.md`
9. `PhoneUXSpecification.md`
10. `CommunicationsAppContract.md`
11. `M2M3PresentationFoundationImplementationPlan.md`
12. `docs/README.md`

Do not modify these for PF.005 until the plan is explicitly approved.

## PF.005 open Design Lead decisions

- visual count-compression threshold;
- state-specific icon/shape vocabulary;
- low-count presentation form;
- Phone versus Laptop badge dimensions;
- count-free warning/error/attention treatment;
- accessible presentation within FS25 backend limits;
- reduced-motion-compatible animation policy, if any;
- final attention artwork and final token values.

These decisions may affect presentation but must not change frozen semantic
meanings.

## PF.005 STOP conditions

Stop and return for architecture authority if PF.005 would require:

- an App Registry field;
- public API or API-version change;
- PF.001 vocabulary/semantic change;
- PF.002 renderer semantic change;
- persistence change;
- notification-derived attention;
- a generic command/event bus;
- Host access to domain services;
- a new attention state, token, component, property, or protocol field;
- application-specific Host rendering.

## Validation state at pause

- PF.004 documentation/status metadata records it as implemented, verified,
  visually reviewed, accepted and frozen.
- `git diff --check` passed with only pre-existing line-ending warnings.
- No PF.005 production implementation was started.
- No synchronization, package rebuild, deployment, staging, commit, push, tag,
  reset, deletion, or cleanup was performed during PF.005 validation.
- The project is paused pending a future explicit instruction.

When work resumes, report current repository state and confirm the requested
gate before editing. Do not treat this handoff itself as authorization.
