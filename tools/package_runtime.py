"""
=============================================================================
FORGE Runtime Package Tool
=============================================================================

Purpose:
    Builds, validates, and optionally deploys the FS25 runtime ZIP packages
    described in docs/developer/FS25RuntimeVerificationDeployment.md.

Responsibilities:
    • Run the pre-deployment gates (sync check, test order, tool tests).
    • Build an operational package and/or a verification package (operational
      plus the Development Test Bootstrap entry) from the synchronized
      prototype, using a staging copy so the prototype is never edited.
    • Validate each archive with tools/validate_runtime_package.py.
    • Optionally deploy one package to the FS25 mods directory as
      FS25_FORGE_Engine.zip, archiving any existing deployed file first, and
      require the deployed SHA-256 to match the built package.
    • Print and save the deployment record.

Design Principles:
    • Never edit the prototype, never delete, never overwrite a built package.
    • Refuse to deploy while FS25 is running.
    • Fail early with clear diagnostics; stop before deployment on any gate.

Usage:
    python tools/package_runtime.py PF.005
    python tools/package_runtime.py PF.005 --deploy verification
=============================================================================
"""

from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import importlib.util
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
TOOLS = REPOSITORY_ROOT / "tools"
PROTOTYPE = REPOSITORY_ROOT / "prototype" / "FS25_FORGE_Engine"
BUILDS = REPOSITORY_ROOT / "_builds"
BACKUPS = BUILDS / "deployed-backups"
DEPLOYED_NAME = "FS25_FORGE_Engine.zip"
BOOTSTRAP = "scripts/forge/tests/DevelopmentTestBootstrap.lua"
LOGGER = "scripts/forge/services/Logger.lua"
DEFAULT_MODS_DIRECTORY = (
    Path.home() / "OneDrive" / "Documents" / "My Games"
    / "FarmingSimulator2025" / "mods"
)
FIXED_TIME = (2026, 1, 1, 0, 0, 0)  # deterministic archive bytes
GAME_PROCESS = "FarmingSimulator2025.exe"


