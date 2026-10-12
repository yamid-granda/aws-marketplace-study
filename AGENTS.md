# AGENTS.md

Working agreement for this repository. Read this before editing anything.

## What this repo is

A study workspace for AWS Marketplace integration (entitlement + metering). Its
purpose is to hold **written reasoning** about the system, with diagrams as
derived views over that reasoning.

## The one invariant

> **The `.mmd` files are the source of truth. The `.svg` files are generated output.**

Never hand-edit anything in `docs/img/`. If a rendered SVG disagrees with its
`.mmd`, the `.mmd` is right and the SVG is stale. Fix it with:

```bash
./scripts/render-diagrams.sh
```

A CI job fails the build if a committed SVG is out of date, so drift is caught
automatically. Do not "fix" CI by re-committing stale SVGs.

## File map

| Path | Purpose |
|---|---|
| `docs/system.md` | Narrative: scope, constraints, glossary, terminology |
| `diagrams/*.mmd` | **Editable** diagrams — one per concern |
| `diagrams/README.md` | Diagram index and the conventions below |
| `docs/img/*.svg` | **Generated** — do not edit |
| `scripts/render-diagrams.sh` | Renders all diagrams, fails on stale output |

## Diagram conventions

These are not stylistic preferences. They are what makes a diagram legible to
both a human reading it and an agent grepping it.

1. **Stable node IDs.** Every node is `id["Human Label"]`. The ID is the
   contract that other diagrams, docs, and code reference. The label is prose
   that may change freely. Never rename an ID without updating references.

2. **Label every edge.** Use `a -->|"METHOD / path → payload"| b`. An
   unlabeled edge forces a reader (human or agent) to guess the protocol,
   direction, and payload. If the edge has no label, it is not understood.

3. **One concern per file.** A diagram that answers one question renders
   legibly. A diagram that answers five renders as a hairball. Split it.

4. **Rationale goes inline.** Put the *why* in a `%%` comment directly above
   the edge or node it explains. Mermaid ignores comments when rendering; an
   agent reads them first. A rationale three paragraphs away from the decision
   it explains is lost.

5. **External systems get the dashed class.**
   `class marketplace external` — anything you do not control.

6. **Cross-reference by path.** Link diagrams to the code or doc that
   implements them so an agent can jump from diagram to implementation.

## Accuracy rule

This is a study repo, so wrong-but-confident is worse than incomplete.

Before asserting anything about AWS Marketplace API behaviour — limits, field
semantics, status codes, endpoints — verify it against the current AWS
documentation and cite it. If you cannot verify it, write it down as an open
question in `docs/system.md` rather than guessing. Mark unverified specifics
with `TODO(verify):`.

## Commands

```bash
./scripts/render-diagrams.sh          # render all diagrams to docs/img/
./scripts/render-diagrams.sh --check  # fail if any SVG is stale (use in CI)
```

Renders via `npx @mermaid-js/mermaid-cli`, so there is no install step and no
lockfile to maintain. The first run downloads the CLI.