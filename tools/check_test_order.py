"""Validate the FORGE development-suite lifecycle ordering contract."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path
import re
import sys


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
PHASES = (
    "PROCESS_INITIAL",
    "FOUNDATION",
    "LIFECYCLE_MUTATING",
    "END_TO_END",
)
PROCESS_INITIAL_HARNESS = "runForgeOSCoreTests"
PHASE_PATTERN = re.compile(r"-- TEST PHASE: ([A-Z_]+)")
HARNESS_PATTERN = re.compile(
    r'harness\(\s*"[^"]+"\s*,\s*FORGE\.Tests\s*\.\s*'
    r"(run[A-Za-z0-9_]+)",
    re.MULTILINE,
)
DEFINITION_PATTERN = re.compile(
    r"function\s+FORGE\.Tests\s*\.\s*(run[A-Za-z0-9_]+)\s*\(",
    re.MULTILINE,
)
LIFECYCLE_PATTERN = re.compile(
    r"FORGE\.(?:"
    r"ForgeOS\s*:\s*(?:start|completeStartup|shutdown)"
    r"|ForgeOSCore\s*:\s*transitionPhase"
    r")\s*\(",
    re.MULTILINE,
)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate development test phases and ForgeOS ordering."
    )
    parser.add_argument(
        "--engine",
        type=Path,
        default=REPOSITORY_ROOT / "engine" / "Engine.lua",
    )
    parser.add_argument(
        "--tests",
        type=Path,
        default=REPOSITORY_ROOT / "tests",
    )
    return parser.parse_args()


def discover_harnesses(tests_root: Path) -> tuple[dict[str, Path], set[str]]:
    definitions: dict[str, Path] = {}
    lifecycle_mutators: set[str] = set()
    for path in sorted(tests_root.rglob("*.lua")):
        text = path.read_text(encoding="utf-8")
        names = DEFINITION_PATTERN.findall(text)
        for name in names:
            if name in definitions:
                raise ValueError(
                    f"duplicate harness definition {name}: "
                    f"{definitions[name]} and {path}"
                )
            definitions[name] = path
            if LIFECYCLE_PATTERN.search(text):
                lifecycle_mutators.add(name)
    return definitions, lifecycle_mutators


def validate(engine_path: Path, tests_root: Path) -> list[str]:
    errors: list[str] = []
    engine = engine_path.read_text(encoding="utf-8")
    phase_matches = list(PHASE_PATTERN.finditer(engine))
    found_phases = tuple(match.group(1) for match in phase_matches)
    if found_phases != PHASES:
        errors.append(
            "phase order must be " + ", ".join(PHASES)
            + "; found " + ", ".join(found_phases)
        )

    invocations = list(HARNESS_PATTERN.finditer(engine))
    invoked_names = [match.group(1) for match in invocations]
    counts = Counter(invoked_names)
    for name, count in sorted(counts.items()):
        if count != 1:
            errors.append(f"harness {name} is invoked {count} times")

    try:
        definitions, lifecycle_mutators = discover_harnesses(tests_root)
    except ValueError as error:
        return errors + [str(error)]

    missing = sorted(set(definitions) - set(invoked_names))
    unknown = sorted(set(invoked_names) - set(definitions))
    if missing:
        errors.append("uninvoked harnesses: " + ", ".join(missing))
    if unknown:
        errors.append("undefined harnesses: " + ", ".join(unknown))

    invocation_phases: dict[str, str | None] = {}
    for invocation in invocations:
        preceding = [
            match for match in phase_matches if match.start() < invocation.start()
        ]
        invocation_phases[invocation.group(1)] = (
            preceding[-1].group(1) if preceding else None
        )

    if invocation_phases.get(PROCESS_INITIAL_HARNESS) != "PROCESS_INITIAL":
        errors.append(
            f"{PROCESS_INITIAL_HARNESS} must be in PROCESS_INITIAL"
        )

    lifecycle_order = [
        name for name in invoked_names if name in lifecycle_mutators
    ]
    if not lifecycle_order:
        errors.append("no ForgeOS lifecycle-mutating harnesses were discovered")
    elif lifecycle_order[0] != PROCESS_INITIAL_HARNESS:
        errors.append(
            "first ForgeOS lifecycle-mutating harness must be "
            f"{PROCESS_INITIAL_HARNESS}; found {lifecycle_order[0]}"
        )

    for name in lifecycle_order[1:]:
        phase = invocation_phases.get(name)
        if phase not in {"LIFECYCLE_MUTATING", "END_TO_END"}:
            errors.append(
                f"lifecycle-mutating harness {name} is in invalid phase {phase}"
            )
    return errors


def main() -> int:
    arguments = parse_arguments()
    errors = validate(arguments.engine.resolve(), arguments.tests.resolve())
    if errors:
        print("FORGE test-order preflight failed:")
        for error in errors:
            print(f"  - {error}")
        return 1
    print("FORGE test-order preflight passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
