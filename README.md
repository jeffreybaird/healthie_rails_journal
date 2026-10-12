# Healthie Rails Journal

A Rails foundation for the provider/client/journal assignment, using Active
Record, SQLite and Puma. The assignment's models, queries and sample data are
not implemented yet.

```sh
bundle install
bin/rails db:prepare
bin/rails console
bin/rails server -b 0.0.0.0 -p 4000
bin/check
```

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
The original `20261008000000_create_notes.rb` migration is retained unchanged:
fresh setup creates its legacy `notes` and `audit_logs` tables, and existing
databases retain all rows. There are no application consumers of these tables.
Deployment state is unknown, so this cleanup does not rewrite migration history
or discard persisted data. Any later table removal requires a deliberate backup,
retention and rollout plan; see [.docs/database.md](.docs/database.md).

`bin/check` prepares the test database, runs RuboCop, RSpec and strict Cucumber,
then enforces 100% line and branch coverage across all application and library
Ruby files before checking current dependency advisories with bundler-audit.
Coverage results are cleared first; both suites must produce fresh results.
Keep Gemfile.lock committed. Before committing, run safe RuboCop autocorrection
on files you own, then rerun bin/check. Do not disable checks to pass.
