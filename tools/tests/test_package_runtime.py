"""Regression tests for the FORGE runtime package tool."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile


TOOLS = Path(__file__).resolve().parent.parent


def load(name: str):
    spec = importlib.util.spec_from_file_location(name, TOOLS / f"{name}.py")
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


package_runtime = load("package_runtime")
validate_runtime_package = load("validate_runtime_package")


class PackageRuntimeTests(unittest.TestCase):
    def test_verification_staging_adds_one_bootstrap_after_logger(self):
        before = (package_runtime.PROTOTYPE / "modDesc.xml").read_bytes()
        with tempfile.TemporaryDirectory() as directory:
            staged = package_runtime.stage("verification", Path(directory))
            declared = validate_runtime_package.declared_sources(
                (staged / "modDesc.xml").read_bytes())
            self.assertEqual(declared.count(package_runtime.BOOTSTRAP), 1)
            self.assertEqual(
                declared.index(package_runtime.BOOTSTRAP),
                declared.index(package_runtime.LOGGER) + 1)
            self.assertEqual(declared[-1], validate_runtime_package.ENGINE)
        self.assertEqual(
            (package_runtime.PROTOTYPE / "modDesc.xml").read_bytes(), before)

    def test_operational_staging_has_no_bootstrap(self):
        with tempfile.TemporaryDirectory() as directory:
            staged = package_runtime.stage("operational", Path(directory))
            declared = validate_runtime_package.declared_sources(
                (staged / "modDesc.xml").read_bytes())
            self.assertEqual(declared.count(package_runtime.BOOTSTRAP), 0)

    def test_archive_is_posix_deterministic_and_valid(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            staged = package_runtime.stage("operational", root)
            first, second = root / "a.zip", root / "b.zip"
            package_runtime.build_archive(staged, first)
            package_runtime.build_archive(staged, second)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            names = zipfile.ZipFile(first).namelist()
            self.assertEqual(names[0], "modDesc.xml")
            self.assertFalse([name for name in names if "\\" in name])
            self.assertEqual(
                validate_runtime_package.validate(staged, first, 0), [])


if __name__ == "__main__":
    unittest.main()
