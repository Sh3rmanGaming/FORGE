"""
=============================================================================
FORGE Synchronisation Tool
=============================================================================

Purpose:
    Synchronises configured authoritative FORGE source trees into the prototype
    reference implementation.

Responsibilities:
    • Validate the required repository structure.
    • Build one combined synchronisation manifest.
    • Recursively synchronise Engine, tests, ForgeOS, and Communications.
    • Remove stale prototype files controlled by the synchronisation process.
    • Report synchronisation results.

Design Principles:
    • The repository is the source of truth.
    • Synchronisation is recursive, repeatable, and idempotent.
    • New files within configured source trees require no tool changes.
    • Source-path collisions are rejected.
    • Fail early with clear diagnostics.
    • Never modify authoritative source files.

This tool is part of the FORGE developer toolchain.
=============================================================================
"""

from __future__ import annotations

import argparse
from pathlib import Path
import filecmp
import shutil


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


CONFIG = {
    "version": "0.2.0-dev",

    "paths": {
        "engine": REPOSITORY_ROOT / "engine",
        "tests": REPOSITORY_ROOT / "tests",
        "forgeos": REPOSITORY_ROOT / "forgeos",
        "communications": REPOSITORY_ROOT / "communications",
        "prototype": (
            REPOSITORY_ROOT
            / "prototype"
            / "FS25_FORGE_Engine"
            / "scripts"
            / "forge"
        ),
    },

    "required_engine_files": (
        Path("FORGE.lua"),
        Path("Engine.lua"),
    ),

    "excluded_directory_names": {
        ".git",
        ".idea",
        ".pytest_cache",
        ".vscode",
        "__pycache__",
    },

    "excluded_file_names": {
        ".DS_Store",
        "Thumbs.db",
    },

    "excluded_file_suffixes": {
        ".pyc",
        ".pyo",
    },
}


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description=(
            "Synchronise authoritative FORGE source into the prototype."
        )
    )

    parser.add_argument(
        "--check",
        action="store_true",
        help=(
            "Report prototype drift without copying, deleting, "
            "or creating files."
        ),
    )

    return parser.parse_args()


def main() -> int:
    """Run the FORGE synchronisation workflow."""
    arguments = parse_arguments()

    print_header()

    if not validate_repository():
        return 1

    try:
        manifest = build_manifest()

        if arguments.check:
            result = check_manifest(
                manifest,
                CONFIG["paths"]["prototype"],
            )

            print_check_result(result)

            if has_manifest_drift(result):
                return 1

            return 0

        sync_result = synchronise_manifest(
            manifest,
            CONFIG["paths"]["prototype"],
        )
    except (OSError, RuntimeError, ValueError) as error:
        print()
        print("ERROR: Synchronisation workflow failed.")
        print()
        print(f"Reason: {error}")
        return 1

    print_result(sync_result)
    print_summary()

    return 0


def print_header() -> None:
    """Print the synchronisation-tool heading."""
    print("FORGE Synchronisation Tool")
    print()


def display_path(path: Path) -> str:
    """Return a repository-relative path when possible."""
    try:
        return str(path.relative_to(REPOSITORY_ROOT))
    except ValueError:
        return str(path)


def validate_repository() -> bool:
    """Validate that the required repository structure exists."""
    print("Validating repository...")
    print()

    missing_paths: list[Path] = []

    engine_root = CONFIG["paths"]["engine"]
    tests_root = CONFIG["paths"]["tests"]
    prototype_root = CONFIG["paths"]["prototype"]

    required_directories = {
        "engine": engine_root,
        "tests": tests_root,
        "forgeos": CONFIG["paths"]["forgeos"],
        "communications": CONFIG["paths"]["communications"],
        "prototype": prototype_root,
    }

    for path_name, path in required_directories.items():
        if path.is_dir():
            print(
                f"[OK] {path_name}: "
                f"{display_path(path)}"
            )
        else:
            print(
                f"[MISSING] {path_name}: "
                f"{display_path(path)}"
            )

            missing_paths.append(path)

    for relative_path in CONFIG["required_engine_files"]:
        file_path = engine_root / relative_path

        if file_path.is_file():
            print(
                f"[OK] engine/{relative_path}: "
                f"{display_path(file_path)}"
            )
        else:
            print(
                f"[MISSING] engine/{relative_path}: "
                f"{display_path(file_path)}"
            )

            missing_paths.append(file_path)

    print()

    if missing_paths:
        print("ERROR: Repository validation failed.")
        print()
        print("Missing required paths:")

        for path in missing_paths:
            print(f"  - {display_path(path)}")

        return False

    print("Repository validation successful.")

    return True


