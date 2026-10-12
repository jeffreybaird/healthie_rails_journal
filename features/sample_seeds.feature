Feature: Load synthetic sample data for the Rails console
  A developer can load a small fictional dataset and demonstrate the four queries.
  Repeating the load preserves existing records and their customized values.

  Background:
    Given I load the synthetic sample seeds

  Scenario: Demonstrate all provider and client memberships
    When I query sample provider "alex" clients
    Then the sample relation contains exactly these clients:
      | key    |
      | sam    |
      | taylor |
    When I query sample provider "jordan" clients
    Then the sample relation contains exactly these clients:
      | key   |
      | riley |
      | sam   |
    When I query sample client "sam" providers
    Then the sample relation contains exactly these providers:
      | key    |
      | alex   |
      | jordan |
    And sample client "sam" has plan "basic" with "alex" and "premium" with "jordan"
    When I query sample client "unrelated" providers
    Then the sample relation is empty

  Scenario: Demonstrate client history and global provider history with stable timestamp ties
    When I query sample client "sam" journal history
    Then the sample relation contains exactly these entries in order:
      | label          |
      | sam-tie-second |
      | sam-tie-first  |
      | sam-middle     |
      | sam-oldest     |
    When I query sample provider "alex" journal history
    Then the sample relation contains exactly these entries in order:
      | label          |
      | taylor-newest  |
      | sam-tie-second |
      | sam-tie-first  |
      | taylor-tie     |
      | sam-middle    |
      | sam-oldest    |
    When I query sample provider "jordan" journal history
    Then the sample relation contains exactly these entries in order:
      | label          |
      | riley-newest   |
      | sam-tie-second |
      | sam-tie-first  |
      | sam-middle     |
      | sam-oldest     |
    When I query sample client "unrelated" journal history
    Then the sample relation contains exactly these entries in order:
      | label            |
      | unrelated-newest |

  Scenario: Repeat the seed load without duplicating or changing persisted records
    Given I remember the sample database records
    When I load the synthetic sample seeds again
    Then all remembered database records are unchanged

  Scenario: Preserve existing customized records while restoring missing synthetic entries
    Given I customize a sample provider, client, plan and journal entry
    When I load the synthetic sample seeds again
    Then the customized records retain all their stored attributes
    And the original synthetic journal entry is restored as a separate record
    Given I remember the sample database records
    When I load the synthetic sample seeds again
    Then all remembered database records are unchanged
