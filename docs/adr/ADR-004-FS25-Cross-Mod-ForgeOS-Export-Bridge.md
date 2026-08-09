# ADR-004 - FS25 Cross-Mod ForgeOS Export Bridge

**Status:** Accepted; bounded M2.010 contract frozen
**Date:** 2026-08-09

## Context

M2.010 requires a real dependent FS25 companion mod to register an application
during production `REGISTRATION_OPEN`. Runtime evidence proved that a dependency
controls load ordering but does not inject its globals into the dependent mod's
custom Lua environment. Direct `FORGE` lookup therefore failed.

The installed GIANTS SDK documents mod-qualified lookup through
`ClassUtil.getClassObject()`, but FS25 1.21.1.0 runtime evidence proved that
`ClassUtil`/`getClassObject` is unavailable to the companion. That mechanism is
rejected and must not be retried.

## Options Considered

1. Inspect ModManager environment tables or manipulate Lua environments. These
   mechanisms are undocumented, unsafe, and rejected.
2. Reload FORGE scripts in the companion. This duplicates authoritative state.
3. Use network events. They serialize data and cannot carry a local façade.
4. Use `addModEventListener`. It provides callbacks but no lookup surface.
5. Use shared local `g_messageCenter` for a FORGE-owned synchronous adapter.
   This is selected for implementation and runtime proof.

## Decision

`FORGE.ForgeOSExportBridge` subscribes during Engine `loadMap`, after
`ForgeOS:start()` enters `REGISTRATION_OPEN` and before FORGE `loadMap` returns,
to the version-1 local topic:

```text
forge.crossMod.forgeOS.request.v1
```

The consumer publishes one caller-owned table containing
`requestedBridgeVersion = 1` and `responderCount = 0`. A valid bridge increments
`responderCount` and may set only `bridgeVersion = 1` and
`forgeOS = FORGE.ForgeOS`. Unsupported or malformed requests receive no
response. Consumers require exactly one responder, bridge version 1, and a
table façade before checking the independent ForgeOS App API version.

The bridge returns only `FORGE.ForgeOS`. It exposes no surrounding namespace,
registry, service, persistence, Engine, registration coordinator, Host, or
private executable asset. It retains no consumer request or callback after
synchronous handling.

The carrier is local-process only. No façade is serialized and no network
event, RPC, authority transfer, or remote API is introduced. Dedicated-server
behaviour requires separate verification.

Shutdown stops request acceptance, unsubscribes listeners owned by the bridge,
releases its carrier reference, and clears lifecycle state before ForgeOS
shutdown continues. Malformed input and unexpected handler failures are
contained without mutating ForgeOS state. Multiple providers are rejected by
the consumer through `responderCount`; no winner is selected.

## Status of the Protocol

The topic, synchronous reference behaviour, and cross-environment façade
transfer were proven in two real companion-mod runtime cycles on 2026-08-09.
M2.010 milestone acceptance freezes this bounded version-1 local-process
protocol as supported addon guidance.

## Consequences

- External companions gain one deliberately narrow acquisition path.
- ForgeOS App API and application-registration contracts do not change.
- FORGE gains one small production FS25 adapter and cleanup responsibility.
- The verifier is the first runtime-proven reference companion.
- Bridge compatibility remains distinct from App API and state versions.

## Rejected Mechanisms

Direct dependency globals, `ClassUtil`, ModManager environment internals,
`getfenv`/`setfenv`, arbitrary global scanning, guessed environment tables, and
`source()` duplication are unsupported.
