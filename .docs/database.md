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

The generated Notes runtime is removed, but its original migration
`db/migrate/20261008000000_create_notes.rb` stays unchanged. Its application in
deployed databases cannot be ruled out. Fresh preparation still creates `notes`
and `audit_logs`; existing preparation leaves their schema and rows intact.
Neither table has an application model or runtime consumer in this release.
Keeping the tables also lets a previous application image run during rollout
or rollback without a destructive schema change.

Do not delete local or deployed databases to perform this cleanup. Physical table
retirement is separate work: establish deployment state, back up and verify the
data, decide retention/export requirements, and wait until older images no longer
need the schema before considering a removal migration. This release performs
no automatic erasure or export of persisted content.

Keep local test data isolated. `bin/check` forces `RAILS_ENV=test` and clears
inherited `DATABASE_PATH`, `DATABASE_URL` and `PRIMARY_DATABASE_URL` before any database command. Never
point manual test/cleanup commands at production data.

No Solid Queue, Solid Cache or Solid Cable database is generated. Adding separate
database files requires a reviewed deployment, volume, migration and backup
plan. Uploaded files belong in an explicitly configured object store, not blobs
in this database or an unbacked container directory.
