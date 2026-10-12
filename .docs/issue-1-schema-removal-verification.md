# Issue #1 schema removal verification

This follow-up supersedes the initial commit's legacy-table preservation. The
user explicitly authorized it on 2026-10-12: “Add a commit to remove the notes
migration - it can be removed from prod as well.” No live production operation
was performed; deployment applies the cleanup through `db:prepare`.

## Final behavior and rollout

Removed `20261008000000_create_notes.rb` and both tables from the schema snapshot.
Added `20261012000000_remove_notes_example.rb`: `up` drops `notes` and `audit_logs`
with `if_exists: true`, including their stored rows. Fresh databases do not create
these tables; existing migration history and unrelated data remain intact.
Repeating cleanup or starting with either table absent is safe.

`down` raises `ActiveRecord::IrreversibleMigration`; deleted data cannot be
recovered by rolling back the migration or image. Notes-enabled older images
are incompatible after cleanup. If production still serves Notes, deploy
runtime-removal commit `3dac04c` first. It remains a compatible image rollback
target. Any recovery of erased content requires a verified backup.

## Workflow, dead-code and test-scope review

The creation migration exclusively creates the retired Notes/audit tables and
was removed at the user's request. The cleanup migration remains a live deployment
entry point. The original approved Notes test removals are documented in
[issue-1-verification.md](issue-1-verification.md).

The migration change initially added seven regression examples using real
isolated SQLite connections and Rails MigrationContext. The runner recorded
7 examples/7 expected failures before implementation; independent review
accepted tests before source changes. That commit passed 20 specs and 5 Cucumber
scenarios. Native audit overlap between a PR read and the implementer's patch was
reviewed; no unauthorized source/test edits were identified.

The user then explicitly requested: “Also, remove tests that confirm the non
existence of notes.” A concrete four-file unapplied patch was prepared, independently
reviewed and presented before application. The direct request authorized these
scoped removals. Patch SHA-256: `1a308abd13c0fcbe899906521aaef6d15afbf2e6606a017b2d482300d25592c8`.

Removed five request examples checking retired endpoints, routes and constants;
two pure fresh/schema-snapshot absence examples; and the former-endpoint Cucumber
outline (three executed cases), its rescue tag and obsolete exception override.
Retained root HTTP 204, readiness, privacy and abstract-base tests, plus five
migration tests of actual populated/partial cleanup, repetition, irreversible
rollback and preservation of unrelated rows/columns/history.

This was a test-scope revision, with no source behavior change or artificial red
phase. The previous suite was green; the revised contract was independently
accepted. Exact patch application was verified with a reverse check. Test-owner
safe RuboCop autocorrection passed without further edits. All other prior test
hashes remained unchanged. No coverage thresholds, exclusions or lint cops changed.

## Final checks and security review

Focused and full RSpec: 13 examples, 0 failures. Strict Cucumber: 2 readiness
scenarios and 6 steps, all passed. Final `bin/check` exited 0: RuboCop 27 files/no
offenses, full RSpec 13/0, Cucumber 2/2, fresh combined coverage 100% line (10/10)
and unchanged 100% branch gate. Application code has no conditional branches.
No pending/skipped examples. Existing SimpleCov deprecation warnings remain.

`bundler-audit check --update` found no new or pre-existing vulnerabilities.
Current advisory DB commit `a6847b0651a702488f5844081e848dd1ec9dbf1d`, updated
2026-10-10, contains 1263 advisories. No dependencies changed in the follow-ups.

The schema-removal runner independently verified `db:prepare` on separate fresh
and populated temporary SQLite files. Fresh history is `20261012000000`; existing
history keeps `20261008000000` and adds `20261012000000`. Both legacy tables and
rows disappear, while an unrelated row and its columns remain intact. Repeated
preparation passes. No schema/source changes were made by the test-only revision.

