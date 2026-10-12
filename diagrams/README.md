# Diagrams

One diagram per concern. Each answers exactly one question — if a diagram needs
a "and" in its title, it is two diagrams.

## Index

| File | Level | Question |
|---|---|---|
| `00-context.mmd` | Context | Who talks to what, and what do we own? |
| `10-entitlement.mmd` | Container | How does a request become an authorized request? |
| `20-metering.mmd` | Container | How does usage become revenue? |

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

## Authoring conventions

The goal is that a diagram is legible to a human reading it *and* to an agent
grepping it. These rules are what make that true.

### 1. Stable node IDs are the contract

```mermaid
flowchart LR
  vendor_svc["Entitlement Service"]   %% ID = contract, label = prose
```

The ID is referenced from docs, other diagrams, and eventually from code. The
label is free prose. **Renaming an ID is a breaking change** — update every
reference in the same commit.

### 2. Label every edge

```mermaid
a -- "SigV4 POST /ResolveEntitlements → Entitlements[]" --> b
```

An unlabeled edge makes a reader guess the protocol, the direction, and the
payload. If you cannot label it, you do not understand it well enough to draw
it.

### 3. Put the rationale inline

```mermaid
%% Why: ResolveEntitlements on every request would add a third-party round
%% trip to the hot path. Cached instead, with an explicit staleness bound.
```

Mermaid ignores `%%` comments when rendering; agents read them first. A comment
sitting directly above the edge it explains survives refactoring in a way that
a paragraph in `docs/system.md` does not.

### 4. External systems are dashed

```mermaid
classDef external stroke-dasharray: 4 3
class marketplace external
```

Anything you do not control is external. This makes ownership legible at a
glance, which is usually the actual question a reader has.

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