def is_excluded_path(
    path: Path,
    source_root: Path,
) -> bool:
    """Return whether a source path should be excluded."""
    relative_path = path.relative_to(source_root)

    excluded_directory_names = (
        CONFIG["excluded_directory_names"]
    )

    if any(
        part in excluded_directory_names
        for part in relative_path.parts[:-1]
    ):
        return True

    if path.name in CONFIG["excluded_file_names"]:
        return True

    if path.suffix.lower() in CONFIG["excluded_file_suffixes"]:
        return True

    return False


def collect_source_files(
    source_root: Path,
    destination_prefix: Path,
    included_file_suffixes: set[str] | None = None,
) -> dict[Path, Path]:
    """
    Collect recursively synchronised files from one source tree.

    Returned keys are destination-relative paths and returned values are
    authoritative source paths.
    """
    if not source_root.is_dir():
        raise FileNotFoundError(
            "Synchronisation source directory does not exist: "
            f"{display_path(source_root)}"
        )

    source_files: dict[Path, Path] = {}

    for source_path in source_root.rglob("*"):
        if not source_path.is_file():
            continue

        if included_file_suffixes is not None:
            if source_path.suffix.lower() not in included_file_suffixes:
                continue

        if is_excluded_path(
            source_path,
            source_root,
        ):
            continue

        source_relative_path = (
            source_path.relative_to(source_root)
        )

        destination_relative_path = (
            destination_prefix
            / source_relative_path
        )

        source_files[destination_relative_path] = (
            source_path
        )

    return source_files


def merge_manifest_entries(
    manifest: dict[Path, Path],
    entries: dict[Path, Path],
) -> None:
    """
    Merge source entries into the combined manifest.

    Raises an error if two authoritative source files target the same
    prototype-relative path.
    """
    for relative_path, source_path in entries.items():
        existing_source = manifest.get(relative_path)

        if existing_source is not None:
            raise RuntimeError(
                "Synchronisation source collision for "
                f"'{relative_path}': "
                f"'{display_path(existing_source)}' and "
                f"'{display_path(source_path)}'"
            )

        manifest[relative_path] = source_path


def build_manifest() -> dict[Path, Path]:
    """
    Build the complete prototype-file manifest.

    Engine files retain their paths relative to engine/.

    Test files are placed beneath tests/ in the prototype.

    ForgeOS Lua files and approved DDS presentation assets are placed beneath
    forgeos/ in the prototype.

    Communications Lua files are placed beneath communications/ in the
    prototype.
    """
    print()
    print("Building synchronisation manifest...")
    print()

    manifest: dict[Path, Path] = {}

    engine_entries = collect_source_files(
        CONFIG["paths"]["engine"],
        Path(),
    )

    test_entries = collect_source_files(
        CONFIG["paths"]["tests"],
        Path("tests"),
    )

    forgeos_entries = collect_source_files(
        CONFIG["paths"]["forgeos"],
        Path("forgeos"),
        included_file_suffixes={".lua", ".dds"},
    )

    communications_entries = collect_source_files(
        CONFIG["paths"]["communications"],
        Path("communications"),
        included_file_suffixes={".lua"},
    )

    merge_manifest_entries(
        manifest,
        engine_entries,
    )

    merge_manifest_entries(
        manifest,
        test_entries,
    )

    merge_manifest_entries(
        manifest,
        forgeos_entries,
    )

    merge_manifest_entries(
        manifest,
        communications_entries,
    )

    print(
        f"[MANIFEST] Engine: "
        f"{len(engine_entries)} files"
    )

    print(
        f"[MANIFEST] Tests: "
        f"{len(test_entries)} files"
    )

    print(
        f"[MANIFEST] ForgeOS: "
        f"{len(forgeos_entries)} files"
    )

    print(
        f"[MANIFEST] Communications: "
        f"{len(communications_entries)} files"
    )

    print(
        f"[MANIFEST] Total: "
        f"{len(manifest)} files"
    )

    return manifest


def collect_destination_files(
    destination_root: Path,
) -> dict[Path, Path]:
    """Collect all files currently present in the prototype tree."""
    if not destination_root.exists():
        return {}

    return {
        path.relative_to(destination_root): path
        for path in destination_root.rglob("*")
        if path.is_file()
    }


def files_are_identical(
    source_path: Path,
    destination_path: Path,
) -> bool:
    """Return whether two files contain identical data."""
    return (
        destination_path.is_file()
        and filecmp.cmp(
            source_path,
            destination_path,
            shallow=False,
        )
    )


