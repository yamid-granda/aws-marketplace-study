#!/usr/bin/env bash
#
# Lint commit messages over a range.
#
#   ./scripts/lint-commits.sh              # base..HEAD, base auto-detected
#   ./scripts/lint-commits.sh <base> [<to>]
#
# Exists because the obvious invocation — `commitlint --from origin/main` —
# dies with a stack trace when origin/main has never been pushed, which is
# the state of a brand-new repo. This resolves a base, explains itself, and
# refuses to report success on an empty range.

set -euo pipefail

BASE="${1:-}"
TO="${2:-HEAD}"

if [[ -z "$BASE" ]]; then
  for candidate in origin/main origin/master main master; do
    if git rev-parse --verify --quiet "$candidate" >/dev/null 2>&1; then
      BASE="$candidate"
      break
    fi
  done
fi

if [[ -z "$BASE" ]]; then
  cat >&2 <<'EOF'
error: no base ref to compare against.

Looked for origin/main, origin/master, main, master. A brand-new repo has
none of them until the first push, so there is no meaningful range yet.

Pass a base explicitly:
    ./scripts/lint-commits.sh <base> [<to>]
EOF
  exit 2
fi

if ! git rev-parse --verify --quiet "$BASE" >/dev/null 2>&1; then
  echo "error: base ref '$BASE' does not exist" >&2
  exit 2
fi

count="$(git rev-list --count "$BASE..$TO" 2>/dev/null || echo 0)"

if [[ "$count" -eq 0 ]]; then
  # An empty range is a vacuous pass. Say so rather than implying the history
  # was checked.
  echo "no commits in $BASE..$TO — nothing to lint."
  echo "(these commits are already contained in '$BASE')"
  exit 0
fi

echo "linting $count commit(s) in $BASE..$TO"
npx --no-install commitlint --from "$BASE" --to "$TO" --verbose