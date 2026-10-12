# Rails service

A Rails application using Active Record, SQLite and Puma. The Notes example
creates, lists and archives notes through domain services and server-rendered ERB.
It records durable audit events and publishes IDs-only notifications after commit.

```sh
bundle install
bin/rails db:prepare
bin/rails server -b 0.0.0.0 -p 4000
bin/check
```

`GET /health` returns HTTP 200 when the database is reachable. Production uses
`SECRET_KEY_BASE`, `DATABASE_PATH=/data/app.db` and `PORT=4000`. SQLite WAL is
replicated by Litestream. Deploy migrations run `bundle exec rails db:prepare`
before the healthy blue/green container receives traffic. Keep migrations
compatible with the previous release; image rollback does not undo migrations.

No Solid Queue, Solid Cache or Solid Cable services/databases are configured.
Add background jobs or extra databases deliberately, with corresponding
deployment and backup changes. See `AGENTS.md` and `.docs/`.

`bin/check` prepares the test database, runs RuboCop, RSpec and strict Cucumber,
then enforces 100% line and branch coverage across all application and library
Ruby files before checking current dependency advisories with bundler-audit.
Coverage results are cleared first; both suites must produce fresh results.
Keep Gemfile.lock committed. Before committing, run safe RuboCop autocorrection
on files you own, then rerun bin/check. Do not disable checks to pass.
