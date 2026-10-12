# Healthie Rails Journal

A small Rails 8.1 application for a provider/client/journal pairing interview.
It uses ordinary Active Record associations, SQLite and Puma. The models, four
required queries and synthetic sample data are implemented; the console is the
interface for this exercise.

## Run locally

Prerequisites:

- Ruby **3.3.12** (see `.ruby-version`) and Bundler. Activate that Ruby with your
  version manager; the macOS system Ruby is insufficient.
- Git and native gem build tools (for example, Xcode Command Line Tools on macOS,
  or a compiler, `pkg-config` and SQLite development headers on Linux).
- Docker CLI with the Compose plugin for deployment regression specs in
  `bin/check`. Those specs inspect configuration without a running Docker daemon.

From the repository root, in a local terminal:

```sh
ruby --version # should report 3.3.12
export RAILS_ENV=development
unset DATABASE_URL PRIMARY_DATABASE_URL DATABASE_PATH
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails console
```

Exit the console with `exit`, then start the server:

```sh
bin/rails server -b 127.0.0.1 -p 4000
```

Visit <http://127.0.0.1:4000/health> or `/up`: both return HTTP 200 with
`{"status":"ok"}` when the database is reachable. `/` deliberately returns
HTTP 204 with no body. Stop the server with Ctrl-C. There is no journal web UI.

Development uses `db/development.sqlite3`. `db:prepare` creates or migrates the
database and loads seeds on initial creation; the explicit `db:seed` also works
on an existing database. SQLite uses WAL, foreign keys and a five-second busy
timeout. `DATABASE_PATH` can select another local file; `DATABASE_URL` can
override the connection, so the setup above clears inherited overrides.

## Sample records

On an empty database, seeds create two providers, four clients, four
relationships and eight journal entries. Everything is fictional.

| Record | Email | Relationships |
| --- | --- | --- |
| Alex Sample (provider) | seed-alex@example.test | Sam: basic; Taylor: premium |
| Jordan Sample (provider) | seed-jordan@example.test | Sam: premium; Riley: basic |
| Sam Sample (client) | seed-sam@example.test | Shared by Alex and Jordan |
| Taylor Sample (client) | seed-taylor@example.test | Alex only |
| Riley Sample (client) | seed-riley@example.test | Jordan only |
| Unrelated Sample (client) | seed-unrelated@example.test | No providers |

Repeat seed loads preserve existing records and edits. People are matched by
email ignoring case; relationships by provider/client; entries by client,
content and creation date. Editing those entry fields can cause the original
sample entry to be added again alongside the edited entry. Seeds run in one
transaction; run loads sequentially. The results below assume fresh, unedited
sample data.

## Four console queries

Paste this block into `bin/rails console` after setup:

```ruby
alex = Provider.find_by!(email: "seed-alex@example.test")
sam = Client.find_by!(email: "seed-sam@example.test")

# 1. All clients for a provider (no default membership order).
clients = alex.clients
clients.order(:name, :id).pluck(:name)
# => ["Sam Sample", "Taylor Sample"]

# 2. All providers for a client (both plans included).
providers = sam.providers
providers.order(:name, :id).pluck(:name)
# => ["Alex Sample", "Jordan Sample"]

# Display only the labels from the fictional seed text.
labels = lambda do |entries|
  entries.pluck(:content).map do |text|
    text.split(":", 2).first.delete_prefix("Synthetic seed entry ")
  end
end

# 3. All journal entries for a client, newest first.
client_history = sam.journal_entries.recent_first
labels.call(client_history)
# => ["sam-tie-second", "sam-tie-first", "sam-middle", "sam-oldest"]

# 4. All journal entries across a provider's clients, newest first.
provider_history = alex.journal_entries.recent_first
labels.call(provider_history)
# => ["taylor-newest", "sam-tie-second", "sam-tie-first", "taylor-tie", "sam-middle", "sam-oldest"]

# Compose another SQL query without losing membership or ordering.
labels.call(provider_history.where(client_id: sam.id).limit(2))
# => ["sam-tie-second", "sam-tie-first"]

Client.find_by!(email: "seed-unrelated@example.test").providers.to_a
# => []
```

Both histories use **`created_at DESC, id DESC`**, globally across clients for
the provider query. Higher IDs break equal timestamp ties. Seeds insert
`taylor-tie`, `sam-tie-first`, then `sam-tie-second` at midnight UTC on January
15, 2026. Other entries occur on January 5, 10 and 20; Riley's January 25 and
Unrelated's January 30 entries stay outside Alex's history despite being newer.
A shared client's entries appear once per provider query.

