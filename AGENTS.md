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
| `commitlint.config.mjs` | Conventional Commits rules, enforced locally and in CI |
| `.husky/commit-msg` | Git hook that validates every commit message |

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

## Commit messages

Every commit message must follow [Conventional Commits](https://www.conventionalcommits.org/),
validated by `commitlint` in a `commit-msg` hook and again in CI:

```
type(scope): subject

Body explaining why, not what. Blank line before it.
```

**Rules that will reject your commit:**

- Subject is lowercase. `chore: update readme` ✓ — `chore: Update readme` ✗
- No trailing period on the subject.
- Header at most 100 characters. If the summary needs wrapping, the detail
  belongs in the body.
- `type` must be one of: `build`, `chore`, `ci`, `docs`, `feat`, `fix`,
  `perf`, `refactor`, `revert`, `style`, `test`, `diagrams`.

**Types specific to this repo:**

| Type | Use for |
|---|---|
| `diagrams` | Any change to `diagrams/*.mmd` **or** their rendered SVG |
| `docs` | Prose in `docs/`, `README.md`, `AGENTS.md` |
| `ci` | Workflows and the render script |

Commit a `.mmd` change together with its re-rendered SVG — they are one change.
Do not use `--no-verify` to route around the hook. If the hook itself is wrong,
fix `commitlint.config.mjs` and say so in the commit body.

## Accuracy rule

This is a study repo, so wrong-but-confident is worse than incomplete.

Before asserting anything about AWS Marketplace API behaviour — limits, field
semantics, status codes, endpoints — verify it against the current AWS
documentation and cite it. If you cannot verify it, write it down as an open
question in `docs/system.md` rather than guessing. Mark unverified specifics
with `TODO(verify):`.

## Commands

```bash
npm ci                                  # install pinned dev dependencies
npm run diagrams                        # render all diagrams to docs/img/
npm run diagrams:check                  # fail if any SVG is stale (used in CI)
npm run lint                            # lint commits since origin/main, then diagrams
npm run commitlint -- --edit <file>     # check one specific message file
```

Requires Node `>=20.12` (see `.nvmrc`). `mermaid-cli` is pinned in
`package-lock.json` deliberately: the `--check` comparison is byte-exact, so an
unpinned renderer silently changes the SVGs and turns CI red for reasons that
have nothing to do with the `.mmd`. Bumping it is a deliberate act — expect to
re-render and commit all three SVGs in the same change.

`npm run lint:commit` needs `origin/main` to be fetched. On a repo with no
remote, lint an explicit range instead.