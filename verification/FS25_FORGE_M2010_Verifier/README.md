# FORGE M2.010 Runtime Verifier

This directory contains temporary, non-production verification infrastructure
for the controlled M2.010 Phone Host runtime gate.

The companion mod depends on `FS25_FORGE_Engine`. It registers one declarative
verification application during the real ForgeOS registration window and uses
only the public ForgeOS facade to establish or inspect controlled navigation
and SAVEGAME notification state.

Cross-mod acquisition uses the approved provisional MessageCenter bridge. The
companion publishes exactly one request:

```lua
local response = { requestedBridgeVersion = 1, responderCount = 0 }
g_messageCenter:publish("forge.crossMod.forgeOS.request.v1", response)
```

It requires exactly one responder and bridge version 1, discards the response
container, retains only the resulting `FORGE.ForgeOS` facade, and validates App
API version 1 before registration. There is no ClassUtil, environment lookup,
fallback, or retry path. This mechanism remains provisional pending real
cross-mod runtime proof and must not yet be described as the permanent
addon-integration contract.

It is deliberately excluded from `tools/sync.py`, the FORGE production
prototype, and the FORGE production package. It creates no Host, owns no
ForgeOS runtime state, and defines no public ForgeOS API.

## Use

1. Use a dedicated verification save, never a normal gameplay save.
2. Package the contents of this directory with `modDesc.xml` at the ZIP root.
3. Deploy as `FS25_FORGE_M2010_Verifier.zip` beside the verified FORGE package.
4. Record package and deployed SHA-256 identities for both mods.
5. Run Cycle 1 to create the controlled route and notification fixture.
6. Save and exit normally without rebuilding either package.
7. Run Cycle 2 on the same save to verify persisted resume and notification
   restoration.
8. Remove the verifier ZIP from the active FS25 mods directory after evidence
   capture.

Fixture detection uses verifier-owned notification source, title, and metadata.
No separate persistent verifier flag is created. A partial fixture is treated
as a hard verification failure and is never silently repaired or overwritten.

F7 remains the production, user-remappable Phone toggle. This verifier does not
inject Phone Host input and does not define F8/F9 controls.