The associations and `recent_first` return composable `ActiveRecord::Relation`
objects. `where`, `order` and `limit` build SQL; `pluck` and `to_a` execute it
and produce arrays. The provider history joins through relationships and clients
rather than loading client IDs or querying once per client. Empty associations
return empty relations. Membership scopes data; it does not authorize a caller.

## Schema, validations and indexes

All four tables have Rails primary keys and `created_at`/`updated_at` timestamps.

| Model | Stored data and relationships | Validation and database protection |
| --- | --- | --- |
| `Provider` | Name, email; many clients through relationships; many journal entries through clients | Name/email presence; email syntax and case-insensitive uniqueness within providers; `NOT NULL` columns and unique `lower(email)` index |
| `Client` | Name, email; many providers through relationships; many journal entries | Same person validations and constraints, with uniqueness within clients |
| `ProviderClientRelationship` | One provider, one client, and that client's plan with that provider | Existing participants required; exactly `basic` or `premium`; unique pair validation; non-null columns, foreign keys and unique `(provider_id, client_id)` index |
| `JournalEntry` | One client, freeform `content` in a text column | Existing client and nonblank content of at least 50 characters; non-null columns and client foreign key |

The plan belongs to the relationship because Sam can have `basic` with Alex
and `premium` with Jordan. There is no default plan. The unique pair index
also prevents duplicate relationships under concurrent writes. Foreign keys
prevent orphan records and parent deletion while dependent records exist;
there is no automatic cascading deletion.

Name/email presence and email syntax keep person records usable. Names may
repeat, and a provider and client may share an email. Email spelling is preserved;
`URI::MailTo::EMAIL_REGEXP` checks syntax, not ownership or deliverability.
The journal's 50-character minimum follows the assignment; whitespace-only text
is rejected, multiline text is preserved, and no maximum or normalization is
imposed. Model validations provide useful errors; database constraints protect
integrity even under races. Bulk writes bypass model checks for blank strings,
email syntax, plan values and content length.

The person-constraint migration stops on existing invalid or duplicate data
without rewriting it. Correct that data deliberately before retrying
`db:prepare`; see [.docs/database.md](.docs/database.md).

- Unique `(provider_id, client_id)` supports a provider's membership lookup;
  its leading column makes another provider-only index redundant. The separate
  `client_id` relationship index supports the reverse lookup.
- `(client_id, created_at, id)` on journal entries supports client history,
  including reverse scans for descending order, and client foreign-key lookup.
- `(created_at, id)` on journal entries offers a global ordered scan. Provider
  history also needs membership joins; the planner may choose client lookups
  followed by a sort instead, depending on selectivity.
- Unique `lower(email)` indexes enforce case-insensitive person uniqueness
  within each table, including concurrent writes.

At larger scale, inspect `relation.explain` and representative query plans
before adding indexes: each index costs storage and write work. Bound results
with SQL filters/limits; a future pagination interface can use `(created_at, id)`
as a stable cursor rather than large offsets. Use `includes` when iterating
records and reading associated people to avoid N+1 queries. SQLite allows one
writer at a time, so keep transactions short and measure contention. Pagination
and additional indexes are considerations here, not implemented features.

## Verify and extend

```sh
bin/check
```

This forces `RAILS_ENV=test`, clears database connection overrides and stale
coverage, prepares `db/test.sqlite3`, then runs RuboCop, RSpec, strict Cucumber,
fresh **100% line and 100% branch coverage** across all app/lib Ruby files, and
`bundler-audit check --update` with current advisory data. Internet access is
needed for the advisory update. Test cleanup uses isolated test data.
Keep `Gemfile.lock` committed. Before a code commit, safely autocorrect owned
Ruby files with `bundle exec rubocop --autocorrect <paths>`, then rerun `bin/check`.
Follow [AGENTS.md](AGENTS.md) and [.docs/agent-workflow.md](.docs/agent-workflow.md)
when extending behavior.

To rehearse setup and the console examples without changing development data,
use a fresh local database in another terminal (macOS/Linux):

```sh
export RAILS_ENV=development
unset DATABASE_URL PRIMARY_DATABASE_URL
export DATABASE_PATH="$(mktemp -d)/journal.sqlite3"
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails console
# Paste the query block above, then exit.
bin/rails server -b 127.0.0.1 -p 4000
# Check /health, then stop with Ctrl-C.
unset DATABASE_PATH
```

The temporary database contains only synthetic records. `bin/check` always
selects its separate test database, even from this terminal.

The requested data-model foundation is complete. Authentication, authorization,
a journal HTTP/UI workflow and pagination are not implemented. Request and
Active Record attribute logging filter names, emails and journal content;
keep new logs free of personal data and journal text. Production deployment,
backups and migration/rollback details live in
[.docs/deployment.md](.docs/deployment.md) and [.docs/database.md](.docs/database.md).
