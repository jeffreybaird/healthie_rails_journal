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

## Workflow, dead-code and security review

The creation migration exclusively creates the retired Notes/audit tables and
is removed at the user's request. The cleanup migration remains a live deployment
entry point. No additional tests were deleted; the previously approved removals
are documented in [issue-1-verification.md](issue-1-verification.md).

The test writer added seven regression examples using real isolated SQLite
connections and Rails MigrationContext. The runner recorded 7 examples/7 expected
failures before implementation (missing target migration and obsolete snapshot).
Independent review accepted tests before source changes. All prior test hashes
were preserved; source and test owners separately ran safe RuboCop autocorrection.
No coverage thresholds, exclusions or lint cops were changed.

Independent review reconciled the native audit's overlapping main-session PR
read with the implementer's migration patch. No unauthorized source/test edits
were identified.

Focused RSpec: 20 examples, 0 failures. Strict Cucumber: 5 scenarios and 12 steps,
all passed. Final `bin/check` exited 0: RuboCop 27 files/no offenses, RSpec 20/0,
Cucumber 5/5, fresh combined coverage 100% line (10/10) and unchanged 100% branch
gate. Application code has no conditional branches. No pending/skipped examples.
Existing SimpleCov deprecation warnings remain.

`bundler-audit check --update` found no new or pre-existing vulnerabilities.
Current advisory DB commit `a6847b0651a702488f5844081e848dd1ec9dbf1d`, updated
2026-10-10, contains 1263 advisories. No dependency versions changed in this
follow-up.

Independent runner verification used `db:prepare` on separate fresh and populated
temporary SQLite files. Fresh history is `20261012000000`; existing history keeps
`20261008000000` and adds `20261012000000`. Both legacy tables and rows disappear,
while an unrelated row and its columns remain intact. Repeated preparation passes.
The repository schema stayed byte-identical during verification.

Evidence directory: `/private/tmp/healthie-issue-1-schema-removal/`. Full logs:
`red-rspec.log`, `green-rspec.log`, `green-cucumber.log`, `green-bin-check.log`,
`db-prepare-*.log`, `db-*-assertions.log`. Runtime: Ruby 3.3.12/Bundler 2.5.22,
`BUNDLE_PATH=vendor/bundle`; database validation overrides point only at that
temporary directory. No development or deployed database was accessed.

## Actual RSpec documentation output

```sh
bundle exec rspec spec/migrations/remove_notes_example_spec.rb spec/models/application_record_spec.rb spec/requests/application_boundary_spec.rb spec/requests/privacy_spec.rb spec/requests/health_spec.rb --format documentation
```

```text
Randomized with seed 29641

RemoveNotesExample
  loads the current schema snapshot without legacy tables
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0002s) ======================

  prepares a fresh database through the current migrations without legacy tables
  with populated legacy tables and unrelated data
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0002s) ======================

    removes both legacy tables while preserving unrelated rows, columns and migration history
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
== 20261012000000 RemoveNotesExample: migrated (0.0002s) ======================

== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0000s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

    can run cleanup again when the tables are already absent
  with only the audit_logs table remaining
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

    removes the remaining legacy table without requiring notes
  with only the notes table remaining
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

    removes the remaining legacy table without requiring audit_logs

Health
  confirms the database is reachable
  keeps the alternate readiness route working

Application boundary
  does not accept former note creation requests
  does not accept former note archive requests
  responds deliberately at the root without rendering a feature
  does not expose the former note list
  removes note controller routes
  removes the note model, controller, services and exclusive audit model

ApplicationRecord
  rejects direct construction of the abstract persistence base

Request parameter privacy
  filters a copy without changing the application's original parameters
  redacts standard credential fields
  redacts nested note content from request logging
  keeps harmless request metadata useful

Finished in 0.25532 seconds (files took 1.63 seconds to load)
20 examples, 0 failures

Randomized with seed 29641
```

## Actual Cucumber scenarios and output

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

  @allow-rescue
  Scenario Outline: Former note endpoints are unavailable # features/application_readiness.feature:15
    When I request "<method>" "<path>"                    # features/application_readiness.feature:16
    Then the HTTP response status is 404                  # features/application_readiness.feature:17

    Examples:
      | method | path             |
      | GET    | /notes           |
      | POST   | /notes           |
      | PATCH  | /notes/1/archive |

5 scenarios (5 passed)
12 steps (12 passed)
0m0.170s
```

## Accepted-test hashes

```text
f01141f47e97026ea735e48f00dc35110ccc926a379c2dccacdec475aef2139b  features/application_readiness.feature
3c310e31223b510216b4662bea19c483d43f9a7c7a86086b941ddf791494f97a  features/step_definitions/application_steps.rb
387ad8b1deec1f81e9eacb7125779e87ce819fb3d3ab6613a298b44fe4fd970f  features/support/env.rb
0a2e14b219271930a6f6dc6591a25bf3f60e28fd6854b6bcae6ff6be3213f9f2  script/coverage.rb
2267e4b3f5afad85ed0f8da26324b044590382220a8cb80b713b6672a5acd47c  spec/migrations/remove_notes_example_spec.rb
d83e7318feb7a297f5cafe3a01ca84a9bf42093789cfbefa528573bcb6c3db56  spec/models/application_record_spec.rb
4505216a02c5416146b8b6192374397415f882d63fd47ddb79103fbab2458e19  spec/rails_helper.rb
9d97371dc20355e51435e4c1dbb68c19d2db2ea36ebf47ea68522aad63631708  spec/requests/application_boundary_spec.rb
1c094fdc022eb6a74bee3a35a494d2e732cff7c207f0fda65e6e8cdefb95f6d7  spec/requests/health_spec.rb
403444a4a7222639d1b032c1be96f524269d46d5c1c05c1a37e42d834e1d52a2  spec/requests/privacy_spec.rb
cc72adddfafb5217fd9c43469c9df3e1ceedaf1b18b1f2c554abb3ed94416596  spec/spec_helper.rb
698cc9a28372947e71d0d43d8a6bd90167082947dc8e667a7a58be44aa16a95c  support/coverage.rb
```
