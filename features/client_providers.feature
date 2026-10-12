Feature: Retrieve a client's providers
  A client can retrieve all associated providers as a composable query.
  Basic and premium plans both belong in the result, while unrelated providers stay outside it.

  Background:
    Given the following relationship providers exist:
      | name          |
      | Alex Morgan   |
      | Jordan Lee    |
      | Taylor Reed   |
      | Riley Example |
    And the following relationship clients exist:
      | name          |
      | Sam Rivera    |
      | Avery Example |

  Scenario: Retrieve providers on both plans without unrelated providers
    When provider "Alex Morgan" enrolls client "Sam Rivera" on the "basic" plan
    And provider "Jordan Lee" enrolls client "Sam Rivera" on the "premium" plan
    And provider "Alex Morgan" enrolls client "Avery Example" on the "premium" plan
    And provider "Riley Example" enrolls client "Avery Example" on the "basic" plan
    Then client "Sam Rivera" has exactly these providers:
      | name        |
      | Alex Morgan |
      | Jordan Lee  |

  Scenario: Filter and order associated providers
    When provider "Alex Morgan" enrolls client "Sam Rivera" on the "basic" plan
    And provider "Jordan Lee" enrolls client "Sam Rivera" on the "premium" plan
    And provider "Taylor Reed" enrolls client "Sam Rivera" on the "basic" plan
    And provider "Alex Morgan" enrolls client "Avery Example" on the "premium" plan
    And provider "Riley Example" enrolls client "Avery Example" on the "basic" plan
    And I filter client "Sam Rivera" providers to these names in descending name order:
      | name          |
      | Alex Morgan   |
      | Taylor Reed   |
      | Riley Example |
    Then the provider query returns an Active Record relation with exactly these providers in order:
      | name        |
      | Taylor Reed |
      | Alex Morgan |

  Scenario: Query a client with no relationships
    When provider "Alex Morgan" enrolls client "Avery Example" on the "basic" plan
    And I filter client "Sam Rivera" providers to these names in descending name order:
      | name        |
      | Alex Morgan |
    Then the provider query returns an empty Active Record relation
