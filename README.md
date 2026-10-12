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
