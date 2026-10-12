# Issue #9 verification

Added `db/seeds.rb` with two fictional providers, four clients, four relationships
and eight explicitly dated journal entries. Sam is shared with different plans;
Taylor and Riley demonstrate exclusive membership, and Unrelated has no provider.
Equal timestamps demonstrate descending ID order. The README identifies each
record, shows all four queries and documents local loading and safe reruns.

Seeds use a single transaction. Case-insensitive email lookup preserves existing
names and stored email spelling; relationship reuse preserves plans. Journal
identity is client/content/created_at. Edited entries remain intact; a missing
original synthetic entry is restored separately. Repeated unedited loads preserve
all attributes, IDs and timestamps. Run loads sequentially.

## Workflow and validation

The spec writer safely corrected owned tests. The runner recorded red: 20 RSpec
examples failed because `db/seeds.rb` was absent; four Cucumber scenarios failed
at the same loader, with 27 later steps skipped. The reviewer accepted and froze
the tests before implementation. The implementer added only `db/seeds.rb` and
safely corrected it, then read-only lint passed. Accepted hashes remain unchanged;
no tests were removed or weakened.

Runtime: Ruby 3.3.12, Bundler 2.5.22, with
`/Users/jeffreybaird/.rubies/ruby-3.3.12/bin` prepended to PATH and
`BUNDLE_PATH=vendor/bundle`. Database checks used `RAILS_ENV=test` and unset
`DATABASE_PATH`, `DATABASE_URL` and `PRIMARY_DATABASE_URL`. Suite runs were
sequential; development and deployed databases were not used.

The actual README seed-console block was executed in a test rollback transaction.
All memberships and ordered histories matched. A repeat load preserved all
attributes; rollback restored the preceding database state. Evidence:
`/tmp/issue9/readme-example.log` and `/tmp/issue9/verify_readme.rb`.

Final `bin/check` exited 0: RuboCop inspected 56 files with no offenses;
RSpec passed 196 examples; strict Cucumber passed 59 scenarios and 256 steps.
Fresh coverage passed the unchanged 100% line and branch gates (31/31 executable
lines). No green examples/scenarios were pending or skipped. Existing SimpleCov
deprecation warnings remain in the logs. Full evidence:
`/tmp/issue9/bin-check-rerun.log`.

The initial gate passed suites and coverage but failed to refresh the advisory
cache because the sandbox could not write `.git/FETCH_HEAD`. The full gate was
rerun with native elevated permission; no checks were bypassed. Failed evidence
is retained at `/tmp/issue9/bin-check.log`.

`bundle exec bundler-audit check --update` refreshed advisory data (commit
`a6847b0651a702488f5844081e848dd1ec9dbf1d`, 1263 advisories, last updated
2026-10-10) and found no vulnerabilities, including pre-existing dependencies.
Separate review audit evidence: `/tmp/issue9/security-review.log`.

## Independent review and dead code

The reviewer accepted the test contract and inspected source, README, correction
logs and mutation audit. No dead code or obsolete tests were identified. The
Rails `db:seed` entry point uses all added data; existing associations/scopes stay
live. Added audit entries have no ownership violations. Historical ambiguous
violation entries are unchanged. Full final review is retained at
`/tmp/issue9/final-review.md`.

## Focused RSpec evidence

Actual documentation output:

```text
COMMAND: PATH=/Users/jeffreybaird/.rubies/ruby-3.3.12/bin:$PATH BUNDLE_PATH=vendor/bundle RAILS_ENV=test (unset DATABASE_PATH DATABASE_URL PRIMARY_DATABASE_URL) bundle exec rspec --format documentation spec/seeds/sample_data_spec.rb
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:7:in `block in <top (required)>': [DEPRECATION] `SimpleCov.track_files` is deprecated. Replace with `SimpleCov.cover "{app,lib}/**/*.rb"` — `cover` includes unloaded files on disk (the historical `track_files` behavior) and also restricts the report to the matching set. If you want to keep additional files outside "{app,lib}/**/*.rb" in the report, pass every directory you care about, e.g. `cover "{app,lib}/**/*.rb", "app/**/*.rb"`.
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:10:in `block in <top (required)>': [DEPRECATION] `SimpleCov.add_filter` is deprecated. Replace with `SimpleCov.skip` (same arguments, same behavior). Example: `SimpleCov.skip { ... }`.

Randomized with seed 1032

SampleData
  provider and client membership queries
    returns exactly the exclusive clients' providers and leaves the unrelated client unassigned
    returns exactly Alex's clients as a composable relation
    returns exactly Jordan's clients
    returns both of the shared client's providers as a composable relation
  client and provider history queries
    returns exactly Taylor's newest-first history
    returns Alex's globally ordered history once per entry and excludes other clients
    returns exactly Riley's history
    keeps the unrelated client's history available through its own client query
    returns Jordan's globally ordered history and excludes other clients
    returns all shared client entries newest first with later IDs first on equal dates
  the initial dataset
    creates two named providers and four named clients at reserved synthetic addresses
    gives the shared client different plans with each provider
    persists eight fictional entries with explicit dates and stable insertion order for ties
  safe repeated loads
    preserves every record, ID and timestamp when run twice
    with customized sample values
      retains every edited attribute when the seeds run again
      preserves the restored sample and edited note on later reruns
      restores the original sample as a separate record without rewriting the edited note
    with case variants of reserved addresses
      reuses existing records without changing their names, email spelling, plan or timestamps
      creates the missing samples without duplicating case variants
    with existing records outside the sample dataset
      preserves existing people, relationships, journal text, IDs and timestamps

Finished in 0.37664 seconds (files took 1.32 seconds to load)
20 examples, 0 failures

Randomized with seed 1032


EXIT STATUS: 0

```

## Focused Cucumber evidence

Feature: `features/sample_seeds.feature`. Actual strict pretty output:

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
0m0.096s
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

## Accepted test hashes

```text
e85077bbac05555b85d6f71fbedd57c9ee964a0387d9e15a047d0315a1d970c5  spec/seeds/sample_data_spec.rb
b610f54f5404df02e68101a96138ffca58b560c4275d71feb81e35d68fc050f7  features/sample_seeds.feature
dd96f4163f511f946a6e4fc9f5451bd3068c050221bffda0fa43aef8d3943714  spec/support/sample_seed_contract.rb
8753df579bfee5cacd5dfb3cb54d60083995ee8e4b9050b2a3676b7cc2fa42e1  features/step_definitions/sample_seed_steps.rb

```
