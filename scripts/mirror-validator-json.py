#!/usr/bin/env python3
"""Mirror per-asset c2pa_view JSON outputs into a flat raw-json/ directory.

`c2pa/validate_evidence.sh` writes the c2pa_view Rust integration test's
per-file JSON to `validator_utility/c2pa_view_conf_<safe-stem>.json` (with
`.` in the stem replaced by `_`). Reviewers expect one validator JSON per
corpus asset in `validator/raw-json/<asset>.json` where `<asset>` matches
the original filename. This script does that mirroring by re-mapping
`safe_stem -> asset_filename` from the conformance samples directory.

Usage: mirror-validator-json.py <utility-dir> <samples-dir> <out-dir>
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

MEDIA_EXTENSIONS = {
    "jpg",
    "jpeg",
    "png",
    "dng",
    "heic",
    "heif",
    "mp4",
    "m4v",
    "m4a",
    "mov",
}


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print(__doc__, file=sys.stderr)
        return 2

    util_dir = Path(argv[1]).resolve()
    samples_dir = Path(argv[2]).resolve()
    out_dir = Path(argv[3]).resolve()
    if not util_dir.is_dir():
        print(f"not a directory: {util_dir}", file=sys.stderr)
        return 2
    if not samples_dir.is_dir():
        print(f"not a directory: {samples_dir}", file=sys.stderr)
        return 2
    out_dir.mkdir(parents=True, exist_ok=True)

    # safe_stem is `stem.replace('.', '_')` (see validate_evidence.rs and
    # validate_evidence.sh). Invert that here by looking up every corpus
    # asset's safe stem.
    expected = {}
    for entry in samples_dir.iterdir():
        if not entry.is_file():
            continue
        ext = entry.suffix.lower().lstrip(".")
        if ext not in MEDIA_EXTENSIONS:
            continue
        safe = entry.stem.replace(".", "_")
        expected[safe] = entry.name

    mirrored = 0
    missing: list[str] = []
    for safe, asset_name in sorted(expected.items()):
        src = util_dir / f"c2pa_view_conf_{safe}.json"
        if not src.is_file():
            missing.append(asset_name)
            continue
        dst = out_dir / f"{asset_name}.json"
        shutil.copyfile(src, dst)
        mirrored += 1

    print(f"  Mirrored {mirrored} validator JSON(s) into {out_dir}")
    if missing:
        print(f"  Missing for {len(missing)} asset(s):", file=sys.stderr)
        for name in missing:
            print(f"    - {name}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
