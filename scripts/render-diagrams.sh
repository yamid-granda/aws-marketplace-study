#!/usr/bin/env bash
#
# Render every diagram in diagrams/ to docs/img/.
#
#   ./scripts/render-diagrams.sh          render and write docs/img/
#   ./scripts/render-diagrams.sh --check  exit 1 if any committed SVG is stale
#
# The .mmd files are the source of truth. These SVGs are derived output and are
# regenerated, never hand-edited. --check exists so CI can catch the case where
# someone edits a .mmd and forgets to re-render.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIAGRAM_DIR="$REPO_ROOT/diagrams"
OUTPUT_DIR="$REPO_ROOT/docs/img"
TMP_DIR="$REPO_ROOT/.tmp/render"

CHECK_ONLY=false
if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=true
fi

# Prefer the pinned local install. Falling back to a floating `npx --yes`
# silently picks up whatever mermaid-cli is newest, which can change the
# rendered SVG and make --check fail in CI for reasons unrelated to the .mmd.
if [[ -x "$REPO_ROOT/node_modules/.bin/mmdc" ]]; then
  MMDC=("$REPO_ROOT/node_modules/.bin/mmdc")
else
  echo "note: mermaid-cli not installed locally; falling back to npx (unpinned)" >&2
  MMDC=(npx --yes @mermaid-js/mermaid-cli)
fi

command -v node >/dev/null 2>&1 || { echo "error: node is required" >&2; exit 1; }

shopt -s nullglob
SOURCES=("$DIAGRAM_DIR"/*.mmd)
shopt -u nullglob

if [[ ${#SOURCES[@]} -eq 0 ]]; then
  echo "error: no .mmd files found in $DIAGRAM_DIR" >&2
  exit 1
fi

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR" "$OUTPUT_DIR"

echo "rendering ${#SOURCES[@]} diagram(s)..."

failed=0
for src in "${SOURCES[@]}"; do
  name="$(basename "$src" .mmd)"
  out="$TMP_DIR/$name.svg"

  # Pre-flight: a bare '%%' line with no text makes Mermaid fail with a
  # misleading "Parse error on line 1" pointing at the comment block instead of
  # the empty comment. Name the real problem here.
  #
  # The pattern anchors on '%%' at end-of-line with no trailing blank, so the
  # recommended fix ('%% ' with a trailing space) does not trip this check.
  if grep -nqE '^[[:blank:]]*%%$' "$src"; then
    echo "  ERROR $name.mmd — bare '%%' comment line(s), which Mermaid cannot parse:" >&2
    grep -nE '^[[:blank:]]*%%$' "$src" | sed 's/^/          line /' >&2
    echo "         use '%% ' with a trailing space, or a genuinely blank line" >&2
    failed=1
    continue
  fi

  if ! "${MMDC[@]}" --input "$src" --output "$out" --quiet 2>"$TMP_DIR/$name.err"; then
    echo "  FAIL  $name.mmd — invalid Mermaid syntax" >&2
    sed 's/^/        /' "$TMP_DIR/$name.err" >&2
    failed=1
    continue
  fi

  if [[ "$CHECK_ONLY" == true ]]; then
    committed="$OUTPUT_DIR/$name.svg"
    if [[ ! -f "$committed" ]]; then
      echo "  STALE $name.svg — never committed; run ./scripts/render-diagrams.sh" >&2
      failed=1
    elif ! cmp -s "$out" "$committed"; then
      echo "  STALE $name.svg — out of date with $name.mmd" >&2
      echo "        run ./scripts/render-diagrams.sh and commit the result" >&2
      failed=1
    else
      echo "  ok    $name.svg"
    fi
  else
    cp "$out" "$OUTPUT_DIR/$name.svg"
    echo "  wrote $name.svg"
  fi
done

rm -rf "$REPO_ROOT/.tmp"

if [[ $failed -ne 0 ]]; then
  exit 1
fi

if [[ "$CHECK_ONLY" == true ]]; then
  echo "all diagrams up to date"
else
  echo "done — commit docs/img/ alongside any .mmd change"
fi