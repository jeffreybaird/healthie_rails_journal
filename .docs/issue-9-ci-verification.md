# Issue #9 fresh-database CI correction

PR #20's first GitHub Actions run failed its test job before build/deploy.
Rails `db:prepare` loads seeds when creating a new database. RSpec's per-example
transaction cleanup preserved these initial records, so assertions expecting an
empty database saw the synthetic seed rows. The original local verification
used an existing database and missed the startup condition.

Added a suite-start `DatabaseCleaner.clean_with(:deletion)` in
`spec/rails_helper.rb`. `spec_helper.rb` forces `RAILS_ENV=test` and clears
`DATABASE_PATH`, `DATABASE_URL`, and `PRIMARY_DATABASE_URL` before Rails loads;
cleanup therefore targets the isolated test database. Per-example cleanup remains
unchanged. Seed behavior and all model/query assertions remain unchanged.

## Workflow and verification

The runner backed up only the isolated test database under
`/tmp/issue9-ci/backup/`, recreated it using `db:prepare`, and reproduced red:
35 relationship examples, 18 failures caused by four preloaded relationships.
The reviewer accepted these existing assertions and the required fresh-database
run as the regression contract before the test writer changed the harness.
All 13 accepted regression-file hashes remain unchanged. The owner safely
corrected the helper and read-only lint passed. No tests were removed or weakened.

Focused green started with the contaminated database: 55 RSpec examples passed;
4 strict Cucumber scenarios / 31 steps passed. The runner then removed only the
isolated test database and ran the full `bin/check` from scratch: RuboCop 56 files
clean, RSpec 196 examples / 0 failures, Cucumber 59 scenarios / 256 steps passed,
fresh unchanged coverage gate passed (31/31 app/lib lines; no branch targets),
and current bundler-audit found no vulnerabilities among 1,263 advisories.
The full gate exited 0. No green tests were skipped or pending.

Runtime remains Ruby 3.3.12 with `BUNDLE_PATH=vendor/bundle`; all database runs
force test environment and clear inherited connection overrides. Development and
deployed data were not used. The failed GitHub log is preserved at
`/tmp/issue9-ci/gh-run-failed-escalated.log`; red output at
`/tmp/issue9-ci/red.log`; full green gate at `/tmp/issue9-ci/bin-check-fresh.log`.

The independent audit refreshed advisory DB commit
`a6847b0651a702488f5844081e848dd1ec9dbf1d` (updated 2026-10-10) and found no
vulnerabilities, including pre-existing dependencies. Evidence:
`/tmp/issue9-ci/security-review.log`. No dead code was found or removed; the
suite-start hook and per-example cleanup serve distinct startup/isolation paths.
Independent final review is retained at `/tmp/issue9-ci/final-review.md`.

The mutation audit includes an ambiguous reviewer row attributed to the helper
change while its security-audit command overlapped the spec writer's explicit
patch. The reviewer correlated the overlapping calls and confirmed the writer
owned the edit; the reviewer made no test mutation. This resolved overlap is
retained in the audit, rather than suppressed.

## Actual focused RSpec evidence

