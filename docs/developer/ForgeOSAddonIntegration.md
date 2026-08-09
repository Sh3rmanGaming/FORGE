# ForgeOS Addon Integration

**Status:** Verified M2.010 reference guidance

**Bridge Protocol:** 1

**ForgeOS App API:** 1

## Purpose

This guide defines the runtime-proven pattern by which a dependent FS25 mod
acquires the public ForgeOS facade and registers an application. FS25 dependency
ordering loads FORGE first, but does not inject FORGE globals into the dependent
mod's custom Lua environment.

The platform carrier is the local process's `g_messageCenter`. The FORGE adapter
is `FORGE.ForgeOSExportBridge`. The only application-facing value returned is
the existing `FORGE.ForgeOS` facade.

## Dependency

Declare the production mod identifier in the companion `modDesc.xml`:

```xml
<dependencies>
    <dependency>FS25_FORGE_Engine</dependency>
</dependencies>
```

The dependency establishes load order. It is not a global-import mechanism.

## Facade Acquisition

During the companion's `loadMap`, first confirm that
`FS25_FORGE_Engine` is known and loaded and that `g_messageCenter:publish()` is
available. Then publish exactly one caller-owned response container:

```lua
local response = {
    requestedBridgeVersion = 1,
    responderCount = 0
}

g_messageCenter:publish(
    "forge.crossMod.forgeOS.request.v1",
    response
)

if response.responderCount ~= 1
    or response.bridgeVersion ~= 1
    or type(response.forgeOS) ~= "table" then
    return
end

local forgeOS = response.forgeOS
response = nil

if forgeOS:supportsAppApiVersion(1) ~= true
    or forgeOS:getAppApiVersion() ~= 1 then
    return
end
```

Zero responders means no provider was available. More than one means provider
identity is ambiguous. Reject both; do not select the first or last response,
retry on later frames, inspect another mod's environment, or use a fallback
acquisition path.

## Registration Timing

The companion must acquire the facade and call `registerApp()` during its
`loadMap`, while `forgeOS:getPhase()` is `registrationOpen`. FORGE subscribes
the bridge before its own `loadMap` returns and freezes registration on its
first eligible update after all mod `loadMap` callbacks complete.

Failure at any dependency, carrier, responder, bridge-version, App API, phase,
or required-operation boundary must emit one concise companion diagnostic,
perform no partial registration, and mutate no ForgeOS state.

## Security and Scope Boundary

The bridge is local-process only. No table is serialized and no network event,
RPC, authority transfer, or remote registration is introduced. Each client or
server process owns its own carrier, bridge, and facade. Dedicated-server
behaviour remains separately unverified.

Applications may use only documented `FORGE.ForgeOS` operations. They must not
seek or retain the surrounding FORGE namespace, registries, services, State
Store, Save Manager, Engine, hosts, bootstrap objects, or private executable
references.

## Reference Implementation

`verification/FS25_FORGE_M2010_Verifier/` is the first runtime-verified
companion-mod reference implementation. It demonstrates dependency validation,
one-shot bridge acquisition, compatibility validation, registration during the
open window, public-facade-only navigation and notification use, and clean
lifecycle release.

See [ADR-004](../adr/ADR-004-FS25-Cross-Mod-ForgeOS-Export-Bridge.md) for the
decision record and [M2.010 Runtime Verification](../reviews/M2.010RuntimeVerification.md)
for the real two-cycle evidence.
