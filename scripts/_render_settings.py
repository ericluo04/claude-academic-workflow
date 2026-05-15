#!/usr/bin/env python3
"""Render settings.example.json / settings.local.example.json to ~/.claude/.

Strips internal `_comments` and `_personalized_examples` keys (they are
documentation hints in the template, not real config), then substitutes
${HOME} with the real home path. Both install.sh and install.ps1 call this.

Usage:
    python _render_settings.py <src.json> <dst.json>
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def strip_meta(obj):
    """Recursively remove `_comments` and `_personalized_examples` keys."""
    if isinstance(obj, dict):
        return {
            k: strip_meta(v)
            for k, v in obj.items()
            if k not in ("_comments", "_personalized_examples")
        }
    if isinstance(obj, list):
        return [strip_meta(x) for x in obj]
    if isinstance(obj, str):
        return obj.replace("${HOME}", str(Path.home()).replace("\\", "/"))
    return obj


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <src> <dst>", file=sys.stderr)
        return 2
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    if not src.is_file():
        print(f"Source not found: {src}", file=sys.stderr)
        return 3
    try:
        data = json.loads(src.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in {src}: {e}", file=sys.stderr)
        return 4
    cleaned = strip_meta(data)
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(json.dumps(cleaned, indent=2) + "\n", encoding="utf-8")
    print(f"Rendered {src.name} -> {dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
