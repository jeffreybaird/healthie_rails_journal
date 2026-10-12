# Database

Production uses exactly one Active Record SQLite database at
`ENV.fetch("DATABASE_PATH", "/data/app.db")`. WAL journaling, a busy timeout and
foreign-key enforcement are configured in `config/database.yml`. Litestream
backs up this file; it is disaster recovery, not a live read replica.

SQLite permits one writer at a time. Keep transactions short, with no network
calls or slow rendering inside them. Use bound Active Record predicates, indexed
lookups, stable bounded pagination and deliberate eager loading to avoid N+1.
Measure query plans before adding complexity. Bulk APIs can bypass callbacks
and validations: preserve audit and integrity guarantees explicitly.

Models validate user input; database NOT NULL, unique and foreign-key constraints
protect integrity under races. Add indexes matching actual queries. Tenant
uniqueness, when introduced, needs a composite database index as well as model
validation. Never trust a submitted tenant ID.

Create schema changes with Rails migrations and run `bundle exec rails db:prepare`.
Production migration runs before the new image becomes healthy while the old
image may still run. Use additive, backward-compatible changes and staged
backfills. SQLite table rebuilds can lock writes; test realistic migration size.
Image rollback does not undo schema changes or already-applied migrations.

## Retired example data

The generated Notes runtime and original creation migration
`db/migrate/20261008000000_create_notes.rb` are removed. At the user's explicit
request, `20261012000000_remove_notes_example.rb` drops `notes` and `audit_logs`,
including all their rows. This applies to production when deployment runs
`db:prepare`. No live production cleanup was performed while preparing this PR.

Fresh databases never create these tables. Existing databases apply the cleanup
migration; either missing table is harmless. Other tables and existing migration
history are left intact. Do not delete an entire database to perform cleanup.

The cleanup is intentionally irreversible: migration rollback raises
`ActiveRecord::IrreversibleMigration`, and image rollback cannot restore erased
data. Any recovery of old content requires a verified backup. A Notes-enabled
image cannot serve against the cleaned schema, including during a mixed-version
rollout. Deploy the runtime-removal commit `3dac04c` before applying this schema
cleanup if production still serves Notes; that commit is also the earliest
compatible application rollback target. This is an explicitly authorized
exception to the normal additive migration convention.

Keep local test data isolated. `bin/check` forces `RAILS_ENV=test` and clears
inherited `DATABASE_PATH`, `DATABASE_URL` and `PRIMARY_DATABASE_URL` before any database command. Never
point manual test/cleanup commands at production data.

No Solid Queue, Solid Cache or Solid Cable database is generated. Adding separate
database files requires a reviewed deployment, volume, migration and backup
plan. Uploaded files belong in an explicitly configured object store, not blobs
in this database or an unbacked container directory.
