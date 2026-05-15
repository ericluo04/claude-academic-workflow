#!/usr/bin/env python3
# Author: Lan Luo (https://github.com/ericluo04)
"""
Post-Tool-Use Auto-Formatter Hook

Fires after Edit / Write / MultiEdit on a file. Auto-formats:
  - .py        → `ruff format <file>`
  - .R / .r    → `Rscript -e "styler::style_file('<file>')"`
  - anything else → no-op

Design constraints:
  - Never block edits: always exit 0, even when the formatter errors or
    is missing.
  - Silent on success (no stdout / stderr) so the hook stays out of the
    way during normal editing.
  - Failures append a timestamped line to
    `~/.claude/state/formatter.log` so issues are debuggable after the
    fact.
  - 10-sec subprocess timeout per file — formatters should be fast, and
    we'd rather skip than hang the harness.
  - Tool detection via `shutil.which`: if the binary isn't on PATH we
    skip silently (no log spam — this is the expected state on machines
    without R or ruff installed).

Hook Event: PostToolUse (matcher: Edit|Write|MultiEdit)
Input contract: hook receives JSON on stdin with shape
`{"tool_name": "...", "tool_input": {"file_path": "..."}, "tool_response": {...}}`.
We read `tool_input.file_path`, falling back to `tool_response.filePath`.
Returns: exit 0 always.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

LOG_PATH = Path.home() / ".claude" / "state" / "formatter.log"
SUBPROCESS_TIMEOUT_SEC = 10


def log_failure(file_path: str, message: str) -> None:
    """Append a timestamped failure note. Never raises."""
    try:
        LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().isoformat(timespec="seconds")
        with open(LOG_PATH, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {file_path}: {message}\n")
    except OSError:
        # Even logging is best-effort — never propagate.
        pass


def read_file_paths_from_stdin() -> list[str]:
    """Parse the PostToolUse JSON payload and pull out edited file paths.

    Edit / Write / MultiEdit all carry a single `file_path` in
    `tool_input`. `tool_response.filePath` is the same value echoed by
    the harness — we fall back to it in case `tool_input` is missing.
    """
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return []
    paths: list[str] = []
    tool_input = payload.get("tool_input") or {}
    tool_response = payload.get("tool_response") or {}
    for candidate in (tool_input.get("file_path"), tool_response.get("filePath")):
        if candidate and candidate not in paths:
            paths.append(candidate)
    return paths


def format_python(file_path: str) -> None:
    """Run `ruff format` on a Python file. Silent on success."""
    if shutil.which("ruff") is None:
        # Expected on machines without ruff — don't log.
        return
    try:
        result = subprocess.run(
            ["ruff", "format", file_path],
            capture_output=True,
            text=True,
            timeout=SUBPROCESS_TIMEOUT_SEC,
        )
        if result.returncode != 0:
            log_failure(
                file_path,
                f"ruff format exit {result.returncode}: "
                f"{(result.stderr or result.stdout or '').strip()[:300]}",
            )
    except subprocess.TimeoutExpired:
        log_failure(file_path, f"ruff format timed out after {SUBPROCESS_TIMEOUT_SEC}s")
    except OSError as e:
        log_failure(file_path, f"ruff format OSError: {e}")


def format_r(file_path: str) -> None:
    """Run `styler::style_file()` on an R file. Silent on success."""
    if shutil.which("Rscript") is None:
        return
    # styler expects forward slashes or escaped backslashes inside the R
    # string. Forward slashes work cross-platform and avoid quoting
    # gymnastics on Windows.
    r_path = file_path.replace("\\", "/")
    r_expr = f"suppressMessages(styler::style_file('{r_path}'))"
    try:
        result = subprocess.run(
            ["Rscript", "-e", r_expr],
            capture_output=True,
            text=True,
            timeout=SUBPROCESS_TIMEOUT_SEC,
        )
        if result.returncode != 0:
            stderr = (result.stderr or "").strip()
            # styler missing → silent skip (not a real failure).
            if "there is no package called" in stderr and "styler" in stderr:
                return
            log_failure(
                file_path,
                f"Rscript styler exit {result.returncode}: "
                f"{(stderr or result.stdout or '').strip()[:300]}",
            )
    except subprocess.TimeoutExpired:
        log_failure(
            file_path, f"Rscript styler timed out after {SUBPROCESS_TIMEOUT_SEC}s"
        )
    except OSError as e:
        log_failure(file_path, f"Rscript styler OSError: {e}")


def format_one(file_path: str) -> None:
    """Dispatch a single file to the right formatter by extension."""
    # Skip if the file doesn't exist (e.g. a delete that was misreported
    # as Write). Formatters would error anyway; this keeps the log
    # clean.
    if not os.path.isfile(file_path):
        return
    ext = os.path.splitext(file_path)[1].lower()
    if ext == ".py":
        format_python(file_path)
    elif ext in (".r",):
        format_r(file_path)
    # else: no-op (e.g. .tex, .md, .json — caller didn't ask us to
    # touch those).


def main() -> int:
    for path in read_file_paths_from_stdin():
        try:
            format_one(path)
        except Exception as e:  # noqa: BLE001 — fail-open guard
            log_failure(path, f"unexpected error: {e!r}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        # Never block edits on a hook bug.
        sys.exit(0)
