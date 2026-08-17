"""Validate the FORGE prototype manifest and optional runtime ZIP package."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path, PurePosixPath
import struct
import sys
import xml.etree.ElementTree as ET
import zipfile


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_PROTOTYPE = REPOSITORY_ROOT / "prototype" / "FS25_FORGE_Engine"
BOOTSTRAP = "scripts/forge/tests/DevelopmentTestBootstrap.lua"
ENGINE = "scripts/forge/Engine.lua"


def raw_entry_names(archive: Path) -> list[str]:
    """Read entry names without Windows path normalization."""
    data = archive.read_bytes()
    names: list[str] = []
    offset = 0
    signature = b"PK\x03\x04"
    while offset + 30 <= len(data) and data[offset:offset + 4] == signature:
        values = struct.unpack_from("<IHHHHHIIIHH", data, offset)
        compressed_size = values[7]
        name_length = values[9]
        extra_length = values[10]
        name_start = offset + 30
        name_end = name_start + name_length
        names.append(data[name_start:name_end].decode("utf-8"))
        offset = name_end + extra_length + compressed_size
    return names


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate FORGE runtime manifest and ZIP identity."
    )
    parser.add_argument("--prototype", type=Path, default=DEFAULT_PROTOTYPE)
    parser.add_argument("--archive", type=Path)
    parser.add_argument(
        "--expect-bootstrap", type=int, choices=(0, 1), required=True
    )
    return parser.parse_args()


def declared_sources(mod_desc: bytes) -> list[str]:
    root = ET.fromstring(mod_desc)
    container = root.find("extraSourceFiles")
    if container is None:
        return []
    return [
        node.attrib.get("filename", "")
        for node in container.findall("sourceFile")
    ]


def validate(
    prototype: Path, archive: Path | None, expected_bootstrap: int
) -> list[str]:
    errors: list[str] = []
    mod_desc_path = prototype / "modDesc.xml"
    mod_desc = mod_desc_path.read_bytes()
    declared = declared_sources(mod_desc)
    counts = Counter(declared)
    duplicates = sorted(name for name, count in counts.items() if count > 1)
    missing = sorted(name for name in declared if not (prototype / name).is_file())
    if duplicates:
        errors.append("duplicate declared sources: " + ", ".join(duplicates))
    if missing:
        errors.append("missing declared sources: " + ", ".join(missing))
    if not declared or declared[-1] != ENGINE:
        errors.append(f"{ENGINE} must be the final declared source")
    bootstrap_count = counts[BOOTSTRAP]
    if bootstrap_count != expected_bootstrap:
        errors.append(
            f"expected {expected_bootstrap} bootstrap entries, "
            f"found {bootstrap_count}"
        )

    if archive is not None:
        raw_names = raw_entry_names(archive)
        with zipfile.ZipFile(archive) as package:
            names = package.namelist()
            if len(raw_names) != len(names):
                errors.append(
                    "raw ZIP filename audit did not enumerate every entry"
                )
            name_counts = Counter(names)
            zip_duplicates = sorted(
                name for name, count in name_counts.items() if count > 1
            )
            backslashes = sorted(name for name in raw_names if "\\" in name)
            if zip_duplicates:
                errors.append(
                    "duplicate ZIP entries: " + ", ".join(zip_duplicates)
                )
            if backslashes:
                errors.append(
                    "backslash ZIP entries: " + ", ".join(backslashes)
                )
            if "modDesc.xml" not in name_counts:
                errors.append("modDesc.xml is absent from ZIP root")
            else:
                packaged_declared = declared_sources(package.read("modDesc.xml"))
                if packaged_declared != declared:
                    errors.append("packaged modDesc.xml differs from prototype")
            for source in declared:
                if name_counts[source] != 1:
                    errors.append(
                        f"declared ZIP source {source} appears "
                        f"{name_counts[source]} times"
                    )
            prototype_files = {
                PurePosixPath(path.relative_to(prototype)).as_posix()
                for path in prototype.rglob("*") if path.is_file()
            }
            unexpected = sorted(set(names) - prototype_files)
            absent = sorted(prototype_files - set(names))
            if unexpected:
                errors.append("unexpected ZIP entries: " + ", ".join(unexpected))
            if absent:
                errors.append("prototype files absent from ZIP: " + ", ".join(absent))
    return errors


def main() -> int:
    arguments = parse_arguments()
    errors = validate(
        arguments.prototype.resolve(),
        arguments.archive.resolve() if arguments.archive else None,
        arguments.expect_bootstrap,
    )
    if errors:
        print("FORGE runtime-package preflight failed:")
        for error in errors:
            print(f"  - {error}")
        return 1
    print("FORGE runtime-package preflight passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
