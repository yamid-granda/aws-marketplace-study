# System: AWS Marketplace integration

Scope, terminology, and constraints for the integration being studied here.
This is the narrative layer — diagrams in [`../diagrams`](../diagrams) are
views over what is written here.

> **Accuracy note.** API limits and field semantics change. Anything asserted
> about AWS Marketplace behaviour is marked `TODO(verify)` until checked against
> the current AWS documentation.

## What the vendor sells

A multi-tenant SaaS product, sold through AWS Marketplace to AWS customers. Two
billing models matter here:

- **SaaS contract** — a subscription. The buyer pays a flat fee for the term
  and usage is unlimited from the vendor's perspective.
- **SaaS with metered usage** — the buyer subscribes to *dimensions* (seats,
  API calls, GB-months), and the vendor reports consumption against them.

The integration has to support both. A SaaS-contract buyer still needs
entitlement resolution (is this account actually subscribed, and until when?),
but generates no usage records.

## The central problem

AWS Marketplace does not tell the vendor about new subscribers through a
push notification. The vendor has to discover them. That single fact drives
almost every design decision in this repo, and it is the reason the system has
two separate paths with very different latency and failure characteristics:

- **Entitlement resolution** — synchronous, on the user's request path.
  If this is slow or unavailable, customers cannot use the product.
- **Metering** — asynchronous, batched. If this is slow or unavailable, the
  vendor under-bills and AWS Marketplace eventually rejects the records.

## AWS Marketplace API surface

All calls are SigV4-signed HTTPS against the regional Metering endpoint
(`metering.<region>.amazonaws.com`). Three operations drive everything:

| Operation | Purpose | Latency class |
|---|---|---|
| `ResolveCustomer` | Map an AWS account ID → opaque `CustomerIdentifier` | Setup, not request path |
| `ResolveEntitlements` | Given a `CustomerIdentifier`, list active entitlements | Synchronous, request path |
| `BatchMeterUsage` | Report a batch of consumption records | Asynchronous, batched |

### `CustomerIdentifier` is the join key

`ResolveCustomer` returns an **opaque, per-customer-per-product identifier**.
It is deliberately not the AWS account ID and must not be guessable.

This is the security and data-modelling crux of the whole integration: the
`CustomerIdentifier` — not the AWS account ID — is the key that usage records
are metered against and entitlements are keyed by. Building your own billing
key off the account ID instead would be a design error.

### Entitlements are dimensioned and time-bounded

An entitlement is not a boolean. Each carries a `Dimension`, a grant value
(`Entitlement`), validity dates (`StartDate` / `EndDate`), an `EffectiveDate`,
and an `Overage` flag. Time-bounded means "not entitled" is a normal,
expected state — and an entitlement that expires mid-session is a real case,
not an edge case.

### Metering results are per-record, and failures are expected

`BatchMeterUsage` returns a `UsageRecordResult` per submitted record, in
order, each with its own `Status`. Statuses observed include `Success`,
`CustomerNotSubscribed`, `DuplicateRecord`, `InvalidTimestampDimension`,
`NotEntitled`, and `Throttled`.

Two consequences:

1. **Partial success is the normal case.** A batch succeeding does not mean the
   records in it were accepted. A naive "batch call returned 200, drop the
   batch" integration loses revenue on every partial failure.
2. **Failures are mostly permanent, not transient.** `DuplicateRecord` and
   `NotEntitled` must not be retried forever. Only throttle-shaped statuses
   warrant backoff. This is the single easiest thing to get wrong.

`TODO(verify)`: confirm the current maximum records per `BatchMeterUsage` call
and the current throttle thresholds before sizing the batcher in
[`../diagrams/20-metering.mmd`](../diagrams/20-metering.mmd).

## Constraints

- **Entitlement resolution is on the hot path.** It cannot block the product
  on a third-party round trip for every request without a latency budget and a
  degradation story. See
  [`../diagrams/10-entitlement.mmd`](../diagrams/10-entitlement.mmd).
- **Vendor is not the system of record for subscriptions.** AWS Marketplace
  is. The vendor's mirror is a cache, and any cache must be built so that
  losing it is recoverable.
- **Usage records must survive vendor failure.** Records already accepted by
  AWS Marketplace must never be re-sent, or they double-bill. This is why
  idempotency, not retry, is the hard part of metering.
- **Credentials are AWS-native.** SigV4 to a regional endpoint means IAM
  rotation and regional scoping are real concerns, not hypotheticals.

## Open questions

- Cache TTL for entitlements: long enough to protect the hot path, short
  enough that revocation feels prompt. No answer yet — this is the main design
  tension in `10-entitlement.mmd`.
- Behaviour when the entitlement API is unavailable but a cached entitlement
  exists. Fail-open and fail-closed are both defensible; the answer depends on
  what the product does, which is not yet decided.
- Whether usage records need to be reconciled against AWS Marketplace billing
  reports, or whether Marketplace reconciliation is sufficient.