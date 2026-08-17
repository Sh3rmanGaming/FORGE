"""Regression tests for FORGE runtime preflight tools."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile


TOOLS = Path(__file__).resolve().parent.parent


def load(name: str):
    spec = importlib.util.spec_from_file_location(name, TOOLS / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


check_test_order = load("check_test_order")
validate_runtime_package = load("validate_runtime_package")
sync_tool = load("sync")


class SynchronizationPreflightTests(unittest.TestCase):
    def test_forgeos_png_assets_are_synchronized(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Host.lua").write_text("-- host\n", encoding="utf-8")
            (root / "wallpaper.png").write_bytes(b"png")
            (root / "notes.txt").write_text("excluded\n", encoding="utf-8")
            files = sync_tool.collect_source_files(
                root,
                Path("forgeos"),
                included_file_suffixes=sync_tool.FORGEOS_FILE_SUFFIXES,
            )
            self.assertIn(Path("forgeos/Host.lua"), files)
            self.assertIn(Path("forgeos/wallpaper.png"), files)
            self.assertNotIn(Path("forgeos/notes.txt"), files)


class TestOrderPreflightTests(unittest.TestCase):
    def fixture(self, root: Path, invalid_order: bool) -> tuple[Path, Path]:
        tests = root / "tests"
        tests.mkdir()
        (tests / "Core.lua").write_text(
            "function FORGE.Tests.runForgeOSCoreTests()\n"
            "  FORGE.ForgeOS:start()\nend\n",
            encoding="utf-8",
        )
        (tests / "Integration.lua").write_text(
            "function FORGE.Tests.runIntegrationTests()\n"
            "  FORGE.ForgeOS:start()\nend\n",
            encoding="utf-8",
        )
        first = (
            'harness("Integration", FORGE.Tests.runIntegrationTests),\n'
            if invalid_order else
            'harness("Core", FORGE.Tests.runForgeOSCoreTests),\n'
        )
        later = (
            'harness("Core", FORGE.Tests.runForgeOSCoreTests),\n'
            if invalid_order else
            'harness("Integration", FORGE.Tests.runIntegrationTests),\n'
        )
        engine = root / "Engine.lua"
        engine.write_text(
            "-- TEST PHASE: PROCESS_INITIAL\n" + first
            + "-- TEST PHASE: FOUNDATION\n"
            + "-- TEST PHASE: LIFECYCLE_MUTATING\n" + later
            + "-- TEST PHASE: END_TO_END\n",
            encoding="utf-8",
        )
        return engine, tests

    def test_valid_process_initial_order_passes(self):
        with tempfile.TemporaryDirectory() as directory:
            engine, tests = self.fixture(Path(directory), False)
            self.assertEqual(check_test_order.validate(engine, tests), [])

    def test_m3005_revision_one_order_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            engine, tests = self.fixture(Path(directory), True)
            errors = check_test_order.validate(engine, tests)
            self.assertTrue(any("first ForgeOS" in error for error in errors))


class RuntimePackagePreflightTests(unittest.TestCase):
    def fixture(self, root: Path) -> Path:
        prototype = root / "prototype"
        source = prototype / "scripts" / "forge"
        source.mkdir(parents=True)
        (source / "Engine.lua").write_text("-- engine\n", encoding="utf-8")
        (prototype / "modDesc.xml").write_text(
            "<modDesc><extraSourceFiles>"
            '<sourceFile filename="scripts/forge/Engine.lua"/>'
            "</extraSourceFiles></modDesc>",
            encoding="utf-8",
        )
        return prototype

    def test_operational_manifest_and_archive_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            prototype = self.fixture(root)
            archive = root / "package.zip"
            with zipfile.ZipFile(archive, "w") as package:
                for path in prototype.rglob("*"):
                    if path.is_file():
                        package.write(path, path.relative_to(prototype).as_posix())
            self.assertEqual(
                validate_runtime_package.validate(prototype, archive, 0), []
            )

    def test_backslash_archive_entry_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            prototype = self.fixture(root)
            archive = root / "package.zip"
            with zipfile.ZipFile(archive, "w") as package:
                package.writestr("modDesc.xml", (prototype / "modDesc.xml").read_bytes())
                package.writestr("scripts/forge/Engine.lua", "-- engine\n")
                package.writestr("bad/path.lua", "-- malformed path\n")
            archive.write_bytes(
                archive.read_bytes().replace(
                    b"bad/path.lua",
                    b"bad\\path.lua",
                )
            )
            errors = validate_runtime_package.validate(prototype, archive, 0)
            self.assertTrue(any("backslash ZIP" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
