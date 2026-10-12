# Issue #8 verification

`Provider#journal_entries` now uses an ordinary `has_many :through` association
through clients. `provider.journal_entries.recent_first` returns a lazy,
composable Active Record relation with global `created_at DESC, id DESC`
ordering. Shared clients appear once; unrelated and unassigned clients stay
outside the provider boundary. Empty providers and providers whose clients
have no entries return empty relations. No schema change is needed.

## Workflow

The spec writer added seven RSpec examples and four Cucumber scenarios and
safely autocorrected owned test files. The runner demonstrated red: seven
RSpec failures and four Cucumber failures from missing `Provider#journal_entries`
(with four downstream assertion steps skipped). The independent reviewer
accepted the tests and froze their SHA-256 hashes before implementation.
The implementer added the association and safely autocorrected the owned model.
Accepted hashes remained unchanged. No tests were deleted or weakened.

The README example was extracted and executed twice in test-environment rollback
transactions. Exact ordered IDs, filtered results, the empty provider result,
relation type and rollback were verified. No development or deployed data was
used. Full example evidence is `/tmp/issue8/readme-example.log`.

Runtime: Ruby 3.3.12 and Bundler 2.5.22, with
`/Users/jeffreybaird/.rubies/ruby-3.3.12/bin` prepended to PATH and
`BUNDLE_PATH=vendor/bundle`. Test commands unset `DATABASE_PATH`, `DATABASE_URL`
and `PRIMARY_DATABASE_URL` and set `RAILS_ENV=test`.

## Full quality gate

Final sequential `bin/check` exited 0: RuboCop inspected 52 files with no
offenses; RSpec passed 176 examples; strict Cucumber passed 55 scenarios and
225 steps. Fresh combined coverage passed the unchanged 100% line and branch
gates (31/31 executable lines). No pending or skipped cases remain in green.
Full output: `/tmp/issue8/bin-check-escalated.log`.

An initial overlapping test-database run failed with SQLite contention and
contamination; the runner accidentally overwrote its full output. That failure
is not claimed as passing evidence. Subsequent suite operations ran sequentially.
The restricted sequential run passed lint, both suites and coverage, then failed
advisory refresh because the sandbox could not write the advisory cache's
`.git/FETCH_HEAD`. The complete gate was rerun with native elevated permission;
no gate was bypassed. Restricted evidence: `/tmp/issue8/bin-check-restricted.log`.
Existing SimpleCov deprecation warnings remain visible in the logs.

`bundle exec bundler-audit check --update` refreshed ruby-advisory-db
(commit `a6847b0651a702488f5844081e848dd1ec9dbf1d`, 1263 advisories,
last updated 2026-10-10 09:26:59 -0400) and found no vulnerabilities,
including pre-existing findings.

## Independent review and dead code

The independent reviewer inspected the full source/test/documentation diff,
accepted hashes, correction evidence, focused and full gate logs, README
execution and dependency advisory result. No implementation findings remain.
The new association is a documented console/public API; the existing client
association and `recent_first` scope remain live. No confirmed dead code was
found or removed, and no test removal is proposed.

New native mutation audit entries have `owner_ok: true` and empty `violations`.
Historical violation-bearing entries are pre-existing and ambiguously attributed;
they are not new findings from this issue. Full independent review is retained
at `/tmp/issue8/final-review.md`.

## Focused RSpec evidence

```text
$ bundle exec rspec spec/models/provider_journal_history_spec.rb --format documentation
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:7:in `block in <top (required)>': [DEPRECATION] `SimpleCov.track_files` is deprecated. Replace with `SimpleCov.cover "{app,lib}/**/*.rb"` — `cover` includes unloaded files on disk (the historical `track_files` behavior) and also restricts the report to the matching set. If you want to keep additional files outside "{app,lib}/**/*.rb" in the report, pass every directory you care about, e.g. `cover "{app,lib}/**/*.rb", "app/**/*.rb"`.
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:10:in `block in <top (required)>': [DEPRECATION] `SimpleCov.add_filter` is deprecated. Replace with `SimpleCov.skip` (same arguments, same behavior). Example: `SimpleCov.skip { ... }`.

Randomized with seed 19137

Provider
  #journal_entries.recent_first
    when associated clients have no journal entries
      returns an empty relation that can still be filtered and limited
    when the provider has no clients
      returns an empty relation despite other clients' entries
    with entries across shared, exclusive, unrelated and unassigned clients
      keeps unrelated clients outside an additional client filter
      composes filtering and a limit while preserving global ordering and the provider boundary
      returns each associated entry once in global creation date and ID descending order
      constructs a lazy Active Record relation without fetching client IDs or entries
      loads all clients' history with one database query that scopes through provider relationships

Finished in 0.10537 seconds (files took 1.25 seconds to load)
7 examples, 0 failures

Randomized with seed 19137

exit=0
```

## Focused Cucumber evidence

Feature: `features/provider_journal_history.feature`. Actual strict pretty output:

