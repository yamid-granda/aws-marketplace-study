# Diagrams

One diagram for the whole system design flow.

## Index

| File | Question |
|---|---|
| `00-system.mmd` | How does a `Create Product` request move through the system? |

`Create Product` is the only feature so far. As features are added, extend this
file rather than adding a new one — see [When to split](#when-to-split).

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

### Syntax gotchas

The script pre-flights one trap and Mermaid's own errors are unhelpful for the
rest:

- **Bare `%%` comment lines break the parser.** A line containing only `%%`
  fails with `Parse error on line 1`, pointing at the comment block rather than
  the empty comment. Use `%% ` with a trailing space, or a blank line.
  `render-diagrams.sh` now detects this and names it.
- `<` inside a node label can be read as an HTML tag start. If a label misbehaves,
  try replacing `<=` with `≤` or spelling it out.

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
class api,image_store,resolve_images,assign_id,is_duplicate notspecified
```

If a detail is not specified, **say it is not specified** — in the diagram, in
[`../docs/system.md`](../docs/system.md), and in the commit message. An
unresolved question written down is useful. An invented answer written down is
a liability that outlives the conversation it came from.

## When to split

One diagram is the right answer today, and splitting preemptively would be
premature — a two-file diagram of a five-node system is harder to read, not
easier. But a single diagram does not scale forever.

Split when a diagram starts failing, not when it hits a node count:

| Trigger | Action |
|---|---|
| Edge labels start overlapping and the render needs checking | First sign. Shorten labels. |
| You cannot trace one request end-to-end without a finger on the screen | Split: flow per feature, context separate. |
| The same node appears in two files and you edit both | The model wants to be shared. Split, or move to Structurizr. |
| You are tempted to hide detail to keep it fitting | Already too big. Split. |

When it splits, the convention returns to one concern per file — a context
diagram for the components, and one flow diagram per feature. The numbering
prefix exists for that: `00-context.mmd`, `10-create-product.mmd`,
`20-next-feature.mmd`.

## Authoring conventions

The goal is that a diagram is legible to a human reading it *and* to an agent
grepping it.

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
| Direction | `flowchart TB` — tall scrolls, wide shrinks to illegible in markdown |

## Why text instead of a drawing tool

Draw.io, Excalidraw, and Figma are excellent for human whiteboarding and bad
source of truth for agents — the format is opaque and the edit surface is
spatial. Text formats are greppable, diffable, and reviewable in a pull
request. The render step costs a command; the debugging step costs hours.