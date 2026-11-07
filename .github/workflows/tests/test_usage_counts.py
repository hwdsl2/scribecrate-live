#!/usr/bin/env python3
"""Offline regression checks for the usage reporter in run.sh."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
BASH = shutil.which("bash")


def reporter_functions(source: str) -> str:
    """Load the actual helpers without executing container startup code."""
    functions = []
    for name in ("usage_arch", "write_usage_state", "read_state_value", "report_usage_counts"):
        match = re.search(rf"(?ms)^{name}\(\) \{{\n.*?^\}}[ \t]*$", source)
        if match is None:
            raise AssertionError(f"Cannot find run.sh function: {name}")
        functions.append(match.group())
    if not re.search(r"^report_usage_counts[ \t]*$", source, re.MULTILINE):
        raise AssertionError("run.sh no longer invokes the usage reporter")
    return "\n\n".join(functions)


class UsageCountsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if BASH is None:
            raise AssertionError("Bash is required for the usage reporter checks")
        cls.functions = reporter_functions((ROOT / "run.sh").read_text(encoding="utf-8"))

    def report(self, *, architecture="x86_64", flavor="latest", previous=None,
               existing=False, mounted=True, opt_out=None, deliveries=(0,)):
        with tempfile.TemporaryDirectory(prefix="whisperlive-usage-test-") as directory:
            root = Path(directory)
            state_dir = root / "state"
            state = state_dir / "whisperlive.version"
            events = root / "events"
            network = root / "unexpected-network"
            if previous is not None:
                state_dir.mkdir()
                state.write_text(previous + "\n", encoding="utf-8")
            # Deliberately omit inherited opt-outs, credentials, BASH_ENV, and build variables.
            env = {"PATH": os.defpath, "LC_ALL": "C", "USAGE_STATE_DIR": str(state_dir),
                   "TEST_EVENTS": str(events), "TEST_NETWORK": str(network),
                   "TEST_ARCH": architecture, "IMAGE_FLAVOR": flavor, "IMAGE_VER": "new"}
            if opt_out is not None:
                env["WHISPERLIVE_DISABLE_USAGE_COUNTS"] = opt_out
            program = r'''
set -euo pipefail
uname() { printf '%s\n' "$TEST_ARCH"; }
fetch_usage_asset() {
  printf '%s\n' "$1" >> "$TEST_EVENTS"
  return "$TEST_FETCH_STATUS"
}
# Guard against accidentally introducing an unmocked transport in the reporter.
curl() { printf 'curl\n' >> "$TEST_NETWORK"; return 99; }
wget() { printf 'wget\n' >> "$TEST_NETWORK"; return 99; }
'''
            program += self.functions
            program += f"\ndata_existing={'true' if existing else 'false'}\n"
            program += f"data_mounted={'true' if mounted else 'false'}\n"
            for status in deliveries:
                program += f"TEST_FETCH_STATUS={status}\nreport_usage_counts\n"
            result = subprocess.run([BASH, "--noprofile", "--norc", "-c", program], cwd=root, env=env,
                                    capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(network.exists(), "Reporter attempted an unmocked network command")
            self.assertEqual(list(state_dir.glob(".usage.*")), [], "Temporary state files were left behind")
            self.assertEqual(result.stdout, "")
            emitted = events.read_text(encoding="utf-8").splitlines() if events.exists() else []
            saved = state.read_text(encoding="utf-8").strip() if state.exists() else None
            return emitted, saved

    def test_fresh_cpu_amd64_reports_deploy_and_persists_version(self) -> None:
        for architecture in ("x86_64", "amd64"):
            with self.subTest(architecture=architecture):
                self.assertEqual(self.report(architecture=architecture, deliveries=(0, 0)),
                                 (["cu-v1-whisperlive-deploy-cpu-amd64"], "latest-new"))

    def test_fresh_cpu_arm64_reports_deploy(self) -> None:
        for architecture in ("aarch64", "arm64"):
            with self.subTest(architecture=architecture):
                self.assertEqual(self.report(architecture=architecture),
                                 (["cu-v1-whisperlive-deploy-cpu-arm64"], "latest-new"))

    def test_fresh_cuda_reports_deploy(self) -> None:
        self.assertEqual(self.report(flavor="cuda"), (["cu-v1-whisperlive-deploy-cuda-amd64"], "cuda-new"))

    def test_existing_data_first_report_is_upgrade(self) -> None:
        self.assertEqual(self.report(existing=True), (["cu-v1-whisperlive-upgrade-cpu-amd64"], "latest-new"))

    def test_changed_build_reports_upgrade_and_only_success_advances_state(self) -> None:
        asset = "cu-v1-whisperlive-upgrade-cpu-amd64"
        for deliveries, expected_events, expected_state in (
                ((0,), [asset], "latest-new"), ((1,), [asset], "latest-old"),
                ((1, 0, 0), [asset, asset], "latest-new")):
            with self.subTest(deliveries=deliveries):
                self.assertEqual(self.report(previous="latest-old", existing=True, deliveries=deliveries),
                                 (expected_events, expected_state))

    def test_same_build_restart_does_not_report(self) -> None:
        self.assertEqual(self.report(previous="latest-new", existing=True), ([], "latest-new"))

    def test_explicit_opt_out_preserves_state_without_reporting(self) -> None:
        for previous in (None, "latest-old"):
            with self.subTest(previous=previous):
                self.assertEqual(self.report(previous=previous, opt_out="1"), ([], previous))

    def test_missing_data_mount_preserves_state_without_reporting(self) -> None:
        for previous in (None, "latest-old"):
            with self.subTest(previous=previous):
                self.assertEqual(self.report(previous=previous, mounted=False), ([], previous))


if __name__ == "__main__":
    unittest.main()
