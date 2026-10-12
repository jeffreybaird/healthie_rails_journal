# Healthie Rails Journal project guidance

## Purpose

This repository is the Rails data-model foundation for a pairing interview.
Keep the code small, readable and easy to explain. It should support a walkthrough
of the schema and queries, followed by a small query, validation or model change.

These app-specific rules take precedence over generic scaffold examples. Let the
interview requirements drive the design. This file is preserved by agent-docs.sh
updates.

## Data model

Use Rails migrations and Active Record models for:

- `Provider`: stores a name and email address and has many clients through
  provider-client relationships.
- `Client`: stores a name and email address and has many providers through
  provider-client relationships.
- `ProviderClientRelationship`: belongs to one provider and one client and stores
  that client's plan with that provider. The plan is either `basic` or `premium`.
  Each provider-client pair has one relationship; a client may have a different
  plan with each provider.
- `JournalEntry`: belongs to one client and stores freeform text and timestamps.

Use foreign keys for the associations and a unique database index for the
provider-client pair. Validate the allowed plan values. Choose other validations
only when they follow from a stated requirement, and explain the choice.

## Required queries

Provide working Active Record queries for:

1. All clients for a given provider.
2. All providers for a given client.
3. All journal entries for a given client, sorted by date.
4. All journal entries across all clients of a given provider, sorted by date.

Use associations and small named scopes where helpful. Journal history uses
`created_at` descending, then `id` descending to make ties predictable. Return
composable Active Record relations. Demonstrate all four queries in the README
with examples that can be run in the Rails console.

## Implementation and sample data

Prefer ordinary Rails conventions and direct Active Record use. Introduce another
layer only when the current behavior needs it. Keep schema changes in migrations
and add indexes that support the required queries.

Provide synthetic seed data with a client shared by two providers, different
plans, multiple dated journal entries and an unrelated client. The sample data
should make the associations, query boundaries and ordering easy to demonstrate.
Never use real health information or log journal text or personal data.

Be ready to explain schema choices, index choices and how the queries would
behave with a much larger dataset. Document relevant tradeoffs briefly.

## Tests and verification

Test the model associations, one relationship per provider-client pair, allowed
and rejected plan values, journal persistence and all four required queries.
Include shared clients, unrelated records, empty results and entries with equal
timestamps. Assert the returned records and their ordering, not just counts.

Follow [agent-workflow.md](agent-workflow.md) for source/test ownership and
[testing.md](testing.md) for verification. Preserve the existing `bin/check`
quality gate, including fresh 100% line and branch coverage, lint and a current
dependency audit. Keep test databases isolated from development and deployed data.

## README and local setup

Include the commands to install dependencies, prepare the database, load sample
data, open the Rails console and run checks. Describe the model relationships,
show the required queries and note any incomplete work honestly. Keep the README
focused on what someone needs to run, understand and extend this Rails exercise.