```text
$ bundle exec cucumber features/provider_journal_history.feature --format pretty --strict
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:7:in `block in <top (required)>': [DEPRECATION] `SimpleCov.track_files` is deprecated. Replace with `SimpleCov.cover "{app,lib}/**/*.rb"` — `cover` includes unloaded files on disk (the historical `track_files` behavior) and also restricts the report to the matching set. If you want to keep additional files outside "{app,lib}/**/*.rb" in the report, pass every directory you care about, e.g. `cover "{app,lib}/**/*.rb", "app/**/*.rb"`.
/Users/jeffreybaird/src/healthie_rails_journal/support/coverage.rb:10:in `block in <top (required)>': [DEPRECATION] `SimpleCov.add_filter` is deprecated. Replace with `SimpleCov.skip` (same arguments, same behavior). Example: `SimpleCov.skip { ... }`.
Feature: Retrieve journal history across a provider's clients
  A provider retrieves one globally ordered history across all their clients.
  A shared client's entries appear once, and unrelated clients' entries stay outside the result.
  Filtering and limiting preserve the provider's boundary and stable newest-first order.

  Background:                                                      # features/provider_journal_history.feature:6
    Given the following relationship providers exist:              # features/step_definitions/provider_client_relationship_steps.rb:21
      | name        |
      | Alex Morgan |
      | Jordan Lee  |
      | Casey Lane  |
    And the following journal clients exist:                       # features/step_definitions/journal_entry_steps.rb:18
      | name          |
      | Sam Rivera    |
      | Taylor Reed   |
      | Avery Example |
      | Riley Example |
      | Unassigned    |
    And the following journal provider-client relationships exist: # features/step_definitions/provider_journal_history_steps.rb:3
      | provider    | client        | plan    |
      | Alex Morgan | Sam Rivera    | basic   |
      | Alex Morgan | Taylor Reed   | premium |
      | Alex Morgan | Avery Example | basic   |
      | Jordan Lee  | Sam Rivera    | premium |
      | Jordan Lee  | Riley Example | basic   |

  Scenario: Retrieve every associated entry once in global stable newest-first order                      # features/provider_journal_history.feature:27
    Given the following dated journal entries exist in this insertion order:                              # features/step_definitions/client_journal_history_steps.rb:3
      | label                 | client        | created_at           |
      | exclusive newest      | Taylor Reed   | 2026-01-20T00:00:00Z |
      | shared oldest         | Sam Rivera    | 2026-01-05T00:00:00Z |
      | exclusive earlier tie | Taylor Reed   | 2026-01-15T00:00:00Z |
      | shared later tie      | Sam Rivera    | 2026-01-15T00:00:00Z |
      | shared middle         | Sam Rivera    | 2026-01-10T00:00:00Z |
      | unrelated newest      | Riley Example | 2026-01-25T00:00:00Z |
      | unrelated tie         | Riley Example | 2026-01-15T00:00:00Z |
      | unassigned newest     | Unassigned    | 2026-01-30T00:00:00Z |
    When I retrieve provider "Alex Morgan" journal history                                                # features/step_definitions/provider_journal_history_steps.rb:12
    Then the journal history query returns an Active Record relation with exactly these entries in order: # features/step_definitions/client_journal_history_steps.rb:25
      | label                 |
      | exclusive newest      |
      | shared later tie      |
      | exclusive earlier tie |
      | shared middle         |
      | shared oldest         |

  Scenario: Filter and limit across clients without losing stable ordering or the provider boundary            # features/provider_journal_history.feature:47
    Given the following dated journal entries exist in this insertion order:                                   # features/step_definitions/client_journal_history_steps.rb:3
      | label                 | client        | created_at           |
      | exclusive newest      | Taylor Reed   | 2026-01-20T00:00:00Z |
      | shared oldest         | Sam Rivera    | 2026-01-05T00:00:00Z |
      | exclusive earlier tie | Taylor Reed   | 2026-01-15T00:00:00Z |
      | shared later tie      | Sam Rivera    | 2026-01-15T00:00:00Z |
      | unrelated tie         | Riley Example | 2026-01-15T00:00:00Z |
    When I retrieve provider "Alex Morgan" journal history through "2026-01-15T00:00:00Z" limited to 2 entries # features/step_definitions/provider_journal_history_steps.rb:16
    Then the journal history query returns an Active Record relation with exactly these entries in order:      # features/step_definitions/client_journal_history_steps.rb:25
      | label                 |
      | shared later tie      |
      | exclusive earlier tie |

  Scenario: Query a provider whose clients have no journal entries                                             # features/provider_journal_history.feature:61
    Given the following dated journal entries exist in this insertion order:                                   # features/step_definitions/client_journal_history_steps.rb:3
      | label            | client        | created_at           |
      | unrelated oldest | Riley Example | 2026-01-10T00:00:00Z |
    When I retrieve provider "Alex Morgan" journal history through "2026-01-15T00:00:00Z" limited to 2 entries # features/step_definitions/provider_journal_history_steps.rb:16
    Then the journal history query returns an empty Active Record relation                                     # features/step_definitions/client_journal_history_steps.rb:32

  Scenario: Query a provider with no clients                                                                  # features/provider_journal_history.feature:68
    Given the following dated journal entries exist in this insertion order:                                  # features/step_definitions/client_journal_history_steps.rb:3
      | label         | client     | created_at           |
      | shared oldest | Sam Rivera | 2026-01-05T00:00:00Z |
    When I retrieve provider "Casey Lane" journal history through "2026-01-15T00:00:00Z" limited to 2 entries # features/step_definitions/provider_journal_history_steps.rb:16
    Then the journal history query returns an empty Active Record relation                                    # features/step_definitions/client_journal_history_steps.rb:32

4 scenarios (4 passed)
24 steps (24 passed)
0m0.095s
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
exit=0
```

## Accepted test hashes

```text
73dcb4fe8c174ff298deabb26f2b4fc22b388c46fb2938ad48e5820dc568551f  spec/models/provider_journal_history_spec.rb
1026a09f745beb7388152eeeb6edc25f4c64382616284e866bbdeca81acb5608  features/provider_journal_history.feature
556630e75a298dd37a608d6911b728d9ca81cfaa715ca53e0e23b923b24fea6e  features/step_definitions/provider_journal_history_steps.rb
```
