# FORGE M2.012 Runtime Verifier

Temporary non-production companion mod for the controlled M2.012 two-cycle
end-to-end verification. It acquires only `FORGE.ForgeOS` through the frozen
version-1 cross-mod bridge, validates App API version 1, and registers one app
with separate Phone and Laptop presentations during `REGISTRATION_OPEN`.

Cycle 1 establishes independent Phone/Laptop navigation and two shared
Phone-and-Laptop SAVEGAME notifications. The verifier mutates only its own
fixtures through the public façade, then proves the read and dismissal state
through separate Phone and Laptop queries before the operator saves. This keeps
the proof deterministic even when older retained notifications occupy the
bounded Host tray. Cycle 2 verifies that the shared states and independent
routes survive the hard restart and remain observable from both projections.

The verifier is not production infrastructure, is excluded from FORGE
synchronization and packaging, and provides no multiplayer or dedicated-server
evidence.
