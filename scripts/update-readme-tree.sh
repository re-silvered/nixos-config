#!/usr/bin/env bash
# Blatantly ripped this btw
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
README="$ROOT/README.md"

TREE="$(
  cd "$ROOT"

  tree \
    --dirsfirst \
    --noreport \
    -I '.git|.github|result|README.md|LICENSE|flake.lock|scripts|secrets'
)"

export TREE

python3 - "$README" <<'PY'
import os
import sys
from pathlib import Path

readme = Path(sys.argv[1])

start = "<!-- TREE-START -->"
end = "<!-- TREE-END -->"

text = readme.read_text()

if start not in text or end not in text:
    raise SystemExit(
        f"README must contain {start} and {end}"
    )

before, rest = text.split(start, 1)
_, after = rest.split(end, 1)

tree = os.environ["TREE"]

replacement = (
    f"{start}\n\n"
    "```text\n"
    f"{tree}\n"
    "```\n\n"
    f"{end}"
)

readme.write_text(before + replacement + after)
PY
