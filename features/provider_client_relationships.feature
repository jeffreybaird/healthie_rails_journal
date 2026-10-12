Feature: Provider-specific client plans
  A client can work with several providers and have a different plan with each.
  Each provider-client pair has exactly one relationship with a basic or premium plan.

  Background:
    Given the following relationship providers exist:
      | name        |
      | Alex Morgan |
      | Jordan Lee  |
    And the following relationship clients exist:
      | name        |
      | Sam Rivera  |
      | Taylor Reed |

  Scenario Outline: Store an allowed plan
    When provider "Alex Morgan" enrolls client "Sam Rivera" on the "<plan>" plan
    Then the enrollment is stored with the "<plan>" plan
    And provider "Alex Morgan" has exactly these clients:
      | name       |
      | Sam Rivera |
    And client "Sam Rivera" has exactly these providers:
      | name        |
      | Alex Morgan |

    Examples:
      | plan    |
      | basic   |
      | premium |

  Scenario: Share a client between providers with different plans
    When provider "Alex Morgan" enrolls client "Sam Rivera" on the "basic" plan
    And provider "Jordan Lee" enrolls client "Sam Rivera" on the "premium" plan
    And provider "Jordan Lee" enrolls client "Taylor Reed" on the "basic" plan
    Then client "Sam Rivera" has the "basic" plan with provider "Alex Morgan"
    And client "Sam Rivera" has the "premium" plan with provider "Jordan Lee"
    And provider "Alex Morgan" has exactly these clients:
      | name       |
      | Sam Rivera |
    And provider "Jordan Lee" has exactly these clients:
      | name        |
      | Sam Rivera  |
      | Taylor Reed |
    And client "Sam Rivera" has exactly these providers:
      | name        |
      | Alex Morgan |
      | Jordan Lee  |
    And client "Taylor Reed" has exactly these providers:
      | name       |
      | Jordan Lee |

  Scenario: Reject a second relationship for the same pair
    When provider "Alex Morgan" enrolls client "Sam Rivera" on the "basic" plan
    And provider "Alex Morgan" enrolls client "Sam Rivera" on the "premium" plan
    Then the enrollment is rejected without adding a relationship
    And client "Sam Rivera" has the "basic" plan with provider "Alex Morgan"

  Scenario Outline: Reject an unsupported or blank plan
    When provider "Alex Morgan" enrolls client "Sam Rivera" on the "<plan>" plan
    Then the enrollment is rejected without adding a relationship

    Examples:
      | plan       |
      | enterprise |
      | BASIC      |
      |            |

  Scenario: Reject a missing plan
    When provider "Alex Morgan" enrolls client "Sam Rivera" without a plan
    Then the enrollment is rejected without adding a relationship

  Scenario Outline: Reject a missing participant
    When I enroll a client on the "basic" plan without a <participant>
    Then the enrollment is rejected without adding a relationship

    Examples:
      | participant |
      | provider    |
      | client      |
