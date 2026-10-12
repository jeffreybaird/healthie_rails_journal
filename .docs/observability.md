# Observability

The scaffold uses Rails logging and ActiveSupport notifications. It does not
install an OpenTelemetry SDK, exporter, collector, metrics backend or job system.

No domain audit writer or notification publisher is currently installed. If
introduced later, audit and instrumentation need different guarantees:
notifications are synchronous in-process observations, not durable messages.
Never rely on a subscriber to perform required audit or billing work.

Use stable operation names and structured identifiers for correlation. Do not
log journal contents, request bodies, credentials, payment details, signed URLs,
emails or raw vendor error payloads. Filter sensitive request parameters before
adding new inputs. Keep error types and bounded status metadata useful without
copying secrets. Logs should distinguish expected rejection from system failure.

If tracing becomes necessary, use maintained Rails/Active Record instrumentation
for their layers, then add manual spans for domain orchestration and unwrapped
external calls. Avoid duplicate spans, high-cardinality metric labels and
unbounded payloads. Configure endpoints and credentials at runtime.

When event publishers are introduced, test event identity, payload privacy and
commit/rollback timing. A subscriber exception after commit must remain an
exception; never pretend the persisted
operation rolled back. For critical delivery use an atomic outbox and idempotent
consumer. See `architecture-decisions.md`.
