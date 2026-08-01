# FORGE Foundation Architecture

## Server authority

The server owns persistent FORGE state and writes `forge.xml`. Client replication will be implemented through explicit network events in a later milestone.

## Core services

- `ForgeLogger`: consistent diagnostics.
- `ForgeEventBus`: decoupled module communication.
- `ForgeModuleRegistry`: discovers installed FORGE modules.
- `ForgeStateStore`: shared runtime state.
- `ForgeSaveManager`: embedded savegame persistence and extensible save sections.
- `ForgeEngine`: FS mission lifecycle entry point.

## Data-driven direction

Campaigns, missions, NPCs, communications, tutorials, rewards and conditions will be XML content. Lua will provide reusable objective types and integrations.
