# Staging Compose verification

Failed staging run: https://github.com/jeffreybaird/healthie_rails_journal/actions/runs/38281010781

The image build succeeded; deployment failed in “Registry login + pull new image”:
`service "backup" has neither an image nor a build context specified: invalid compose project`.

The Rails base stack has no backup service. Its old staging overlay supplied
only backup entrypoint/command fields, creating a new service without an image.
Replaced the incompatible override with a neutral `services: {}` overlay.
The unchanged upload flow overwrites the remote `compose.override.yaml`, so
retries also remove stale invalid configuration. Workflow edits are comments
only; parsed YAML semantics are unchanged.

Staging isolation remains its separate Compose project/data volume and copied
Litestream config with a file replica inside `/data/staging-replica`. The
production base stack, remote deployment scripts and application behavior are
unchanged. No manual staging or production operations were performed locally.

## Test contract and review

The test writer added three real Docker Compose configuration regressions. Two
failed with the exact workflow error before implementation; the local replica
invariant passed. Independent review accepted the tests before source changes.
All previous test hashes remained unchanged. Source scope is the overlay and
workflow comments; test scope is the new deployment spec. No tests were deleted.
The removed overlay block was specific to a backup service absent from this Rails
stack; no production service was removed.

The regression invokes `docker compose config --format json` with copied files,
a synthetic `.env`, explicit project/interpolation overrides and tools profile.
It checks valid deployment services, staging-scoped volume and mounted local
replica config. It does not require a Docker daemon, network, registry credentials
or real `.env` file. README documents the Compose CLI prerequisite. Test-owner
safe Ruby autocorrection passed; no Ruby source was changed. Audit entries and
accepted hashes were independently reviewed with no ownership violations.

## Local validation

Focused/full RSpec: 16 examples, 0 failures. Strict Cucumber: 2 readiness scenarios,
6 steps passed. Final `bin/check`: RuboCop 28 files/no offenses, RSpec 16/0,
Cucumber 2/2, fresh 100% line coverage (10/10) and unchanged 100% branch gate; exit 0.
Application code has no conditional branches. No skipped/pending examples;
existing SimpleCov deprecation warnings remain.

Direct base and staging Compose rendering both pass, with and without the tools
profile. With tools enabled, services are app_blue, app_green, db_init, litestream
and migrate. All files/values are synthetic temporary fixtures, with no Docker
daemon or external deployment action. These checks validate configuration;
actual GitHub deployment and health readiness will be verified separately on the PR.

`bundler-audit check --update` found no new or pre-existing vulnerabilities.
Current advisory DB commit `a6847b0651a702488f5844081e848dd1ec9dbf1d`, updated
2026-10-10, contains 1263 advisories. Dependency versions are unchanged.

Full raw evidence: `/private/tmp/healthie-staging-compose-fix/`, including
failed-run.log, red-rspec.log, green-rspec.log, green-cucumber.log, bin-check.log,
compose-commands.txt and rendered Compose JSON/status/assertion files.
Runtime: Ruby 3.3.12, Bundler 2.5.22, Docker Compose 5.1.4; BUNDLE_PATH=vendor/bundle.

## Actual RSpec documentation output

```sh
bundle exec rspec spec/deployment/staging_compose_spec.rb spec/migrations/remove_notes_example_spec.rb spec/models/application_record_spec.rb spec/requests/application_boundary_spec.rb spec/requests/privacy_spec.rb spec/requests/health_spec.rb --format documentation
```

```text
Randomized with seed 50797

ApplicationRecord
  rejects direct construction of the abstract persistence base

Health
  confirms the database is reachable
  keeps the alternate readiness route working

StagingCompose
  renders a valid staging project containing the Rails deployment services
  uses its own data volume and copied Litestream configuration
  replicates staging data to a local directory without a cloud replica

RemoveNotesExample
  with populated legacy tables and unrelated data
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0007s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0003s
== 20261012000000 RemoveNotesExample: migrated (0.0012s) ======================

== 20261012000000 RemoveNotesExample: reverting ===============================
    rejects rollback explicitly while retaining unrelated data and applied migration history
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
== 20261012000000 RemoveNotesExample: migrated (0.0002s) ======================

== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0000s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

    can run cleanup again when the tables are already absent
  with only the notes table remaining
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

    removes the remaining legacy table without requiring audit_logs
  with only the audit_logs table remaining
== 20261012000000 RemoveNotesExample: migrating ===============================
-- drop_table(:notes, {:if_exists=>true})
   -> 0.0001s
-- drop_table(:audit_logs, {:if_exists=>true})
   -> 0.0000s
== 20261012000000 RemoveNotesExample: migrated (0.0001s) ======================

    removes the remaining legacy table without requiring notes

Request parameter privacy
  keeps harmless request metadata useful
  filters a copy without changing the application's original parameters
  redacts standard credential fields
  redacts nested note content from request logging

Application boundary
  responds deliberately at the root without rendering a feature

Finished in 0.85075 seconds (files took 1.08 seconds to load)
16 examples, 0 failures

Randomized with seed 50797
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

2 scenarios (2 passed)
6 steps (6 passed)
0m0.013s
```

## Accepted-test hashes

```text
487b98b7f2d2777f2c091d0ead43b21b857cf33b1920a38a441353eaf62e246e  features/application_readiness.feature
7a1832f0a2cd75df7c930b0f2bb2cbf569ca1ac39e686533ec24f1afcc8da7fa  features/step_definitions/application_steps.rb
387ad8b1deec1f81e9eacb7125779e87ce819fb3d3ab6613a298b44fe4fd970f  features/support/env.rb
0a2e14b219271930a6f6dc6591a25bf3f60e28fd6854b6bcae6ff6be3213f9f2  script/coverage.rb
907907139a13bedb56d0f626d344c54cf8eb3c9368cd1c935e11a1d1eec92e79  spec/deployment/staging_compose_spec.rb
a7f3d6bd43eb8f59b872aaa7c76c44bfb10e85966fa6eb3f7661d2be270d5d85  spec/migrations/remove_notes_example_spec.rb
d83e7318feb7a297f5cafe3a01ca84a9bf42093789cfbefa528573bcb6c3db56  spec/models/application_record_spec.rb
4505216a02c5416146b8b6192374397415f882d63fd47ddb79103fbab2458e19  spec/rails_helper.rb
897d0add104414c56b15c842722227d055414411d234b511ef3445ae279dd26e  spec/requests/application_boundary_spec.rb
1c094fdc022eb6a74bee3a35a494d2e732cff7c207f0fda65e6e8cdefb95f6d7  spec/requests/health_spec.rb
403444a4a7222639d1b032c1be96f524269d46d5c1c05c1a37e42d834e1d52a2  spec/requests/privacy_spec.rb
cc72adddfafb5217fd9c43469c9df3e1ceedaf1b18b1f2c554abb3ed94416596  spec/spec_helper.rb
698cc9a28372947e71d0d43d8a6bd90167082947dc8e667a7a58be44aa16a95c  support/coverage.rb
```
