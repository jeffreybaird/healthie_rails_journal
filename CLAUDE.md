
<!-- BEGIN MANAGED AGENT DOCS -->
Read [.docs/project-guidance.md](.docs/project-guidance.md) for app-specific rules.
Keep local guidance there; maintain shared content with agent-docs.sh.

# HealthieRailsJournal — Rails application guidance

Read the shared agent workflow first. Preserve role ownership, accepted tests,
current security audits and safe precommit correction requirements.

## Generated application

Rails, Active Record, SQLite and Puma serve a small Notes example. Domain
operations return explicit dry-monads Results; controllers stay thin, ERB uses
locals, and recoverable content is archived rather than destroyed. Durable audit
rows commit with mutations; IDs-only notifications run after the outer commit.
Lists are indexed, stably ordered and bounded. Keep this single-database service
small; optional guides do not install auth, tenants, jobs or external services.

## Required checks

Run `bin/check`: test database preparation, RuboCop (Rails/RSpec), RSpec, strict
Cucumber, SimpleCov with **100% line and 100% branch coverage** across all app/lib
Ruby files, then bundler-audit with current advisory data. No stale coverage,
threshold bypasses, excluded application code or suppressed cops. Before commit,
safely autocorrect owned Ruby files, then rerun checks. Read `testing.md` for
suite isolation and the explicit legacy gate for adopted applications.

## Working conventions

Expected errors are `Failure([:tag, details])`; unexpected errors raise. Test
successful behavior and every expected rejection. Whitelist request input,
use Rails forms/CSRF, escape user output and keep authorization separate from
data scoping. Use semantic design tokens, accessible controls, stable data-testid
hooks and meaningful empty/error states. Keep UI logic on the server and any
future JavaScript small. Never log secrets, personal data or note contents.

## Supporting guides

- `.docs/architecture-decisions.md` — Architecture decisions
- `.docs/separation-of-concerns.md` — Separation of concerns
- `.docs/database.md` — Database
- `.docs/testing.md` — Testing and quality gates
- `.docs/frontend-map.md` — Frontend map
- `.docs/design-system.md` — Design system
- `.docs/a11y-audit.md` — Accessibility review
- `.docs/theming.md` — Optional theming
- `.docs/rbac.md` — Optional authentication and authorization
- `.docs/multi-tenancy.md` — Optional multi-tenancy
- `.docs/observability.md` — Observability
- `.docs/scalability.md` — Scalability
- `.docs/external-service-integration.md` — Optional external services
- `.docs/payment-integration.md` — Optional payments
- `.docs/object-storage-integration.md` — Optional object storage
- `.docs/deployment.md` — Rails deployment
<!-- END MANAGED AGENT DOCS -->

<!-- BEGIN MANAGED AGENT WORKFLOW -->
Shared native agent workflow version 2.0.0 applies to every behavior
change. This section supersedes legacy workflow, role-assignment, and blanket
test-edit approval instructions only. Preserve domain, privacy, coverage,
static-analysis, deployment, and project constraints. Follow [.docs/agent-workflow.md](.docs/agent-workflow.md) for role ownership,
red → accepted tests → implementation → green → independent review.
Accepted tests are a contract: only the test writer changes them when the
expected behavior changes, with renewed review. Never weaken tests to pass.
The orchestrator coordinates the pipeline. This hook restricts only direct source
and test edits; other files, tools and commands retain ordinary native permissions.
Do not use alternate editing routes to evade the source/test ownership workflow.
<!-- END MANAGED AGENT WORKFLOW -->