def check_manifest(
    manifest: dict[Path, Path],
    destination_root: Path,
) -> dict[str, list[Path]]:
    """Inspect prototype drift without modifying the filesystem."""
    result: dict[str, list[Path]] = {
        "identical": [],
        "divergent": [],
        "missing": [],
        "stale": [],
        "collisions": [],
    }

    destination_files = collect_destination_files(
        destination_root
    )

    for relative_path in sorted(manifest):
        source_path = manifest[relative_path]
        destination_path = (
            destination_root
            / relative_path
        )

        if not destination_path.is_file():
            result["missing"].append(relative_path)
            continue

        if files_are_identical(
            source_path,
            destination_path,
        ):
            result["identical"].append(relative_path)
        else:
            result["divergent"].append(relative_path)

    result["stale"] = sorted(
        destination_files.keys()
        - manifest.keys()
    )

    return result


def has_manifest_drift(
    result: dict[str, list[Path]],
) -> bool:
    """Return whether a manifest check found any inconsistency."""
    return any(
        result[result_name]
        for result_name in (
            "divergent",
            "missing",
            "stale",
            "collisions",
        )
    )


def print_check_paths(
    heading: str,
    paths: list[Path],
) -> None:
    """Print one category of synchronization-check paths."""
    if not paths:
        return

    print()
    print(f"{heading}:")

    for path in paths:
        print(f"  - {path}")


def print_check_result(
    result: dict[str, list[Path]],
) -> None:
    """Print non-mutating synchronization-check results."""
    print()
    print("Checking prototype synchronization...")
    print()
    print(
        "[CHECK] "
        f"{len(result['identical'])} identical, "
        f"{len(result['divergent'])} divergent, "
        f"{len(result['missing'])} missing, "
        f"{len(result['stale'])} stale, "
        f"{len(result['collisions'])} collisions"
    )

    print_check_paths(
        "Divergent files",
        result["divergent"],
    )

    print_check_paths(
        "Missing files",
        result["missing"],
    )

    print_check_paths(
        "Stale files",
        result["stale"],
    )

    print_check_paths(
        "Destination collisions",
        result["collisions"],
    )


def remove_empty_directories(
    destination_root: Path,
) -> list[Path]:
    """Remove empty directories left after stale-file cleanup."""
    removed_directories: list[Path] = []

    if not destination_root.is_dir():
        return removed_directories

    directories = sorted(
        (
            path
            for path in destination_root.rglob("*")
            if path.is_dir()
        ),
        key=lambda path: len(path.parts),
        reverse=True,
    )

    for directory in directories:
        if any(directory.iterdir()):
            continue

        relative_path = (
            directory.relative_to(destination_root)
        )

        directory.rmdir()
        removed_directories.append(relative_path)

    return removed_directories


def synchronise_manifest(
    manifest: dict[Path, Path],
    destination_root: Path,
) -> dict[str, list[Path]]:
    """
    Mirror the combined manifest into the prototype destination.

    Files present in the controlled prototype tree but absent from the
    manifest are removed.
    """
    print()
    print("Synchronising prototype...")
    print()

    result: dict[str, list[Path]] = {
        "copied": [],
        "unchanged": [],
        "removed": [],
        "removed_directories": [],
    }

    destination_root.mkdir(
        parents=True,
        exist_ok=True,
    )

    destination_files = collect_destination_files(
        destination_root
    )

    for relative_path in sorted(manifest):
        source_path = manifest[relative_path]
        destination_path = (
            destination_root
            / relative_path
        )

        destination_path.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        if files_are_identical(
            source_path,
            destination_path,
        ):
            result["unchanged"].append(
                relative_path
            )

            continue

        shutil.copy2(
            source_path,
            destination_path,
        )

        result["copied"].append(
            relative_path
        )

    stale_paths = sorted(
        destination_files.keys()
        - manifest.keys()
    )

    for relative_path in stale_paths:
        destination_path = (
            destination_files[relative_path]
        )

        destination_path.unlink()

        result["removed"].append(
            relative_path
        )

    result["removed_directories"] = (
        remove_empty_directories(
            destination_root
        )
    )

    return result


def print_result(
    result: dict[str, list[Path]],
) -> None:
    """Print synchronisation counts and changed paths."""
    print(
        "[SYNC] prototype: "
        f"{len(result['copied'])} copied, "
        f"{len(result['unchanged'])} unchanged, "
        f"{len(result['removed'])} removed, "
        f"{len(result['removed_directories'])} "
        "empty directories removed"
    )

    if result["copied"]:
        print()
        print("Copied files:")

        for path in result["copied"]:
            print(f"  + {path}")

    if result["removed"]:
        print()
        print("Removed stale files:")

        for path in result["removed"]:
            print(f"  - {path}")

    if result["removed_directories"]:
        print()
        print("Removed empty directories:")

        for path in result["removed_directories"]:
            print(f"  - {path}")


def print_summary() -> None:
    """Print the final synchronisation summary."""
    print()
    print("=" * 60)
    print("FORGE synchronisation completed successfully.")
    print(f"Tool version: {CONFIG['version']}")
    print("=" * 60)


if __name__ == "__main__":
    raise SystemExit(main())
