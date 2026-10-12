# Architecture decisions

The application is a small Rails foundation for the provider/client/journal
assignment. Add domain features only when required; optional guides do not
install infrastructure. The generated Notes runtime and creation migration have
been removed. An explicitly authorized cleanup migration removes legacy tables
and their data from existing databases; see
[database.md](database.md).

The root endpoint deliberately returns HTTP 204 with no body. Readiness endpoints
check database connectivity and return a small JSON response. No replacement
product interface, mutation service or event publisher is installed.

## Domain operations and results

Use direct Active Record models and relations for the assignment. Introduce
domain operations only when behavior needs orchestration. Expected failures in
such operations are explicit `Failure([:tag, details])` values. Handle every tag
at the HTTP boundary and test successful and rejected behavior. Unexpected
database or programming errors propagate; do not disguise them as validation
failures. Add a Result library only when an operation actually needs it.

Models own validation, associations and named query scopes. Controllers whitelist
parameters, call operations and translate results into redirects, status codes
and locals. Views render locals; they do not query or authorize records.

## Durable mutations and observations

No audit model or audit writer is currently installed. If a future operation
requires durable audit records, write them in the same Active Record transaction
as the mutation. An audit failure must roll back the mutation. Add actor
identifiers only when real authentication exists; never invent an actor or log
sensitive field values.

If notifications are introduced, publish identifiers only through
`ActiveSupport::Notifications` in `ActiveRecord.after_all_transactions_commit`.
This waits for the outer transaction and emits nothing on rollback. Notifications
are synchronous, in-process and non-durable. A subscriber exception occurs after
commit and must not be returned as a validation failure implying rollback.

For future critical external effects, persist an outbox entry atomically and
process it with idempotent delivery. An after-commit callback alone has a
commit-to-delivery crash window and cannot guarantee delivery.

## Recoverability and bounded reads

Use explicit named scopes rather than a global `default_scope` for any future
archive visibility. Recovery and retention/erasure operations must be intentional
and separately authorized when authentication is introduced.

Journal history will use `created_at` descending, then `id` descending, with
composable Active Record relations. If pagination is introduced, validate its
bounds and paginate in SQL rather than loading unbounded collections in Ruby.

When introducing tenants, pass a resolved scope explicitly to operations;
scoping determines visible records and policies determine permitted actions.
Feature flags, exports, jobs and caches are optional extensions, not generated
services.
