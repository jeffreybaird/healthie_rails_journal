Feature: Provider and client records
  The data model stores providers and clients using ordinary Rails persistence.

  Scenario Outline: Store a person's name and email
    When I save a <record_type> with name "Renée O'Neil" and email "renee@example.test"
    Then the saved person has name "Renée O'Neil" and email "renee@example.test"
    And the saved person has creation and update timestamps

    Examples:
      | record_type |
      | Provider    |
      | Client      |

  Scenario Outline: Store two people with the same email
    When I save a <record_type> with name "Alex Morgan" and email "shared@example.test"
    And I save a <record_type> with name "Sam Rivera" and email "shared@example.test"
    Then both people are stored with email "shared@example.test"

    Examples:
      | record_type |
      | Provider    |
      | Client      |

  Scenario Outline: Store a person without name or email
    When I save a <record_type> without name or email
    Then the saved person has no name or email

    Examples:
      | record_type |
      | Provider    |
      | Client      |

  Scenario Outline: Store a person with blank name and email
    When I save a <record_type> with name "" and email ""
    Then the saved person has name "" and email ""

    Examples:
      | record_type |
      | Provider    |
      | Client      |