def load_validator():
    path = TOOLS / "validate_runtime_package.py"
    spec = importlib.util.spec_from_file_location("validate_runtime", path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run_gate(title: str, command: list[str]) -> str:
    print(f"[gate] {title}")
    result = subprocess.run(
        command, cwd=REPOSITORY_ROOT, capture_output=True, text=True
    )
    output = (result.stdout + result.stderr).strip()
    if result.returncode != 0:
        print(output)
        raise SystemExit(f"STOP: gate failed: {title}")
    return output


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def stage(mode: str, directory: Path) -> Path:
    """Copy the prototype into a staging directory, adding the bootstrap
    entry for a verification build."""
    staged = directory / "FS25_FORGE_Engine"
    shutil.copytree(PROTOTYPE, staged)
    if mode == "verification":
        mod_desc = staged / "modDesc.xml"
        text = mod_desc.read_bytes().decode("utf-8")
        match = re.search(
            rf'^([ \t]*)<sourceFile filename="{re.escape(LOGGER)}"/>(\r?\n)',
            text, re.MULTILINE)
        if match is None:
            raise SystemExit("STOP: Logger source entry not found in modDesc")
        entry = (f'{match.group(1)}<sourceFile filename="{BOOTSTRAP}"/>'
                 f"{match.group(2)}")
        text = text[:match.end()] + entry + text[match.end():]
        mod_desc.write_bytes(text.encode("utf-8"))
    return staged


def build_archive(staged: Path, target: Path) -> int:
    names = sorted(
        path.relative_to(staged).as_posix()
        for path in staged.rglob("*") if path.is_file()
    )
    names.remove("modDesc.xml")
    names.insert(0, "modDesc.xml")
    with zipfile.ZipFile(target, "x", zipfile.ZIP_DEFLATED) as package:
        for name in names:
            info = zipfile.ZipInfo(name, FIXED_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            package.writestr(info, (staged / name).read_bytes())
    return len(names)


def game_is_running() -> bool:
    try:
        result = subprocess.run(
            ["tasklist", "/FI", f"IMAGENAME eq {GAME_PROCESS}"],
            capture_output=True, text=True
        )
    except OSError:
        return False
    return GAME_PROCESS.lower() in result.stdout.lower()


def deploy(package: Path, mods_directory: Path, stamp: str) -> tuple[Path, str]:
    if game_is_running():
        raise SystemExit(f"STOP: {GAME_PROCESS} is running; close it first")
    if not mods_directory.is_dir():
        raise SystemExit(f"STOP: mods directory not found: {mods_directory}")
    destination = mods_directory / DEPLOYED_NAME
    if destination.exists():
        BACKUPS.mkdir(parents=True, exist_ok=True)
        backup = BACKUPS / f"FS25_FORGE_Engine_{stamp}.zip"
        shutil.copy2(destination, backup)
        print(f"[deploy] archived previous deployment to {backup}")
    shutil.copy2(package, destination)
    deployed_hash = sha256(destination)
    if deployed_hash != sha256(package):
        raise SystemExit("STOP: deployed SHA-256 does not match the package")
    return destination, deployed_hash


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build, validate, and optionally deploy FORGE FS25 packages.")
    parser.add_argument("label", help="batch label, for example PF.005")
    parser.add_argument(
        "--mode", choices=("operational", "verification", "both"),
        default="both", help="which package(s) to build (default: both)")
    parser.add_argument(
        "--deploy", choices=("operational", "verification"),
        help="copy this package to the FS25 mods directory")
    parser.add_argument(
        "--mods-directory", type=Path,
        default=Path(os.environ.get("FORGE_FS25_MODS_DIR",
                                    DEFAULT_MODS_DIRECTORY)))
    arguments = parser.parse_args()
    modes = (("operational", "verification") if arguments.mode == "both"
             else (arguments.mode,))
    if arguments.deploy and arguments.deploy not in modes:
        raise SystemExit("STOP: --deploy names a package that is not built")

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    python = sys.executable
    sync_line = run_gate(
        "synchronization check",
        [python, "tools/sync.py", "--check"]).splitlines()[-1]
    run_gate("test-order preflight", [python, "tools/check_test_order.py"])
    run_gate("tool regression tests",
             [python, "-m", "unittest", "discover", "tools/tests"])
    run_gate("operational prototype manifest",
             [python, "tools/validate_runtime_package.py",
              "--expect-bootstrap", "0"])

    validator = load_validator()
    BUILDS.mkdir(exist_ok=True)
    records: list[str] = [
        f"FORGE runtime package record - {arguments.label}",
        f"timestamp: {stamp}",
        f"synchronization: {sync_line.strip()}",
    ]
    built: dict[str, Path] = {}
    for mode in modes:
        target = BUILDS / f"FS25_FORGE_Engine_{arguments.label}-{mode}.zip"
        if target.exists():
            raise SystemExit(f"STOP: {target.name} already exists; "
                             "choose a new label or archive it yourself")
        with tempfile.TemporaryDirectory() as directory:
            staged = stage(mode, Path(directory))
            entries = build_archive(staged, target)
            expected = 1 if mode == "verification" else 0
            errors = validator.validate(staged, target, expected)
        if errors:
            raise SystemExit("STOP: package validation failed:\n  - "
                             + "\n  - ".join(errors))
        built[mode] = target
        declared = len(validator.declared_sources(
            zipfile.ZipFile(target).read("modDesc.xml")))
        print(f"[build] {target.name}: {entries} entries, "
              f"{declared} declared sources, SHA-256 {sha256(target)}")
        records += [
            f"{mode} package: {target.name}",
            f"  archive entries: {entries}; declared sources: {declared}",
            f"  package SHA-256: {sha256(target)}",
        ]

    if arguments.deploy:
        destination, deployed_hash = deploy(
            built[arguments.deploy], arguments.mods_directory, stamp)
        print(f"[deploy] {destination} SHA-256 {deployed_hash} (matches)")
        records += [
            f"deployed: {arguments.deploy} package",
            f"  destination: {destination}",
            f"  deployed SHA-256: {deployed_hash}",
        ]

    record = BUILDS / f"FS25_FORGE_Engine_{arguments.label}-{stamp}.record.txt"
    record.write_text("\n".join(records) + "\n", encoding="utf-8")
    print(f"[record] {record}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
