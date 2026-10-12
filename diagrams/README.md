# Diagrams

One diagram per concern. Each answers exactly one question — if a diagram needs
a "and" in its title, it is two diagrams.

## Index

| File | Level | Question |
|---|---|---|
| `00-context.mmd` | Context | What are the moving parts? |
| `10-create-product.mmd` | Container | What happens during Create Product? |

## Rendering

```bash
npm run diagrams        # render all → docs/img/
npm run diagrams:check  # exit 1 if any committed SVG is stale
```

The script is also callable directly as `./scripts/render-diagrams.sh [--check]`.
It uses the locally pinned `mermaid-cli` from `package-lock.json`, so run
`npm ci` first. A fallback to a floating `npx` download exists for convenience,
but it warns — an unpinned renderer changes the SVG bytes and breaks the
byte-exact staleness check.

### Syntax gotcha

A bare `%%` line with **no text after it** breaks the Mermaid parser with a
misleading `Parse error on line 1` that points at the comment block rather
than the empty comment. Use `%% ` (with a trailing space) or a genuinely
blank line.

## Provenance: specified vs inferred

The most important rule in this file. An earlier revision of these diagrams
described an AWS Marketplace *seller* integration — entitlements, metering,
`CustomerIdentifier` — that the owner had never specified. It was invented,
presented confidently, and sat in the repo long enough to look authoritative.

So: **never let a guess look like a decision.**

| Marker | Meaning |
|---|---|
| Solid node/edge | Specified by the owner. Authoritative. |
| Amber dashed node/edge | Inferred or undecided. Not a decision — do not build on it. |
| `%%` comment | Why the diagram looks like this |

The styling is two lines:

```
classDef notspecified stroke-width:2px,stroke:#b45309,stroke-dasharray: 2 2
class api,image_store notspecified
```

If a detail is not specified, **say it is not specified** — in the diagram, in
[`../docs/system.md`](../docs/system.md), and in the commit message. An
unresolved question written down is useful. An invented answer written down is
a liability that outlives the conversation it came from.

## Authoring conventions

The goal is that a diagram is legible to a human reading it *and* to an agent
grepping it. These rules are what make that true.

### 1. Stable node IDs are the contract

```mermaid
flowchart LR
  create_product["Create Product handler"]   %% ID = contract, label = prose
```

The ID is referenced from docs, other diagrams, and eventually from code. The
label is free prose. **Renaming an ID is a breaking change** — update every
reference in the same commit.

### 2. Label every edge

```mermaid
client -- "POST /products → 201 Created" --> api
```

An unlabeled edge makes a reader guess the protocol, the direction, and the
payload. If you cannot label it, you do not understand it well enough to draw
it.

### 3. Put the rationale inline

```mermaid
%% The spec says 'images' without saying what an image is. DynamoDB caps an
%% item at 400 KB, so bytes cannot live in products_table.
```

Mermaid ignores `%%` comments when rendering; agents read them first. A comment
sitting directly above the edge it explains survives refactoring in a way that
a paragraph in `docs/system.md` does not.

### 4. Undecided things are amber dashed

```
classDef notspecified stroke-width:2px,stroke:#b45309,stroke-dasharray: 2 2
class api,image_store notspecified
```

Everything in this system is AWS-managed, so a "third party vs ours" marking
buys nothing here. What a reader actually needs to know is *which parts are
real yet*. See [Provenance](#provenance-specified-vs-inferred).

### 5. Style sheet

| Element | Convention |
|---|---|
| IDs | `snake_case`, no version or number suffixes |
| Edge labels | `METHOD /path → payload`, quoted |
| Node labels | `<Thing><br/>id: node_id` for named nodes |
| Subgraphs | Quote the label; lowercase ID |
| Unverified facts | `TODO(verify):` in a `%%` comment |

## Why text instead of a drawing tool

Draw.io, Excalidraw, and Figma are excellent for human whiteboarding and bad
source of truth for agents — the format is opaque and the edit surface is
spatial. Text formats are greppable, diffable, and reviewable in a pull
request. The render step costs a command; the debugging step costs hours.