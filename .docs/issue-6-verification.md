# Issue #6 verification

`Client#providers` uses the existing `has_many :through` association. No new
scope or application change is needed. The new model specs and Cucumber
scenarios assert exact membership across basic and premium plans, shared
providers, unrelated providers, composable filtering and ordering, and empty
relations. The README adds a repeatable synthetic Rails-console example.

## Workflow and evidence

The spec writer safely autocorrected owned Ruby tests. The runner recorded
35 passing focused RSpec examples and three passing Cucumber scenarios (21
steps) before implementation. Existing behavior already satisfies the issue;
no failing red result was manufactured. The independent reviewer accepted the
tests, and their SHA-256 hashes were frozen before final verification. No tests
were deleted or weakened. No source edits were required.

The README example ran twice against an isolated temporary test database,
asserting exact output, relation type, and transaction rollback without leaked
records. Commands clear inherited database overrides. Development and deployed
data were not used. Evidence is in `/tmp/issue6-docs/verification.log`.

Dead-code review checked the public model associations, relationship model
validations, and Rails migration/schema entry points. No confirmed dead code
was found or removed. The native audit log records role-owned test changes;
its new entries have no ownership violations.

Runtime: Ruby 3.3.12, Bundler 2.5.22, with
`/Users/jeffreybaird/.rubies/ruby-3.3.12/bin` prepended to PATH and
`BUNDLE_PATH=vendor/bundle`. Full workflow logs and accepted hashes are in
`/private/tmp/healthie-issue-6/`; test correction evidence is in
`/tmp/issue-6-client-providers/spec-autocorrect-final.log`.

## Focused RSpec evidence

Command: `bundle exec rspec spec/models/client_spec.rb --format documentation`.

```text
$ unset DATABASE_PATH DATABASE_URL PRIMARY_DATABASE_URL; env PATH=/Users/jeffreybaird/.rubies/ruby-3.3.12/bin:$PATH BUNDLE_PATH=vendor/bundle RAILS_ENV=test bundle exec rspec spec/models/client_spec.rb --format documentation
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:7:in `block in <top (required)>': [DEPRECATION] `SimpleCov.track_files` is deprecated. Replace with `SimpleCov.cover "{app,lib}/**/*.rb"` — `cover` includes unloaded files on disk (the historical `track_files` behavior) and also restricts the report to the matching set. If you want to keep additional files outside "{app,lib}/**/*.rb" in the report, pass every directory you care about, e.g. `cover "{app,lib}/**/*.rb", "app/**/*.rb"`.
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:10:in `block in <top (required)>': [DEPRECATION] `SimpleCov.add_filter` is deprecated. Replace with `SimpleCov.skip` (same arguments, same behavior). Example: `SimpleCov.skip { ... }`.

Randomized with seed 25314

Client
  behaves like a person record
    rejects nil email without persistence
    rejects whitespace name without persistence
    persists a representative name and email with Rails timestamps
    rejects omitted name and email without persistence
    updates stored attributes and updated_at while preserving created_at
    rejects omitted name without persistence
    uses the application's ordinary Active Record persistence base
    rejects omitted email without persistence
    rejects nil name without persistence
    rejects different records sharing an email address
    rejects blank email without persistence
    rejects whitespace email without persistence
    rejects blank name and email without persistence
    rejects an email without valid syntax without persistence
    rejects blank name without persistence
    database integrity when validations are bypassed
      rejects duplicate email renee@example.test at the database boundary
      rejects a null name
      rejects duplicate email RENEE@EXAMPLE.TEST at the database boundary
      rejects a null email
    email syntax
      accepts representative valid email first.last@example.test
      rejects malformed email "@example.test"
      accepts representative valid email alex+weekly@care.example.test
      rejects malformed email "alex@"
      rejects malformed email "alex@example.test\n"
      rejects malformed email "alex rivera@example.test"
    email uniqueness within each model
      rejects changing an email to another person's case variant
      allows different people to share a name
      rejects a case variant of an existing email
      allows an existing person to update while keeping its email
      allows an existing person to change only its email case
      allows the same email in the other person model
  #providers
    with shared, exclusive and unrelated providers
      returns every associated provider regardless of plan and excludes unrelated providers
      returns a composable Active Record relation
      composes filtering and ordering while preserving the client boundary
    without relationships
      returns an empty relation that can still be filtered and ordered

Finished in 0.16506 seconds (files took 1.11 seconds to load)
35 examples, 0 failures

Randomized with seed 25314

```

## Focused Cucumber evidence

Command: `bundle exec cucumber features/client_providers.feature --format pretty --strict`.

