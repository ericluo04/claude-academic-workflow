#!/usr/bin/env python3
"""
redact-check.py -- Pre-push secrets gate for the claude-academic-workflow repo.

Scans every text file under a directory (default: cwd) for known secret
patterns and Lan-specific values that must never ship public. Exits 0 if
clean, 1 if anything matches.

Usage:
    python scripts/redact-check.py [PATH] [--allowlist FILE] [--no-color]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# ---------- Regex patterns (high-entropy / structural) ----------
PATTERNS: dict[str, str] = {
    "Anthropic API token": r"sk-ant-(?:oat01|ort01|api)-[A-Za-z0-9_-]{20,}",
    "Notion API token (legacy)": r"\bsecret_[A-Za-z0-9]{40,}\b",
    "Notion API token (ntn)": r"\bntn_[A-Za-z0-9]{40,}\b",
    "Notion OAuth token shape": r"\b[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}:[A-Za-z0-9_]{16}:[A-Za-z0-9_]{32}\b",
    "Telegram bot token": r"\b\d{9,10}:[A-Za-z0-9_-]{35}\b",
    "GitHub PAT (classic)": r"\bghp_[A-Za-z0-9]{36}\b",
    "GitHub PAT (fine-grained)": r"\bgithub_pat_[A-Za-z0-9_]{82}\b",
    "OpenAI API key": r"\bsk-[A-Za-z0-9]{48}\b",
    "AWS access key ID": r"\bAKIA[0-9A-Z]{16}\b",
    "Generic 40-char API key": r"\b(?i:api[-_ ]?key|token|secret)\s*[:=]\s*['\"]?[A-Za-z0-9_-]{40,}['\"]?",
}

# ---------- Personal exact-string blocklist ----------
# The blocklist itself is loaded at runtime from `scripts/.blocklist.json`,
# which is gitignored. See `scripts/.blocklist.example.json` for the schema
# and the README in scripts/ for setup. If the file is missing, the scanner
# falls back to generic regex patterns only (still catches Anthropic / Notion /
# Telegram tokens by shape) but loses the exact-match defense-in-depth.
#
# This design keeps the user's specific values (chat IDs, page UUIDs, emails)
# off of GitHub, even though the script that scans for them must ship publicly.

import json as _json


def load_personal_blocklist(script_dir: Path) -> dict[str, str]:
    bl = script_dir / ".blocklist.json"
    if not bl.is_file():
        return {}
    try:
        data = _json.loads(bl.read_text(encoding="utf-8"))
        # Drop `_documentation` and any underscore-prefixed metadata keys.
        return {
            k: v
            for k, v in data.items()
            if not k.startswith("_") and isinstance(v, str)
        }
    except (OSError, _json.JSONDecodeError) as e:
        print(f"WARN: could not load {bl}: {e}", file=sys.stderr)
        return {}


SKIP_DIRS = {
    ".git",
    "node_modules",
    "__pycache__",
    ".venv",
    "venv",
    "_archive",
    ".mypy_cache",
    ".pytest_cache",
}
SKIP_SUFFIXES = {
    ".pyc",
    ".pyo",
    ".so",
    ".dll",
    ".exe",
    ".bin",
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".pdf",
    ".zip",
    ".gz",
    ".tar",
    ".woff",
    ".woff2",
    ".ttf",
    ".ico",
    ".mp4",
    ".mp3",
}

# Anything that contains a regex pattern STRING (e.g. this file) self-allowlists.
# Personal-blocklist self-allowlisting is handled at runtime in main() after the
# blocklist is loaded.
INTERNAL_ALLOWLIST_TOKENS_REGEX_ONLY: set[str] = set(PATTERNS.values())


def is_text_file(path: Path, sample: int = 2048) -> bool:
    if path.suffix.lower() in SKIP_SUFFIXES:
        return False
    try:
        with path.open("rb") as f:
            chunk = f.read(sample)
        if b"\x00" in chunk:
            return False
        chunk.decode("utf-8")
        return True
    except (UnicodeDecodeError, OSError):
        return False


def iter_files(root: Path):
    for p in root.rglob("*"):
        if not p.is_file():
            continue
        if any(part in SKIP_DIRS for part in p.parts):
            continue
        if is_text_file(p):
            yield p


def redact(snippet: str, head: int = 10) -> str:
    s = snippet.strip()
    return (s[:head] + "***") if len(s) > head else s + "***"


def load_allowlist(path: Path | None) -> set[str]:
    if not path:
        return set()
    if not path.exists():
        print(f"WARN: allowlist {path} not found", file=sys.stderr)
        return set()
    return {
        ln.strip()
        for ln in path.read_text("utf-8").splitlines()
        if ln.strip() and not ln.startswith("#")
    }


def scan_file(
    path: Path, compiled_patterns, exact_terms, allowlist, internal_allowlist
) -> list[tuple[str, int, str, str]]:
    hits = []
    try:
        text = path.read_text("utf-8", errors="replace")
    except OSError:
        return hits
    # Always skip the blocklist file itself and this script's own pattern definitions.
    is_blocklist_file = path.name in (".blocklist.json", ".blocklist.example.json")
    if is_blocklist_file:
        return hits
    for i, line in enumerate(text.splitlines(), 1):
        # Skip lines that are literally one of our regex strings (self-match safety)
        if any(
            tok in line
            for tok in internal_allowlist
            if tok and len(tok) > 6 and tok == line.strip().strip("'\"`,")
        ):
            continue
        # Regex patterns
        for name, rx in compiled_patterns:
            for m in rx.finditer(line):
                snip = m.group(0)
                if snip in allowlist or snip in internal_allowlist:
                    continue
                hits.append((str(path), i, name, redact(snip)))
        # Exact-string blocklist
        for name, term in exact_terms:
            if term in line:
                if term in allowlist:
                    continue
                hits.append((str(path), i, name, redact(term)))
    return hits


def color(s: str, code: str, enabled: bool) -> str:
    return f"\033[{code}m{s}\033[0m" if enabled else s


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Scan repo for leaked secrets before public push."
    )
    ap.add_argument(
        "path", nargs="?", default=".", help="Root path to scan (default: cwd)"
    )
    ap.add_argument(
        "--allowlist",
        type=Path,
        default=None,
        help="Path to allowlist.txt of known-safe strings",
    )
    ap.add_argument(
        "--no-color", action="store_true", help="Plain output (no ANSI codes)"
    )
    args = ap.parse_args()

    root = Path(args.path).resolve()
    if not root.exists():
        print(f"ERROR: {root} does not exist", file=sys.stderr)
        return 2

    use_color = sys.stdout.isatty() and not args.no_color
    allowlist = load_allowlist(args.allowlist)

    # Load personal blocklist from gitignored scripts/.blocklist.json
    script_dir = Path(__file__).resolve().parent
    personal_blocklist = load_personal_blocklist(script_dir)
    internal_allowlist = INTERNAL_ALLOWLIST_TOKENS_REGEX_ONLY | set(personal_blocklist.values())

    compiled = [(name, re.compile(rx)) for name, rx in PATTERNS.items()]
    exact = list(personal_blocklist.items())

    print(color(f"=== redact-check scanning {root} ===", "35", use_color))
    print(f"  patterns       : {len(compiled)}")
    print(f"  exact strings  : {len(exact)} (from .blocklist.json)")
    print(f"  allowlist size : {len(allowlist)}")
    if not exact:
        print(
            color(
                "  WARN: no .blocklist.json found; running with generic regex patterns only.",
                "33",
                use_color,
            )
        )
        print(
            "        Copy scripts/.blocklist.example.json to scripts/.blocklist.json and fill in"
        )
        print("        your project-specific UUIDs / chat IDs / emails for full coverage.")

    all_hits = []
    files_scanned = 0
    for f in iter_files(root):
        files_scanned += 1
        all_hits.extend(
            scan_file(f, compiled, exact, allowlist, internal_allowlist)
        )

    print(f"  files scanned  : {files_scanned}")
    print()

    if not all_hits:
        print(color("[ok] No secrets found. Safe to push.", "32", use_color))
        return 0

    for fp, ln, rule, snip in all_hits:
        try:
            rel = Path(fp).relative_to(root)
        except ValueError:
            rel = Path(fp)
        msg = f"{rel}:{ln}: [{rule}] {snip}"
        print(color("[XX] " + msg, "31", use_color))

    print()
    print(
        color(
            f"[XX] {len(all_hits)} match(es) across {files_scanned} files. DO NOT PUSH.",
            "31",
            use_color,
        )
    )
    print(
        color(
            "     Fix the leaks, or add to --allowlist if intentional.", "31", use_color
        )
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