Latest full logs: `/private/tmp/healthie-issue-1-absence-test-removal/`, including
`focused-rspec.log`, `focused-cucumber.log`, `bin-check.log`, patch and hash
manifests. Original migration red/green/database logs remain under
`/private/tmp/healthie-issue-1-schema-removal/`. Runtime: Ruby 3.3.12/Bundler 2.5.22,
`BUNDLE_PATH=vendor/bundle`; checks use isolated test or temporary SQLite databases.
No development or deployed database was accessed.

## Actual retained RSpec documentation output

```sh
bundle exec rspec spec/migrations/remove_notes_example_spec.rb spec/models/application_record_spec.rb spec/requests/application_boundary_spec.rb spec/requests/privacy_spec.rb spec/requests/health_spec.rb --format documentation
```

```text
Randomized with seed 54132

Application boundary
  responds deliberately at the root without rendering a feature

ApplicationRecord
  rejects direct construction of the abstract persistence base

RemoveNotesExample
  with only the notes table remaining
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0002s) ======================

    removes the remaining legacy table without requiring audit_logs
  with only the audit_logs table remaining
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

    removes the remaining legacy table without requiring notes
  with populated legacy tables and unrelated data
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

== 20261012000000 RemoveNotesExample: reverting ===============================
    rejects rollback explicitly while retaining unrelated data and applied migration history
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0000s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

    can run cleanup again when the tables are already absent
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

    removes both legacy tables while preserving unrelated rows, columns and migration history

Request parameter privacy
  keeps harmless request metadata useful
  filters a copy without changing the application's original parameters
  redacts nested note content from request logging
  redacts standard credential fields

Health
  confirms the database is reachable
  keeps the alternate readiness route working

Finished in 0.05634 seconds (files took 1.22 seconds to load)
13 examples, 0 failures

Randomized with seed 54132
```

## Actual retained Cucumber scenarios and output

```sh
bundle exec cucumber features/application_readiness.feature --format pretty --strict
```

```text
Feature: Application readiness
  Operators can verify that the application and its database are ready.

  Scenario Outline: Check readiness                               # features/application_readiness.feature:4
    When I request "GET" "<path>"                                 # features/application_readiness.feature:5
    Then the HTTP response status is 200                          # features/application_readiness.feature:6
    And the readiness response confirms the database is reachable # features/application_readiness.feature:7

    Examples:
      | path    |
      | /health |
      | /up     |

2 scenarios (2 passed)
6 steps (6 passed)
0m0.011s
```

## Revised accepted-test hashes

```text
487b98b7f2d2777f2c091d0ead43b21b857cf33b1920a38a441353eaf62e246e  features/application_readiness.feature
7a1832f0a2cd75df7c930b0f2bb2cbf569ca1ac39e686533ec24f1afcc8da7fa  features/step_definitions/application_steps.rb
387ad8b1deec1f81e9eacb7125779e87ce819fb3d3ab6613a298b44fe4fd970f  features/support/env.rb
0a2e14b219271930a6f6dc6591a25bf3f60e28fd6854b6bcae6ff6be3213f9f2  script/coverage.rb
a7f3d6bd43eb8f59b872aaa7c76c44bfb10e85966fa6eb3f7661d2be270d5d85  spec/migrations/remove_notes_example_spec.rb
d83e7318feb7a297f5cafe3a01ca84a9bf42093789cfbefa528573bcb6c3db56  spec/models/application_record_spec.rb
4505216a02c5416146b8b6192374397415f882d63fd47ddb79103fbab2458e19  spec/rails_helper.rb
897d0add104414c56b15c842722227d055414411d234b511ef3445ae279dd26e  spec/requests/application_boundary_spec.rb
1c094fdc022eb6a74bee3a35a494d2e732cff7c207f0fda65e6e8cdefb95f6d7  spec/requests/health_spec.rb
403444a4a7222639d1b032c1be96f524269d46d5c1c05c1a37e42d834e1d52a2  spec/requests/privacy_spec.rb
cc72adddfafb5217fd9c43469c9df3e1ceedaf1b18b1f2c554abb3ed94416596  spec/spec_helper.rb
698cc9a28372947e71d0d43d8a6bd90167082947dc8e667a7a58be44aa16a95c  support/coverage.rb
```
