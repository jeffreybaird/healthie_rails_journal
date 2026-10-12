# Healthie Rails Journal

A Rails foundation for the provider/client/journal assignment, using Active
Record, SQLite and Puma. `Provider` and `Client` each store a name, email address,
and Rails timestamps. `ProviderClientRelationship` connects them and stores a
client's `basic` or `premium` plan with each provider. Journal entries, journal
queries, and sample seed data are not implemented yet.

```sh
bundle install
bin/rails db:prepare
bin/rails console
bin/rails server -b 0.0.0.0 -p 4000
bin/check
```

In the Rails console, create and retrieve synthetic records:

```ruby
provider = Provider.create!(name: "Morgan Example", email: "morgan@example.test")
client = Client.create!(name: "Alex Example", email: "alex@example.test")
Provider.find(provider.id).attributes.slice("name", "email")
# => {"name" => "Morgan Example", "email" => "morgan@example.test"}
Client.find(client.id).attributes.slice("name", "email")
# => {"name" => "Alex Example", "email" => "alex@example.test"}
ProviderClientRelationship.create!(provider: provider, client: client, plan: "basic")
provider.clients
# => relation containing Alex Example
client.providers
# => relation containing Morgan Example

second_provider = Provider.create!(name: "Taylor Example", email: "taylor@example.test")
second_provider.provider_client_relationships.create!(client: client, plan: "premium")
client.provider_client_relationships.pluck(:provider_id, :plan)
# => the two provider IDs with "basic" and "premium", respectively
```

Both models inherit from `ApplicationRecord` and use ordinary Active Record
persistence. Name and email are nullable strings, with no presence, format,
length, or uniqueness validation: the assignment requires storing these values,
but states no restrictions. Duplicate emails, blank values, and missing values
are accepted. Tables use Rails primary keys and non-null `created_at` and
`updated_at` timestamps. Both models expose `provider_client_relationships` and
their opposite records through that association, returning composable Active
Record relations. Each pair has one relationship: model validation gives a
useful rejection and a unique database index protects concurrent writes.
Relationships require existing providers and clients and accept exactly
`basic` or `premium`; a client's plan belongs to the relationship, so it can
differ between providers. See [.docs/database.md](.docs/database.md) for schema
choices.

`GET /` deliberately returns HTTP 204 with no body. `GET /health` and `GET /up`
return HTTP 200 with `{"status":"ok"}` when the database is reachable. Production
uses `SECRET_KEY_BASE`, `DATABASE_PATH=/data/app.db` and `PORT=4000`. SQLite WAL is
replicated by Litestream. Deploy migrations run `bundle exec rails db:prepare`
before the healthy blue/green container receives traffic. Keep migrations
compatible with the previous release; image rollback does not undo migrations.

No Solid Queue, Solid Cache or Solid Cable services/databases are configured.
Add background jobs or extra databases deliberately, with corresponding
deployment and backup changes. See `AGENTS.md` and `.docs/`.

The generated Notes interface, models, services and routes have been retired.
The original creation migration is removed. The cleanup migration drops legacy
`notes` and `audit_logs` tables and their data when `db:prepare` runs, including
production deployment. This removal is explicitly authorized; fresh databases
do not create these tables. The migration cannot restore deleted data, and older
Notes-enabled application images are incompatible with the resulting schema.
See [.docs/database.md](.docs/database.md) for rollout and rollback details.

`bin/check` prepares the test database, runs RuboCop, RSpec and strict Cucumber,
then enforces 100% line and branch coverage across all application and library
Ruby files before checking current dependency advisories with bundler-audit.
Deployment regression specs require the Docker CLI with its Compose plugin;
they validate configuration without a running Docker daemon.
Coverage results are cleared first; both suites must produce fresh results.
Keep Gemfile.lock committed. Before committing, run safe RuboCop autocorrection
on files you own, then rerun bin/check. Do not disable checks to pass.
