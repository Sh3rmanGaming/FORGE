# FORGE M2.011 Runtime Verifier

Temporary non-production companion mod for the controlled M2.011 two-cycle
Laptop Host verification. It acquires only `FORGE.ForgeOS` through the frozen
version-1 cross-mod bridge, validates App API version 1, and registers one app
with separate Phone and Laptop presentations during `REGISTRATION_OPEN`.

The verifier creates distinct device navigation and SAVEGAME notification
fixtures in Cycle 1 and verifies their independent restoration in Cycle 2. It
does not construct a Host, access FORGE internals, implement a physical Laptop
object, or participate in production synchronization or packaging.
