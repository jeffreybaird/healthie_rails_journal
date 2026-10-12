Feature: Retrieve a provider's clients
  A provider can retrieve all associated clients as a composable query.
  Shared clients belong in the result, while unrelated clients stay outside it.

  Background:
    Given the following relationship providers exist:
      | name        |
      | Alex Morgan |
      | Jordan Lee  |
    And the following relationship clients exist:
      | name          |
      | Sam Rivera    |
      | Taylor Reed   |
      | Avery Example |
      | Riley Example |

  Scenario: Retrieve exclusive and shared clients without unrelated clients
    When provider "Alex Morgan" enrolls client "Sam Rivera" on the "basic" plan
    And provider "Alex Morgan" enrolls client "Taylor Reed" on the "premium" plan
    And provider "Jordan Lee" enrolls client "Sam Rivera" on the "premium" plan
    And provider "Jordan Lee" enrolls client "Avery Example" on the "basic" plan
    Then provider "Alex Morgan" has exactly these clients:
      | name        |
      | Sam Rivera  |
      | Taylor Reed |

  Scenario: Filter and order associated clients
    When provider "Alex Morgan" enrolls client "Sam Rivera" on the "basic" plan
    And provider "Alex Morgan" enrolls client "Taylor Reed" on the "premium" plan
    And provider "Alex Morgan" enrolls client "Avery Example" on the "basic" plan
    And provider "Jordan Lee" enrolls client "Sam Rivera" on the "premium" plan
    And provider "Jordan Lee" enrolls client "Riley Example" on the "basic" plan
    And I filter provider "Alex Morgan" clients to these names in descending name order:
      | name          |
      | Avery Example |
      | Taylor Reed   |
      | Riley Example |
    Then the client query returns an Active Record relation with exactly these clients in order:
      | name          |
      | Taylor Reed   |
      | Avery Example |

  Scenario: Query a provider with no relationships
    When provider "Jordan Lee" enrolls client "Sam Rivera" on the "basic" plan
    And I filter provider "Alex Morgan" clients to these names in descending name order:
      | name       |
      | Sam Rivera |
    Then the client query returns an empty Active Record relation
