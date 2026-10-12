Feature: Retrieve a client's journal history
  A client can retrieve their journal entries from newest to oldest.
  Entries with the same creation date show the later-created record first.
  The query supports filtering and limiting while keeping other clients' entries outside the result.

  Background:
    Given the following journal clients exist:
      | name        |
      | Sam Rivera  |
      | Taylor Reed |

  Scenario: Retrieve every own entry in stable newest-first order
    Given the following dated journal entries exist in this insertion order:
      | label             | client      | created_at           |
      | newest            | Sam Rivera  | 2026-01-20T00:00:00Z |
      | oldest            | Sam Rivera  | 2026-01-10T00:00:00Z |
      | earlier tie       | Sam Rivera  | 2026-01-15T00:00:00Z |
      | later tie         | Sam Rivera  | 2026-01-15T00:00:00Z |
      | unrelated newest  | Taylor Reed | 2026-01-25T00:00:00Z |
      | unrelated tie     | Taylor Reed | 2026-01-15T00:00:00Z |
    When I retrieve client "Sam Rivera" journal history
    Then the journal history query returns an Active Record relation with exactly these entries in order:
      | label       |
      | newest      |
      | later tie   |
      | earlier tie |
      | oldest      |

  Scenario: Filter and limit history without losing stable ordering or the client boundary
    Given the following dated journal entries exist in this insertion order:
      | label             | client      | created_at           |
      | newest            | Sam Rivera  | 2026-01-20T00:00:00Z |
      | oldest            | Sam Rivera  | 2026-01-10T00:00:00Z |
      | earlier tie       | Sam Rivera  | 2026-01-15T00:00:00Z |
      | later tie         | Sam Rivera  | 2026-01-15T00:00:00Z |
      | unrelated newest  | Taylor Reed | 2026-01-25T00:00:00Z |
      | unrelated tie     | Taylor Reed | 2026-01-15T00:00:00Z |
    When I retrieve client "Sam Rivera" journal history through "2026-01-15T00:00:00Z" limited to 2 entries
    Then the journal history query returns an Active Record relation with exactly these entries in order:
      | label       |
      | later tie   |
      | earlier tie |

  Scenario: Query a client with no journal entries
    Given the following dated journal entries exist in this insertion order:
      | label            | client      | created_at           |
      | unrelated oldest | Taylor Reed | 2026-01-10T00:00:00Z |
    When I retrieve client "Sam Rivera" journal history through "2026-01-15T00:00:00Z" limited to 2 entries
    Then the journal history query returns an empty Active Record relation
