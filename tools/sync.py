"""
=============================================================================
FORGE Synchronisation Tool
=============================================================================

Purpose:
    Synchronises the authoritative FORGE engine source into the prototype
    reference implementation.

Responsibilities:
    • Validate repository structure.
    • Synchronise engine files.
    • Synchronise test files.
    • Report synchronisation results.

Design Principles:
    • The repository is the source of truth.
    • Synchronisation is repeatable and idempotent.
    • Fail early with clear diagnostics.
    • Never modify the authoritative engine source.

This tool is part of the FORGE developer toolchain.
=============================================================================
"""

from pathlib import Path
import filecmp
import shutil

CONFIG = {
    "version": "0.1.0-dev",

    "paths": {
        "engine": Path("engine"),
        "tests": Path("tests"),
        "prototype": Path(
            "prototype/FS25_FORGE_Engine/scripts/forge"
        ),
    },

    "engine_directories": (
        "definitions",
        "services",
        "managers",
        "utilities",
    ),

    "engine_root_files": (
        "FORGE.lua",
        "Engine.lua",
    ),
}


def main() -> int:
    """Run the FORGE synchronisation workflow."""
    if not validate():
        return 1

    try:
        sync_engine()
        sync_tests()
    except (OSError, ValueError) as error:
        print()
        print("ERROR: Synchronisation failed.")
        print()
        print(f"Reason: {error}")
        return 1

    print_summary()
    return 0


def validate() -> bool:
    """Validate that all required repository directories exist."""
    print("FORGE Synchronisation Tool")
    print()
    print("Validating repository...")
    print()

    missing_paths: list[Path] = []

    for path_name, path in CONFIG["paths"].items():
        if path.is_dir():
            print(f"[OK] {path_name}: {path}")
        else:
            print(f"[MISSING] {path_name}: {path}")
            missing_paths.append(path)

    print()


    engine_root = CONFIG["paths"]["engine"]

    for directory_name in CONFIG["engine_directories"]:
        directory_path = engine_root / directory_name
        path_name = f"engine/{directory_name}"

        if directory_path.is_dir():
            print(f"[OK] {path_name}: {directory_path}")
        else:
            print(f"[MISSING] {path_name}: {directory_path}")
            missing_paths.append(directory_path)

    for file_name in CONFIG["engine_root_files"]:
        file_path = engine_root / file_name
        path_name = f"engine/{file_name}"

        if file_path.is_file():
            print(f"[OK] {path_name}: {file_path}")
        else:
            print(f"[MISSING] {path_name}: {file_path}")
            missing_paths.append(file_path)


    if missing_paths:
        print("ERROR: Repository validation failed.")
        print()
        print("Missing required directories:")

        for path in missing_paths:
            print(f"  - {path}")

        return False

    print("Repository validation successful.")
    return True


def sync_directory(
    source_directory: Path,
    destination_directory: Path,
) -> dict[str, list[Path]]:
    """
    Mirror one source directory into one controlled destination directory.

    Returns lists of copied, skipped and removed paths for reporting.
    """
    if not source_directory.is_dir():
        raise FileNotFoundError(
            f"Synchronisation source directory does not exist: "
            f"{source_directory}"
        )

    result: dict[str, list[Path]] = {
        "copied": [],
        "skipped": [],
        "removed": [],
    }

    destination_directory.mkdir(parents=True, exist_ok=True)

    source_files = {
        path.relative_to(source_directory): path
        for path in source_directory.rglob("*")
        if path.is_file()
    }

    destination_files = {
        path.relative_to(destination_directory): path
        for path in destination_directory.rglob("*")
        if path.is_file()
    }

    for relative_path, source_path in source_files.items():
        destination_path = destination_directory / relative_path
        destination_path.parent.mkdir(parents=True, exist_ok=True)

        if (
            destination_path.is_file()
            and filecmp.cmp(
                source_path,
                destination_path,
                shallow=False,
            )
        ):
            result["skipped"].append(relative_path)
            continue

        shutil.copy2(source_path, destination_path)
        result["copied"].append(relative_path)

    stale_paths = destination_files.keys() - source_files.keys()

    for relative_path in sorted(stale_paths):
        destination_files[relative_path].unlink()
        result["removed"].append(relative_path)

    for directory in sorted(
        destination_directory.rglob("*"),
        reverse=True,
    ):
        if directory.is_dir() and not any(directory.iterdir()):
            directory.rmdir()

    return result


def sync_file(
    source_file: Path,
    destination_file: Path,
) -> str:
    """
    Synchronise one controlled source file into its destination.

    Returns copied or skipped for reporting.
    """
    if not source_file.is_file():
        raise FileNotFoundError(
            f"Synchronisation source file does not exist: "
            f"{source_file}"
        )

    destination_file.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    if (
        destination_file.is_file()
        and filecmp.cmp(
            source_file,
            destination_file,
            shallow=False,
        )
    ):
        return "skipped"

    shutil.copy2(source_file, destination_file)
    return "copied"


def sync_engine() -> None:
    """Synchronise authoritative engine files into the prototype."""
    engine_root = CONFIG["paths"]["engine"]
    prototype_root = CONFIG["paths"]["prototype"]

    print()
    print("Synchronising engine...")
    print()

    for directory_name in CONFIG["engine_directories"]:
        source_directory = engine_root / directory_name
        destination_directory = prototype_root / directory_name

        result = sync_directory(
            source_directory,
            destination_directory,
        )

        print(
            f"[SYNC] {directory_name}: "
            f"{len(result['copied'])} copied, "
            f"{len(result['skipped'])} unchanged, "
            f"{len(result['removed'])} removed"
        )

    for file_name in CONFIG["engine_root_files"]:
        source_file = engine_root / file_name
        destination_file = prototype_root / file_name

        result = sync_file(
            source_file,
            destination_file,
        )

        print(f"[{result.upper()}] {file_name}")


def sync_tests() -> None:
    """Synchronise test files into the prototype."""
    tests_root = CONFIG["paths"]["tests"]
    prototype_tests = CONFIG["paths"]["prototype"] / "tests"

    print()
    print("Synchronising tests...")
    print()

    result = sync_directory(
        tests_root,
        prototype_tests,
    )

    print(
        f"[SYNC] tests: "
        f"{len(result['copied'])} copied, "
        f"{len(result['skipped'])} unchanged, "
        f"{len(result['removed'])} removed"
    )


def print_summary() -> None:
    """Print the final synchronisation summary."""
    print()
    print("=" * 60)
    print("FORGE synchronisation completed successfully.")
    print(f"Tool version: {CONFIG['version']}")
    print("=" * 60)


if __name__ == "__main__":
    raise SystemExit(main())