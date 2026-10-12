# Issue #1 verification

The generated Notes runtime is removed. The root returns an empty HTTP 204;
`/health` and `/up` retain their database readiness response. No provider/client/
journal models or replacement interface are introduced by this cleanup.

## Dead-code review and approved test removals

Reviewed routes, application constants, services, configuration, framework entry
points and repository references. The Notes controller, model, services and view
are exclusive to the retired feature. AuditLog has only Notes service consumers.
Removed these runtime files and the exclusive dry-monads/dry-core dependencies.
Retained Rails base classes, the neutral application layout, shared stylesheet,
privacy filtering and deployment infrastructure as framework/public entry points.

The user explicitly approved the exact unapplied test-removal patch on
2026-10-12, replying “Approve the exact patch.” Its SHA-256 is
`26de75e6f08605dc089673e8060fb8c0aeb71c7cd95e1810526b5ad576f670ef`. The test writer applied it; independent review verified exact
application with a reverse patch check. Approved obsolete files:

- `spec/requests/notes_spec.rb`
- `spec/services/notes/archive_spec.rb`
- `spec/services/notes/create_spec.rb`
- `spec/services/notes/list_spec.rb`
- `spec/support/events.rb`
- `features/notes.feature`
- `features/step_definitions/notes_steps.rb`

The patch also removed EventCapture imports and the mixed privacy spec's obsolete
Notes persistence example. Retained content/credential filtering and metadata
assertions; added an original-parameter nonmutation assertion. New request and
feature tests cover readiness and retired routes. A model regression verifies
that the retained abstract ApplicationRecord rejects direct construction.

The runner recorded meaningful red before implementation: 13 focused examples,
5 failures; 5 Cucumber scenarios, 2 failures. Reviewed fixture correction added
Cucumber's scoped `@allow-rescue` tag to exercise genuine Rails 404 rendering.
HTTP assertions were unchanged. An initial full gate exposed unloaded
ApplicationRecord (80% line coverage); the reviewed abstract-base regression
covers its retained behavior. No thresholds, exclusions or cops were changed.

Native audit violations were independently reviewed: overlapping runner reads
observed the test writer's edits; `db:prepare` generated `db/schema.rb` as a
framework side effect. The implementer reviewed and adopted that schema, applying
only safe formatting. No unauthorized direct source/test edits were identified.

## Database safety

Original migration `20261008000000_create_notes.rb` is unchanged (SHA-256
`d4e10de3ddff296f1736d7d23026b71dddb3924bd37b10d76dc2e45364374f28`).
Historical notes/audit_logs tables intentionally remain, without runtime models
or consumers. Deployment state is unknown; no data is dropped. See database.md.

The runner used separate temporary SQLite databases to verify fresh preparation,
table/column definitions and migration version. A populated database retained
its synthetic note and audit rows after repeated `db:prepare`. Original migration
and adopted schema hashes stayed unchanged. No development/deployed database was
used by these checks.

## Checks and current security advisories

Ruby 3.3.12, Bundler 2.5.22; local execution used `BUNDLE_PATH=vendor/bundle`
and prepended `/Users/jeffreybaird/.rubies/ruby-3.3.12/bin` to PATH. Source and test
owners separately ran safe RuboCop autocorrection before the final gate.

Final `bin/check` exited 0: RuboCop inspected 26 files with no offenses, RSpec
13 examples with no failures, strict Cucumber 5 scenarios/12 steps passed,
fresh combined coverage 100% line and branch (10/10 executable lines), and
`bundler-audit check --update` found no vulnerabilities. No skipped or pending
examples remain. Advisory database commit
`a6847b0651a702488f5844081e848dd1ec9dbf1d`, last updated 2026-10-10,
contained 1263 advisories. No pre-existing or new advisories were reported.
Existing SimpleCov deprecation warnings remain; the enforced gate passed.
The remaining application code has no conditional branches; the branch gate
therefore passes without any branch paths to exercise.

Full runner logs and intermediate failures: `/private/tmp/healthie-issue-1/`.
Relevant final logs are `green-rspec.log`, `green-cucumber.log`,
`green-bin-check.log`, and `db-*.log`.

## Executed RSpec documentation output

Command:

```sh
bundle exec rspec spec/models/application_record_spec.rb spec/requests/application_boundary_spec.rb spec/requests/privacy_spec.rb spec/requests/health_spec.rb --format documentation
```

```text
Randomized with seed 64475

Health
  keeps the alternate readiness route working
  confirms the database is reachable

Application boundary
  does not accept former note archive requests
  responds deliberately at the root without rendering a feature
  does not accept former note creation requests
  removes note controller routes
  does not expose the former note list
  removes the note model, controller, services and exclusive audit model

Request parameter privacy
  redacts nested note content from request logging
  keeps harmless request metadata useful
  filters a copy without changing the application's original parameters
  redacts standard credential fields

ApplicationRecord
  rejects direct construction of the abstract persistence base

Finished in 0.17918 seconds (files took 1.07 seconds to load)
13 examples, 0 failures

Randomized with seed 64475
```

## Executed Cucumber scenario output

Command:

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
0m0.019s
```

## Final accepted-test hashes

Initial hashes were recorded before implementation. The reviewer accepted the
scoped Cucumber fixture correction and additional abstract-base regression;
all other hashes stayed unchanged.

```text
f01141f47e97026ea735e48f00dc35110ccc926a379c2dccacdec475aef2139b  features/application_readiness.feature
3c310e31223b510216b4662bea19c483d43f9a7c7a86086b941ddf791494f97a  features/step_definitions/application_steps.rb
387ad8b1deec1f81e9eacb7125779e87ce819fb3d3ab6613a298b44fe4fd970f  features/support/env.rb
0a2e14b219271930a6f6dc6591a25bf3f60e28fd6854b6bcae6ff6be3213f9f2  script/coverage.rb
4505216a02c5416146b8b6192374397415f882d63fd47ddb79103fbab2458e19  spec/rails_helper.rb
9d97371dc20355e51435e4c1dbb68c19d2db2ea36ebf47ea68522aad63631708  spec/requests/application_boundary_spec.rb
1c094fdc022eb6a74bee3a35a494d2e732cff7c207f0fda65e6e8cdefb95f6d7  spec/requests/health_spec.rb
403444a4a7222639d1b032c1be96f524269d46d5c1c05c1a37e42d834e1d52a2  spec/requests/privacy_spec.rb
cc72adddfafb5217fd9c43469c9df3e1ceedaf1b18b1f2c554abb3ed94416596  spec/spec_helper.rb
698cc9a28372947e71d0d43d8a6bd90167082947dc8e667a7a58be44aa16a95c  support/coverage.rb
d83e7318feb7a297f5cafe3a01ca84a9bf42093789cfbefa528573bcb6c3db56  spec/models/application_record_spec.rb
```
