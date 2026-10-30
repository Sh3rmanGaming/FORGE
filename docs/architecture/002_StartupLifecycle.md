# FORGE Startup Lifecycle

**Status:** Approved
**Version:** 1.1

## Purpose

This document defines the exact runtime sequence FORGE follows from the moment Farming Simulator 25 discovers the mod until FORGE is ready to process gameplay.

It separates:

- File loading
- Namespace creation
- Service initialisation
- Manager initialisation
- Mission lifecycle callbacks
- OS and app startup
- First gameplay update

## Phase 1 — Mod Discovery and Lua Loading

1. Farming Simulator 25 scans the active mods folder.
2. FS25 reads `modDesc.xml`.
3. FS25 validates the mod description version and declared source files.
4. Lua files are executed in the order defined by `modDesc.xml`.
5. `engine/FORGE.lua` creates the global `FORGE` namespace.
6. Definition files attach reusable definition tables to `FORGE`.
7. Service, manager, OS and app files define their tables and functions.
8. No mission-specific state is initialised during this phase.

## Phase 2 — Mission Initialisation

Once the player loads or creates a savegame, Farming Simulator begins the mission lifecycle.

1. FS25 creates the mission instance.
2. FORGE receives the `loadMap()` callback through `Engine.lua`.
3. The Engine validates that the FORGE runtime can be started.
4. Engine services are initialised.
5. Engine managers are initialised.
6. The Event Bus is brought online.
7. The Save Manager loads FORGE save data.
8. The State Store is populated.
9. ForgeOS opens registration and installs its production Device, Device Host,
   and App Registry participants plus the built-in Phone profile and Host.
10. Other participating mods may register while `loadMap()` processing remains
    in progress.
11. The first eligible Engine update completes registration exactly once.
12. ForgeOS enters `RUNTIME_ACTIVE` and publishes `STARTED`.
13. Communications registers and restores its accepted domain and application
    participants through their existing owners.
14. ForgeOS atomically constructs and initializes PhoneHost then LaptopHost.

## Phase 3 — Gameplay Runtime

After mission loading, normal gameplay processing begins.

1. FS25 calls `update(dt)` every frame.
2. `Engine.lua` forwards update processing to active FORGE managers and systems.
3. FS25 calls `draw()` every frame.
4. `Engine.lua` draws LaptopHost before PhoneHost so the Phone can appear above
   the Laptop when both are visible.
5. Update and normalized input delegation remain Phone-first, then Laptop; a
   visible Phone may claim its bounded pointer region before Laptop handling.
6. Engine owns input callbacks and delegates only bounded Host interactions.
7. Managers and systems communicate through the Event Bus where practical.
8. Shared multiplayer state is intended to remain server authoritative. The
   transport/request contract is a pre-gameplay-domain foundation gate and is
   not implemented merely by this lifecycle description.
9. Clients may display replicated state and request mutations only through a
   future approved authority boundary.
10. FORGE uses Farming Simulator game time as its simulation-clock source; a
    shared deadline contract remains required before time-dependent domains.

## Phase 4 — Save Lifecycle

FORGE persists its state through Farming Simulator's normal save process.

1. The player or server initiates a save.
2. FS25 begins writing the savegame to its temporary save directory.
3. The FORGE save hook is called as part of the normal save lifecycle.
4. The Save Manager checks whether the current instance has authority to write shared state.
5. Registered FORGE systems write their data into `forge.xml`.
6. The save is completed by Farming Simulator.
7. FS25 promotes the temporary save data into the active savegame folder.
8. FORGE does not maintain a separate external save location.

## Complete Startup Sequence

```text
Farming Simulator 25
        │
        ▼
Scan Mods
        │
        ▼
Read modDesc.xml
        │
        ▼
Execute Lua Files
        │
        ▼
Create FORGE Namespace
        │
        ▼
Definitions Available
        │
        ▼
Mission Created
        │
        ▼
Engine loadMap()
        │
        ▼
Initialise Services
        │
        ▼
Initialise Managers
        │
        ▼
Load Save Data
        │
        ▼
Populate State Store
        │
        ▼
Open ForgeOS Registration
        │
        ▼
Register Devices, Hosts and Apps
        │
        ▼
Complete Registration and Start ForgeOS
        │
        ▼
Restore Communications and Runtime Hosts
        │
        ▼
Gameplay Begins
```

## Resolved and Deferred Classification

- The Event Bus is initialized as an Engine service before runtime publication;
  changing earlier-service event availability requires a separate contract.
- Lua definition tables are available after ordered source execution. Future
  XML gameplay definitions require the separately reviewed Definition Registry.
- ForgeOS applications register explicitly through the accepted App Registry;
  automatic application discovery is not implied.
- Multiplayer request transport and authoritative client/server replication are
  deferred, with the restriction that future gameplay domains may not equate a
  local client call with authoritative mutation.