```text
$ unset DATABASE_PATH DATABASE_URL PRIMARY_DATABASE_URL; env PATH=/Users/jeffreybaird/.rubies/ruby-3.3.12/bin:$PATH BUNDLE_PATH=vendor/bundle RAILS_ENV=test bundle exec cucumber features/client_providers.feature --format pretty --strict
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:7:in `block in <top (required)>': [DEPRECATION] `SimpleCov.track_files` is deprecated. Replace with `SimpleCov.cover "{app,lib}/**/*.rb"` — `cover` includes unloaded files on disk (the historical `track_files` behavior) and also restricts the report to the matching set. If you want to keep additional files outside "{app,lib}/**/*.rb" in the report, pass every directory you care about, e.g. `cover "{app,lib}/**/*.rb", "app/**/*.rb"`.
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:10:in `block in <top (required)>': [DEPRECATION] `SimpleCov.add_filter` is deprecated. Replace with `SimpleCov.skip` (same arguments, same behavior). Example: `SimpleCov.skip { ... }`.
Feature: Retrieve a client's providers
  A client can retrieve all associated providers as a composable query.
  Basic and premium plans both belong in the result, while unrelated providers stay outside it.

  Background:                                         # features/client_providers.feature:5
    Given the following relationship providers exist: # features/step_definitions/provider_client_relationship_steps.rb:21
      | name          |
      | Alex Morgan   |
      | Jordan Lee    |
      | Taylor Reed   |
      | Riley Example |
    And the following relationship clients exist:     # features/step_definitions/provider_client_relationship_steps.rb:27
      | name          |
      | Sam Rivera    |
      | Avery Example |

  Scenario: Retrieve providers on both plans without unrelated providers            # features/client_providers.feature:17
    When provider "Alex Morgan" enrolls client "Sam Rivera" on the "basic" plan     # features/step_definitions/provider_client_relationship_steps.rb:33
    And provider "Jordan Lee" enrolls client "Sam Rivera" on the "premium" plan     # features/step_definitions/provider_client_relationship_steps.rb:33
    And provider "Alex Morgan" enrolls client "Avery Example" on the "premium" plan # features/step_definitions/provider_client_relationship_steps.rb:33
    And provider "Riley Example" enrolls client "Avery Example" on the "basic" plan # features/step_definitions/provider_client_relationship_steps.rb:33
    Then client "Sam Rivera" has exactly these providers:                           # features/step_definitions/provider_client_relationship_steps.rb:80
      | name        |
      | Alex Morgan |
      | Jordan Lee  |

  Scenario: Filter and order associated providers                                                    # features/client_providers.feature:27
    When provider "Alex Morgan" enrolls client "Sam Rivera" on the "basic" plan                      # features/step_definitions/provider_client_relationship_steps.rb:33
    And provider "Jordan Lee" enrolls client "Sam Rivera" on the "premium" plan                      # features/step_definitions/provider_client_relationship_steps.rb:33
    And provider "Taylor Reed" enrolls client "Sam Rivera" on the "basic" plan                       # features/step_definitions/provider_client_relationship_steps.rb:33
    And provider "Alex Morgan" enrolls client "Avery Example" on the "premium" plan                  # features/step_definitions/provider_client_relationship_steps.rb:33
    And provider "Riley Example" enrolls client "Avery Example" on the "basic" plan                  # features/step_definitions/provider_client_relationship_steps.rb:33
    And I filter client "Sam Rivera" providers to these names in descending name order:              # features/step_definitions/client_provider_steps.rb:3
      | name          |
      | Alex Morgan   |
      | Taylor Reed   |
      | Riley Example |
    Then the provider query returns an Active Record relation with exactly these providers in order: # features/step_definitions/client_provider_steps.rb:8
      | name        |
      | Taylor Reed |
      | Alex Morgan |

  Scenario: Query a client with no relationships                                        # features/client_providers.feature:43
    When provider "Alex Morgan" enrolls client "Avery Example" on the "basic" plan      # features/step_definitions/provider_client_relationship_steps.rb:33
    And I filter client "Sam Rivera" providers to these names in descending name order: # features/step_definitions/client_provider_steps.rb:3
      | name        |
      | Alex Morgan |
    Then the provider query returns an empty Active Record relation                     # features/step_definitions/client_provider_steps.rb:15

3 scenarios (3 passed)
21 steps (21 passed)
0m0.051s
┌──────────────────────────────────────────────────────────────────────────────┐
│ Share your Cucumber Report with your team at https://reports.cucumber.io     │
│                                                                              │
│ Command line option:    --publish                                            │
│ Environment variable:   CUCUMBER_PUBLISH_ENABLED=true                        │
│ cucumber.yml:           default: --publish                                   │
│                                                                              │
│ More information at https://cucumber.io/docs/cucumber/environment-variables/ │
│                                                                              │
│ To disable this message, specify CUCUMBER_PUBLISH_QUIET=true or use the      │
│ --publish-quiet option. You can also add this to your cucumber.yml:          │
│ default: --publish-quiet                                                     │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Accepted test hashes

```text
dc006f73ccc336770218bed458e59988343aa2f45016739fbf01e03aca7a3ded  spec/models/client_spec.rb
482d41320683deaa304d29385c5ae9bcf9e3cb605f4ba7d1829705c7813a7e94  features/client_providers.feature
a04ced0ca324f0e2af77df92fdc5c375fc5edca491f51fe21708f7690e38a2a7  features/step_definitions/client_provider_steps.rb
```

## Full quality gate

Final `bin/check` exited 0: RuboCop inspected 48 files with no offenses,
RSpec passed 165 examples with zero failures, strict Cucumber passed 48
scenarios and 189 steps, and fresh combined coverage passed the unchanged
100% line and 100% branch gates (29/29 executable lines). No skipped or
pending cases remain. Accepted test hashes were unchanged after the gate.

The first sandbox run reached coverage but could not refresh the advisory
database due to filesystem permissions. The runner reran the complete gate
with native permission; no checks were suppressed. Full successful evidence:
`/private/tmp/healthie-issue-6/bin-check-escalated.log`.

`bundle exec bundler-audit check --update` refreshed ruby-advisory-db
(commit `a6847b0651a702488f5844081e848dd1ec9dbf1d`, 1263 advisories,
last updated 2026-10-10) and found no vulnerabilities, including pre-existing
findings. Existing SimpleCov deprecation warnings remain visible in logs.

Independent final review approved the complete diff and full evidence with no
material findings. Accepted hashes stayed unchanged; the current security audit
was clean and no dead code was found. Full review:
`/private/tmp/healthie-issue-6/final-review.md`.
