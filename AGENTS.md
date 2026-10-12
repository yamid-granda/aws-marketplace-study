# AGENTS.md

Working agreement for this repository. Read this before editing anything.

## What this repo is

Working notes and spec for a product-catalog service. Its purpose is to hold
**written reasoning** about the system, with diagrams as derived views over
that reasoning.

## The rule that matters most

**Never invent spec.** If something is not specified by the owner, write it down
as an open question — do not fill it in with something plausible.

An earlier revision of this repo documented an AWS Marketplace *seller*
integration (entitlements, metering, `CustomerIdentifier`, SigV4) that the owner
had never described. It was invented here, written confidently, and survived
long enough to look authoritative. That is the failure mode this rule exists to
prevent.

Concretely:

- In prose, separate **specified** from **inferred** from **open**. See the
  provenance rule in [`docs/system.md`](docs/system.md).
- In diagrams, mark inferred or undecided nodes with the `notspecified`
  (amber dashed) class. See [`diagrams/README.md`](diagrams/README.md).
- In commit messages, say what you assumed if you had to assume anything.

Being wrong-but-flagged is fine. Being confident-but-invented is not.

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
| `docs/system.md` | The spec, data model, and open questions |
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

3. **One diagram, split only on evidence.** There is a single file,
   `diagrams/00-system.mmd`, covering the whole system design flow. Extending
   it is the default as features arrive. Split into `00-context.mmd` plus one
   flow per feature only when a trigger in
   [`diagrams/README.md`](diagrams/README.md) → "When to split" actually fires —
   overlapping labels, an untraceable request, or a node duplicated across
   files. Do not split preemptively: two files for a five-node system is harder
   to read, not easier.

4. **Rationale goes inline.** Put the *why* in a `%%` comment directly above
   the edge or node it explains. Mermaid ignores comments when rendering; an
   agent reads them first. A rationale three paragraphs away from the decision
   it explains is lost.

5. **Undecided things get the `notspecified` class.**
   `classDef notspecified stroke-width:2px,stroke:#b45309,stroke-dasharray: 2 2`
   renders amber and dashed. Everything currently in `00-system.mmd` is
   specified, so no node is marked today — but a new feature must mark anything
   undecided. Everything here is AWS-managed, so a "third party vs ours" marking
   carries no meaning; what a reader needs to know is which parts are real yet.
   See the provenance rule above; never let a guess render as solid.

6. **Cross-reference by path.** Link diagrams to the code or doc that
   implements them so an agent can jump from diagram to implementation.

7. **A bare `%%` line breaks the parser** and reports the error at line 1,
   pointing at the comment block. Use `%% ` with a trailing space.
   `render-diagrams.sh` pre-flights this.

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

Wrong-but-flagged beats confident-but-invented.

When asserting anything about AWS service behaviour — DynamoDB limits, Lambda
retry semantics, S3 constraints, conditional-write guarantees — verify it
against current AWS documentation and cite it. If you cannot verify it, write it
as an open question in `docs/system.md` and mark it `TODO(verify):`.

The same applies to the owner's own spec. The `Create Product` payload is the
only specified contract in this repo. Everything downstream of it — the
identifier, currency, image storage, auth — is currently undecided, and
`docs/system.md` says so. Do not quietly promote one of those to a decision
because the diagram looked incomplete without it.

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

`npm run lint:commit` picks a base ref automatically and refuses to report
success on an empty range — a brand-new repo has no `origin/main` until its
first push, and `commitlint --from origin/main` otherwise dies with a stack
trace. Pass a base explicitly if you need one: `./scripts/lint-commits.sh <base> [<to>]`.