# Healthie Rails Journal

A Rails foundation for the provider/client/journal assignment, using Active
Record, SQLite and Puma. `Provider` and `Client` each store a name, email address,
and Rails timestamps. `ProviderClientRelationship` connects them and stores a
client's `basic` or `premium` plan with each provider. `JournalEntry` stores each
client's freeform journal text. Client journal history is ordered newest first.
Provider-wide journal queries and sample seed data are not implemented yet.

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

entry = client.journal_entries.create!(
  content: "A synthetic journal entry for this example.\nA second line is preserved exactly."
)
entry.reload.content
# => "A synthetic journal entry for this example.\nA second line is preserved exactly."
client.journal_entries
# => relation containing the client's entries
```

To query all clients for a provider, use `provider.clients`. It returns a
composable Active Record relation, including clients shared with another
provider and excluding clients without a relationship to this provider. Results
have no default order; add an explicit order when displaying them.

This independent Rails console example uses synthetic records and unique email
suffixes so it can be run repeatedly:

```ruby
suffix = SecureRandom.hex(8)
query_provider = Provider.create!(name: "Morgan Query Example", email: "morgan-query-#{suffix}@example.test")
other_provider = Provider.create!(name: "Taylor Query Example", email: "taylor-query-#{suffix}@example.test")
empty_provider = Provider.create!(name: "Jordan Query Example", email: "jordan-query-#{suffix}@example.test")
first_client = Client.create!(name: "Avery Query Example", email: "avery-query-#{suffix}@example.test")
shared_client = Client.create!(name: "Blair Query Example", email: "blair-query-#{suffix}@example.test")
unrelated_client = Client.create!(name: "Casey Query Example", email: "casey-query-#{suffix}@example.test")

query_provider.provider_client_relationships.create!(client: first_client, plan: "basic")
query_provider.provider_client_relationships.create!(client: shared_client, plan: "premium")
other_provider.provider_client_relationships.create!(client: shared_client, plan: "basic")
other_provider.provider_client_relationships.create!(client: unrelated_client, plan: "premium")

all_clients = query_provider.clients
all_clients.order(:name, :id).pluck(:name)
# => ["Avery Query Example", "Blair Query Example"]

all_clients.where(id: [shared_client.id, unrelated_client.id]).order(:name, :id).pluck(:name)
# => ["Blair Query Example"]

empty_provider.clients.where(id: shared_client.id).order(:name, :id).to_a
# => []
```

To query all providers for a client, use `client.providers`. It returns a
composable Active Record relation containing providers from both `basic` and
`premium` relationships, including providers shared with another client and
excluding unrelated providers. Results have no default order; add an explicit
order when displaying them.

This independent example uses synthetic records and unique email suffixes so
it can be run repeatedly. Prepare the test database and open a sandbox console;
the sandbox rolls back the example records when you exit:

```sh
env -u DATABASE_URL -u DATABASE_PATH -u PRIMARY_DATABASE_URL RAILS_ENV=test bin/rails db:prepare
env -u DATABASE_URL -u DATABASE_PATH -u PRIMARY_DATABASE_URL bin/rails console --environment=test --sandbox
```

```ruby
suffix = SecureRandom.hex(8)
query_client = Client.create!(name: "Avery Provider Query Example", email: "avery-providers-#{suffix}@example.test")
other_client = Client.create!(name: "Blair Provider Query Example", email: "blair-providers-#{suffix}@example.test")
empty_client = Client.create!(name: "Casey Provider Query Example", email: "casey-providers-#{suffix}@example.test")
first_provider = Provider.create!(name: "Morgan Provider Query Example", email: "morgan-providers-#{suffix}@example.test")
shared_provider = Provider.create!(name: "Taylor Provider Query Example", email: "taylor-providers-#{suffix}@example.test")
unrelated_provider = Provider.create!(name: "Jordan Provider Query Example", email: "jordan-providers-#{suffix}@example.test")

query_client.provider_client_relationships.create!(provider: first_provider, plan: "basic")
query_client.provider_client_relationships.create!(provider: shared_provider, plan: "premium")
other_client.provider_client_relationships.create!(provider: shared_provider, plan: "basic")
other_client.provider_client_relationships.create!(provider: unrelated_provider, plan: "premium")