```text
COMMAND: PATH=/Users/jeffreybaird/.rubies/ruby-3.3.12/bin:$PATH BUNDLE_PATH=vendor/bundle RAILS_ENV=test (unset DATABASE_PATH DATABASE_URL PRIMARY_DATABASE_URL) bundle exec rspec spec/models/provider_client_relationship_spec.rb spec/seeds/sample_data_spec.rb --format documentation
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:7:in `block in <top (required)>': [DEPRECATION] `SimpleCov.track_files` is deprecated. Replace with `SimpleCov.cover "{app,lib}/**/*.rb"` — `cover` includes unloaded files on disk (the historical `track_files` behavior) and also restricts the report to the matching set. If you want to keep additional files outside "{app,lib}/**/*.rb" in the report, pass every directory you care about, e.g. `cover "{app,lib}/**/*.rb", "app/**/*.rb"`.
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:10:in `block in <top (required)>': [DEPRECATION] `SimpleCov.add_filter` is deprecated. Replace with `SimpleCov.skip` (same arguments, same behavior). Example: `SimpleCov.skip { ... }`.

Randomized with seed 47691

SampleData
  the initial dataset
    gives the shared client different plans with each provider
    persists eight fictional entries with explicit dates and stable insertion order for ties
    creates two named providers and four named clients at reserved synthetic addresses
  safe repeated loads
    preserves every record, ID and timestamp when run twice
    with existing records outside the sample dataset
      preserves existing people, relationships, journal text, IDs and timestamps
    with customized sample values
      preserves the restored sample and edited note on later reruns
      restores the original sample as a separate record without rewriting the edited note
      retains every edited attribute when the seeds run again
    with case variants of reserved addresses
      creates the missing samples without duplicating case variants
      reuses existing records without changing their names, email spelling, plan or timestamps
  client and provider history queries
    returns all shared client entries newest first with later IDs first on equal dates
    returns Jordan's globally ordered history and excludes other clients
    returns exactly Taylor's newest-first history
    returns Alex's globally ordered history once per entry and excludes other clients
    keeps the unrelated client's history available through its own client query
    returns exactly Riley's history
  provider and client membership queries
    returns exactly Alex's clients as a composable relation
    returns both of the shared client's providers as a composable relation
    returns exactly Jordan's clients
    returns exactly the exclusive clients' providers and leaves the unrelated client unassigned

ProviderClientRelationship
  database constraints
    rejects null plan when validation is bypassed
    rejects null client_id when validation is bypassed
    prevents deleting a client referenced by a relationship
    prevents deleting a provider referenced by a relationship
    enforces the client foreign key when validation is bypassed
    enforces the provider foreign key when validation is bypassed
    rejects null provider_id when validation is bypassed
  persistence
    stores a premium plan on the provider-client relationship
    stores a basic plan on the provider-client relationship
  plan validation
    rejects "BASIC" as a plan without persisting
    rejects "enterprise" as a plan without persisting
    rejects an omitted plan rather than selecting a default
    rejects "" as a plan without persisting
    rejects nil as a plan without persisting
    rejects " basic " as a plan without persisting
  required associations
    belongs to a client
    rejects a missing client
    rejects a provider ID that does not exist
    rejects a client ID that does not exist
    rejects a missing provider
    belongs to a provider
  one relationship per provider-client pair
    has a unique composite index covering both relationship IDs
    enforces pair uniqueness when model validation is bypassed
    rejects a duplicate pair even when the attempted plan differs
    allows another client to have a relationship with the same provider
  bidirectional collections
    returns empty collections for people without relationships
    declares Client's direct relationship collection
    declares Provider's direct relationship collection
    declares Provider's clients as a has-many-through collection
    declares Client's providers as a has-many-through collection
    with a shared client and an unrelated relationship
      scopes each client's providers to that client's relationships
      scopes each provider's clients to that provider's relationships
      exposes each client's own relationship records
      stores a different plan for each provider of the same client
      exposes each provider's own relationship records

Finished in 0.47901 seconds (files took 1.38 seconds to load)
55 examples, 0 failures

Randomized with seed 47691


EXIT STATUS: 0

```

## Actual focused Cucumber evidence

Feature `features/sample_seeds.feature`, strict pretty output:

```text
COMMAND: PATH=/Users/jeffreybaird/.rubies/ruby-3.3.12/bin:$PATH BUNDLE_PATH=vendor/bundle RAILS_ENV=test (unset DATABASE_PATH DATABASE_URL PRIMARY_DATABASE_URL) bundle exec cucumber features/sample_seeds.feature --format pretty --strict
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:7:in `block in <top (required)>': [DEPRECATION] `SimpleCov.track_files` is deprecated. Replace with `SimpleCov.cover "{app,lib}/**/*.rb"` — `cover` includes unloaded files on disk (the historical `track_files` behavior) and also restricts the report to the matching set. If you want to keep additional files outside "{app,lib}/**/*.rb" in the report, pass every directory you care about, e.g. `cover "{app,lib}/**/*.rb", "app/**/*.rb"`.
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:10:in `block in <top (required)>': [DEPRECATION] `SimpleCov.add_filter` is deprecated. Replace with `SimpleCov.skip` (same arguments, same behavior). Example: `SimpleCov.skip { ... }`.
Feature: Load synthetic sample data for the Rails console
  A developer can load a small fictional dataset and demonstrate the four queries.
  Repeating the load preserves existing records and their customized values.

  Background:                               # features/sample_seeds.feature:5
    Given I load the synthetic sample seeds # features/step_definitions/sample_seed_steps.rb:7

  Scenario: Demonstrate all provider and client memberships                          # features/sample_seeds.feature:8
    When I query sample provider "alex" clients                                      # features/step_definitions/sample_seed_steps.rb:15
    Then the sample relation contains exactly these clients:                         # features/step_definitions/sample_seed_steps.rb:31
      | key    |
      | sam    |
      | taylor |
    When I query sample provider "jordan" clients                                    # features/step_definitions/sample_seed_steps.rb:15
    Then the sample relation contains exactly these clients:                         # features/step_definitions/sample_seed_steps.rb:31
      | key   |
      | riley |
      | sam   |
    When I query sample client "sam" providers                                       # features/step_definitions/sample_seed_steps.rb:19
    Then the sample relation contains exactly these providers:                       # features/step_definitions/sample_seed_steps.rb:36
      | key    |
      | alex   |
      | jordan |
    And sample client "sam" has plan "basic" with "alex" and "premium" with "jordan" # features/step_definitions/sample_seed_steps.rb:51
    When I query sample client "unrelated" providers                                 # features/step_definitions/sample_seed_steps.rb:19
    Then the sample relation is empty                                                # features/step_definitions/sample_seed_steps.rb:46

  Scenario: Demonstrate client history and global provider history with stable timestamp ties # features/sample_seeds.feature:28
    When I query sample client "sam" journal history                                          # features/step_definitions/sample_seed_steps.rb:23
    Then the sample relation contains exactly these entries in order:                         # features/step_definitions/sample_seed_steps.rb:41
      | label          |
      | sam-tie-second |
      | sam-tie-first  |
      | sam-middle     |
      | sam-oldest     |
    When I query sample provider "alex" journal history                                       # features/step_definitions/sample_seed_steps.rb:27
    Then the sample relation contains exactly these entries in order:                         # features/step_definitions/sample_seed_steps.rb:41
      | label          |
      | taylor-newest  |
      | sam-tie-second |
      | sam-tie-first  |
      | taylor-tie     |
      | sam-middle    |
      | sam-oldest    |
    When I query sample provider "jordan" journal history                                     # features/step_definitions/sample_seed_steps.rb:27
    Then the sample relation contains exactly these entries in order:                         # features/step_definitions/sample_seed_steps.rb:41
      | label          |
      | riley-newest   |
      | sam-tie-second |
      | sam-tie-first  |
      | sam-middle     |
      | sam-oldest     |
    When I query sample client "unrelated" journal history                                    # features/step_definitions/sample_seed_steps.rb:23
    Then the sample relation contains exactly these entries in order:                         # features/step_definitions/sample_seed_steps.rb:41
      | label            |
      | unrelated-newest |

  Scenario: Repeat the seed load without duplicating or changing persisted records # features/sample_seeds.feature:58
    Given I remember the sample database records                                   # features/step_definitions/sample_seed_steps.rb:59
    When I load the synthetic sample seeds again                                   # features/step_definitions/sample_seed_steps.rb:11
    Then all remembered database records are unchanged                             # features/step_definitions/sample_seed_steps.rb:63

  Scenario: Preserve existing customized records while restoring missing synthetic entries # features/sample_seeds.feature:63
    Given I customize a sample provider, client, plan and journal entry                    # features/step_definitions/sample_seed_steps.rb:67
    When I load the synthetic sample seeds again                                           # features/step_definitions/sample_seed_steps.rb:11
    Then the customized records retain all their stored attributes                         # features/step_definitions/sample_seed_steps.rb:72
    And the original synthetic journal entry is restored as a separate record              # features/step_definitions/sample_seed_steps.rb:76
    Given I remember the sample database records                                           # features/step_definitions/sample_seed_steps.rb:59
    When I load the synthetic sample seeds again                                           # features/step_definitions/sample_seed_steps.rb:11
    Then all remembered database records are unchanged                                     # features/step_definitions/sample_seed_steps.rb:63

4 scenarios (4 passed)
31 steps (31 passed)
0m0.142s
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

EXIT STATUS: 0

```
