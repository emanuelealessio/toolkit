#!/usr/bin/env python3
"""Deep-merge a settings fragment into ~/.claude/settings.json.

Rules:
- Dicts merged recursively.
- Lists unioned (no duplicates, preserves order: existing first, new appended).
- Scalars: existing value WINS (never overwritten by the fragment).
- Atomic write via .tmp + rename.

Usage: merge-settings.py <fragment.json> <target.json>
"""
import json
import os
import sys
import tempfile


def deep_merge(base, fragment):
    if isinstance(base, dict) and isinstance(fragment, dict):
        out = dict(base)
        for k, v in fragment.items():
            out[k] = deep_merge(base[k], v) if k in base else v
        return out
    if isinstance(base, list) and isinstance(fragment, list):
        out = list(base)
        for item in fragment:
            if item not in out:
                out.append(item)
        return out
    return base


def main():
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        sys.exit(2)
    fragment_path, target_path = sys.argv[1], sys.argv[2]

    with open(fragment_path) as f:
        fragment = json.load(f)

    if os.path.exists(target_path):
        with open(target_path) as f:
            base = json.load(f)
    else:
        base = {}

    merged = deep_merge(base, fragment)

    target_dir = os.path.dirname(target_path) or "."
    fd, tmp = tempfile.mkstemp(dir=target_dir, prefix=".settings.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(merged, f, indent=2)
            f.write("\n")
        os.replace(tmp, target_path)
    except Exception:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


if __name__ == "__main__":
    main()