all_providers = query_client.providers
all_providers.order(:name, :id).pluck(:name)
# => ["Morgan Provider Query Example", "Taylor Provider Query Example"]

all_providers.where(id: [shared_provider.id, unrelated_provider.id]).order(:name, :id).pluck(:name)
# => ["Taylor Provider Query Example"]

empty_client.providers.where(id: shared_provider.id).order(:name, :id).to_a
# => []
```

To retrieve a client's journal history, use `client.journal_entries.recent_first`.
It returns a composable Active Record relation ordered by `created_at DESC, id
DESC`. Equal timestamps put the entry with the higher ID first. Filtering and
limiting stay in SQL and retain the client boundary; a client with no entries
returns an empty relation.

Run this independent example in the test sandbox console shown above:

```ruby
suffix = SecureRandom.hex(8)
history_client = Client.create!(name: "Avery History Example", email: "avery-history-#{suffix}@example.test")
other_client = Client.create!(name: "Blair History Example", email: "blair-history-#{suffix}@example.test")
empty_client = Client.create!(name: "Casey History Example", email: "casey-history-#{suffix}@example.test")
timestamp = Time.utc(2026, 1, 15, 12)
content = "Synthetic journal content for demonstrating ordered client history."

newer = history_client.journal_entries.create!(content: content, created_at: timestamp)
older = history_client.journal_entries.create!(content: content, created_at: timestamp - 1.day)
tied = history_client.journal_entries.create!(content: content, created_at: timestamp)
unrelated = other_client.journal_entries.create!(content: content, created_at: timestamp + 1.day)

history = history_client.journal_entries.recent_first
history.pluck(:id)
# => [tied.id, newer.id, older.id]

history.where(id: [older.id, tied.id, unrelated.id]).limit(1).pluck(:id)
# => [tied.id]

empty_client.journal_entries.recent_first.to_a
# => []
```

The existing `(client_id, created_at, id)` journal index supports this scoped
ordering, including reverse traversal for descending history. Large histories
can use SQL filters and limits without loading every entry; inspect query plans
before adding indexes for further access patterns.

The unique relationship index on `(provider_id, client_id)` supports finding a
provider's clients and prevents duplicate pairs. Its leading `provider_id`
column makes a separate provider-only index redundant; the `client_id` index
supports the reverse query. For larger datasets, inspect query plans before
adding indexes for particular filters or ordering: each additional index uses
storage and adds work to writes.

Both models inherit from `ApplicationRecord` and use ordinary Active Record
persistence. Name and email are required, nonblank strings backed by database
`NOT NULL` constraints. Emails must match `URI::MailTo::EMAIL_REGEXP` and are
unique ignoring case within each model, enforced by model validation and a
database unique index on `lower(email)`. Names can repeat, and a provider and
client may share an email. Email spelling is preserved; syntax validation does
not verify delivery or ownership. Tables use Rails primary keys and non-null `created_at` and
`updated_at` timestamps. Both models expose `provider_client_relationships` and
their opposite records through that association, returning composable Active
Record relations. Each pair has one relationship: model validation gives a
useful rejection and a unique database index protects concurrent writes.
Relationships require existing providers and clients and accept exactly
`basic` or `premium`; a client's plan belongs to the relationship, so it can
differ between providers. See [.docs/database.md](.docs/database.md) for schema
choices.

Journal entries require an existing client and nonblank `content` of at least
50 characters. The minimum follows the assignment; presence validation also
rejects whitespace-only entries. Text uses a database `text` column, with no
maximum length or automatic stripping, formatting, or normalization. Multiple
entries per client are allowed. Client foreign keys and non-null content protect
database integrity; the minimum length is enforced by model validation, which
bulk writes bypass. Journal content, names, and emails are filtered from Rails
request and Active Record attribute logging. No journal HTTP interface is added.

The person-constraint migration checks existing records first and stops if
names/emails are missing or blank, emails are malformed, or emails repeat
ignoring case within a table. Correct those records deliberately before retrying
`bin/rails db:prepare`; the migration does not fill, rewrite, or delete them.
See [.docs/database.md](.docs/database.md) for rollout and rollback behavior.

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
