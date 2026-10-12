# System: AWS Marketplace

Working spec for a product-catalog service.

> **Provenance rule for this file.** Three kinds of statement appear here, and
> they are never mixed:
>
> - **Specified** — given by the project owner. Authoritative.
> - **Inferred** — follows from the specified architecture but not stated.
>   Marked inline. Do not treat as decided.
> - **Open** — a decision nobody has made. Marked inline.
>
> Earlier revisions of this file described an AWS Marketplace *seller
> integration* (entitlements, metering, `CustomerIdentifier`). That was
> invented, not specified, and has been removed. If you encounter it in git
> history below the commit that replaced it, it describes nothing real.

## Specified

### Project

Title: **AWS Marketplace**.

### Endpoint 1 — Create Product

Creates a product record. Persisted via AWS Lambda into DynamoDB.

**Request payload:**

| Field | Type | Constraint |
|---|---|---|
| `name` | string | — |
| `description` | string | — |
| `images` | array | **min 1, max 3** |
| `price` | number | — |
| `stock` | number | — |

The payload as specified does not define a product identifier, a currency, or
any authentication. Those are listed under [Open questions](#open-questions),
not filled in here.

## Architecture

| Concern | Specified |
|---|---|
| Front door | API Gateway |
| Compute | AWS Lambda |
| Product storage | DynamoDB |
| Image storage | S3 |

## Data model

A product is stored as a DynamoDB item. The fields are specified; their
*types* are not, and two of them cannot safely use the obvious type.

### `price` must be integer minor units

The payload says `price` is a number. A JSON number is a float, and float
arithmetic does not round: `0.1 + 0.2` is not `0.3`. Any later computation on
price — tax, discounts, refunds, totals — inherits that error.

**Recommendation:** store `price` as an integer in minor units (`1999` for
$19.99) alongside an explicit `currency` field, or as a decimal string. Never
a float.

> **Open:** currency is absent from the payload. A bare number is meaningless
> across currencies, and the choice of representation constrains every later
> endpoint that touches price.

### `images` live in S3, not in the item

**Specified:** images are stored in S3. DynamoDB caps an item at 400 KB, so
image bytes cannot live in the product item — the item holds references
instead.

> **Open:** what a reference is. An S3 key, or a pre-signed URL? And does
> `images: 3` mean three uploaded objects or three references? Also undecided:
> whether the merchant uploads before or after the product is created, and how
> orphaned uploads are reclaimed if the create call then fails.

### `stock` constrains every later endpoint

On *create*, `stock` is just an initial value — set, not decremented. But it
determines what any future purchase or reservation endpoint is allowed to do,
so the type has to be chosen now.

Two requirements follow:

1. **Concurrent decrement must not oversell.** A read-then-write in Lambda
   lets two simultaneous purchases both read `stock: 1` and both succeed. The
   write must be conditional: `SET stock = stock - :q IF stock >= :q`, with a
   failed condition meaning "someone else won the race".
2. **Unlimited stock needs a representation.** If a product can be unlimited,
   that state must be distinguishable from a large finite number. A sentinel
   is workable; a missing field is not, because absence is ambiguous with
   "not set".

> **Open:** whether unlimited stock is possible, and how it is represented.

### Missing: a product identifier

The payload has no `productId`. Something must generate one — UUID, a
ULID, or a caller-supplied SKU — and it becomes the DynamoDB partition key.

> **Open:** identifier generation, and whether the caller supplies a SKU.

### Missing: idempotency

Lambda retries on failure. A retried `Create Product` creates a second product
unless the write is conditional or keyed on a merchant-supplied idempotency
token. This interacts directly with the identifier question above.

> **Open:** whether merchants may retry, and how duplicates are prevented.

## Diagrams

| Diagram | Question |
|---|---|
| [`../diagrams/00-system.mmd`](../diagrams/00-system.mmd) | How does a `Create Product` request move through the system? |

`Create Product` is currently the only feature, so `00-system.mmd` carries the
whole system design flow. As features are added, extend it and split only when
it stops being legible — see
[`../diagrams/README.md`](../diagrams/README.md) → "When to split".

## Open questions

Consolidated, in rough order of how much they block:

1. **Remaining endpoints.** The spec was numbered "1. Create Product",
   implying more exist. None have been provided, so the catalog cannot yet
   be described end to end.
2. **Product identifier** — generated or supplied? Becomes the partition key.
3. **`price` representation** — minor units or decimal string? Currency?
4. **Image reference shape** — S3 key or pre-signed URL? Upload before or after
   product creation, and how are orphaned uploads reclaimed?
5. **Authentication** — who is permitted to create a product? A public
   catalog endpoint with no auth is a write endpoint anyone can call.
6. **Stock semantics** — can it be unlimited? How is that represented?
7. **Idempotency** — can callers retry safely?
8. **One-time vs recurring price** — determines whether `stock` even means
   the same thing. A subscription is not stock-constrained the way a
   physical good is.