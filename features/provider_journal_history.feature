Feature: Retrieve journal history across a provider's clients
  A provider retrieves one globally ordered history across all their clients.
  A shared client's entries appear once, and unrelated clients' entries stay outside the result.
  Filtering and limiting preserve the provider's boundary and stable newest-first order.

  Background:
    Given the following relationship providers exist:
      | name        |
      | Alex Morgan |
      | Jordan Lee  |
      | Casey Lane  |
    And the following journal clients exist:
      | name          |
      | Sam Rivera    |
      | Taylor Reed   |
      | Avery Example |
      | Riley Example |
      | Unassigned    |
    And the following journal provider-client relationships exist:
      | provider    | client        | plan    |
      | Alex Morgan | Sam Rivera    | basic   |
      | Alex Morgan | Taylor Reed   | premium |
      | Alex Morgan | Avery Example | basic   |
      | Jordan Lee  | Sam Rivera    | premium |
      | Jordan Lee  | Riley Example | basic   |

  Scenario: Retrieve every associated entry once in global stable newest-first order
    Given the following dated journal entries exist in this insertion order:
      | label                 | client        | created_at           |
      | exclusive newest      | Taylor Reed   | 2026-01-20T00:00:00Z |
      | shared oldest         | Sam Rivera    | 2026-01-05T00:00:00Z |
      | exclusive earlier tie | Taylor Reed   | 2026-01-15T00:00:00Z |
      | shared later tie      | Sam Rivera    | 2026-01-15T00:00:00Z |
      | shared middle         | Sam Rivera    | 2026-01-10T00:00:00Z |
      | unrelated newest      | Riley Example | 2026-01-25T00:00:00Z |
      | unrelated tie         | Riley Example | 2026-01-15T00:00:00Z |
      | unassigned newest     | Unassigned    | 2026-01-30T00:00:00Z |
    When I retrieve provider "Alex Morgan" journal history
    Then the journal history query returns an Active Record relation with exactly these entries in order:
      | label                 |
      | exclusive newest      |
      | shared later tie      |
      | exclusive earlier tie |
      | shared middle         |
      | shared oldest         |

  Scenario: Filter and limit across clients without losing stable ordering or the provider boundary
    Given the following dated journal entries exist in this insertion order:
      | label                 | client        | created_at           |
      | exclusive newest      | Taylor Reed   | 2026-01-20T00:00:00Z |
      | shared oldest         | Sam Rivera    | 2026-01-05T00:00:00Z |
      | exclusive earlier tie | Taylor Reed   | 2026-01-15T00:00:00Z |
      | shared later tie      | Sam Rivera    | 2026-01-15T00:00:00Z |
      | unrelated tie         | Riley Example | 2026-01-15T00:00:00Z |
    When I retrieve provider "Alex Morgan" journal history through "2026-01-15T00:00:00Z" limited to 2 entries
    Then the journal history query returns an Active Record relation with exactly these entries in order:
      | label                 |
      | shared later tie      |
      | exclusive earlier tie |

  Scenario: Query a provider whose clients have no journal entries
    Given the following dated journal entries exist in this insertion order:
      | label            | client        | created_at           |
      | unrelated oldest | Riley Example | 2026-01-10T00:00:00Z |
    When I retrieve provider "Alex Morgan" journal history through "2026-01-15T00:00:00Z" limited to 2 entries
    Then the journal history query returns an empty Active Record relation

  Scenario: Query a provider with no clients
    Given the following dated journal entries exist in this insertion order:
      | label         | client     | created_at           |
      | shared oldest | Sam Rivera | 2026-01-05T00:00:00Z |
    When I retrieve provider "Casey Lane" journal history through "2026-01-15T00:00:00Z" limited to 2 entries
    Then the journal history query returns an empty Active Record relation
