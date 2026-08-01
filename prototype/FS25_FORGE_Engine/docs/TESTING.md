# FORGE Engine 0.2 Test Procedure

1. Remove the previous `FS25_FORGE_Core.zip` from the mods folder to avoid loading both prototypes.
2. Copy `FS25_FORGE_Engine.zip` into the FS25 mods folder.
3. Enable **FORGE Engine** on a disposable test save.
4. Enter the map and save once.
5. Exit to the main menu.
6. Search `log.txt` for `[FORGE]`.
7. Confirm `forge.xml` exists in the savegame directory.
8. Reload and save again; confirm `totalSessions` increases.

Expected key log lines:

- `[FORGE] INFO: Lua sources loaded; waiting for mission lifecycle`
- `[FORGE] INFO: Loading FORGE Engine v0.2.0.0`
- `[FORGE] INFO: Registered module 'forge.engine' v0.2.0.0`
- `[FORGE] INFO: FORGE ready: modules=1 session=... authority=true`
- `[FORGE] INFO: Saved FORGE data to .../forge.xml`

Report every `[FORGE]` line and any nearby `Error`, `Warning`, or call stack.
