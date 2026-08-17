# FS25 Runtime Verification Deployment

**Status:** Approved
**Version:** 1.0

## Purpose

This procedure proves that reviewed authoritative source, synchronized
prototype, verified ZIP package, deployed ZIP, and FS25 runtime evidence
represent one traceable build. It prevents packaging or deployment defects
from being confused with implementation defects.

## Scope

Use this procedure for every FORGE FS25 runtime-verification build. Verification
ZIP artifacts remain outside Git unless separately approved.

## Build Chain

```text
reviewed authoritative source
    ↓
synchronized prototype
    ↓
verified ZIP package
    ↓
deployed ZIP
    ↓
FS25 runtime evidence
```

## Pre-deployment Procedure

1. Require a clean `python tools/sync.py --check` result for every controlled
   authoritative/prototype pair.
2. Run `python tools/check_test_order.py`. The development suite must retain
   the exact `PROCESS_INITIAL`, `FOUNDATION`, `LIFECYCLE_MUTATING`, and
   `END_TO_END` phase order. `ForgeOSCoreTest` must be the first harness that
   can start or stop ForgeOS.
3. Enable `DevelopmentTestBootstrap.lua` only through its reviewed
   `modDesc.xml` source entry.
4. Run
   `python tools/validate_runtime_package.py --expect-bootstrap 1` before
   packaging.
5. Package the contents of `prototype/FS25_FORGE_Engine/`, not the directory's
   parent and not an enclosing directory.
6. Require `modDesc.xml` at the ZIP root.
7. Require POSIX `/` separators for every ZIP entry. Reject every entry
   containing `\`.
8. Open and parse the packaged `modDesc.xml`.
9. Enumerate every declared `<sourceFile>` path. Require each exact relative
   path to exist exactly once in the ZIP.
10. Reject duplicate ZIP entries and unexpected package contents.
11. Verify dependency order, including Logger before Development Test
   Bootstrap, production dependencies before their consumers, harness
   definitions before Engine, and `Engine.lua` last.
12. Run `python tools/validate_runtime_package.py --expect-bootstrap 1
    --archive <verification.zip>` against the completed archive.
13. Run `python -m unittest discover tools/tests` and require every preflight
    regression test to pass.
14. Record synchronization inventory counts, archive entry count, declared
    source count, package SHA-256, deployed SHA-256, destination, and timestamp.
15. Deploy the validated ZIP and require its SHA-256 to match the package
    SHA-256 before launching FS25.

## Deployment Hard Gate

STOP before FS25 launch when:

- synchronization is not clean;
- test-suite phase or lifecycle ordering is invalid;
- `modDesc.xml` is not at the ZIP root;
- any ZIP path contains a backslash;
- an archive entry is duplicated or unexpected;
- a declared source is absent, duplicated, or path-mismatched;
- Logger/bootstrap ordering is incorrect;
- production dependencies are out of order;
- a harness loads after Engine;
- `Engine.lua` is not last;
- package and deployed hashes differ; or
- the package cannot be tied deterministically to the reviewed prototype.

Do not use an FS25 launch to discover a packaging defect detectable by static
inspection.

## Development Suite Phase Contract

The Engine test runner owns four ordered phases:

```text
PROCESS_INITIAL
    -> FOUNDATION
    -> LIFECYCLE_MUTATING
    -> END_TO_END
```

`PROCESS_INITIAL` contains assertions that can be made only once in a genuine
Lua process. The ForgeOS Core harness checks `UNAVAILABLE` before it performs
any lifecycle mutation. A normal `shutdown()` produces `STOPPED`; tests must
never fabricate a return to `UNAVAILABLE`.

Every runtime harness records its ForgeOS phase before and after execution. A
declared phase prerequisite fails fast with the harness name, required phase,
and observed phase. New harnesses that call `ForgeOS:start()`,
`completeStartup()`, or `shutdown()` belong after the process-initial harness
and must pass `tools/check_test_order.py` before packaging.

## Runtime Evidence

Run one complete mission lifecycle. Preserve `log.txt` without relaunching the
mission or game before evidence capture. Record the log identity, package
identity, development-suite outcome, production startup, persistence, normal
shutdown, and any intentional negative-path diagnostics.

## Operational Restoration

After successful evidence capture:

1. remove the explicit Development Test Bootstrap entry from `modDesc.xml`;
2. preserve the bootstrap source;
3. confirm the permanent Logger default remains false;
4. require bootstrap entry count zero;
5. reparse operational XML and verify `Engine.lua` remains last;
6. run `python tools/validate_runtime_package.py --expect-bootstrap 0`;
7. rerun `python tools/sync.py --check`; and
8. report the restored operational prototype separately from the retained
   verification package.

## Required Deployment Record

Each milestone runtime record must identify:

- synchronization manifest counts;
- ZIP entry and declared-source counts;
- package SHA-256;
- deployed SHA-256;
- deployment destination and timestamp;
- log path, timestamp, hash, and relevant lines;
- bootstrap removal and operational revalidation.

## Related Documents

- [Engineering Process](../style/EngineeringProcess.md)
- [Git Workflow](../style/GitWorkflow.md)
- [M2 Architecture Review](../reviews/M2ArchitectureReview.md)
