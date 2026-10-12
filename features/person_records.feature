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

  Scenario Outline: Reject two people with the same email
    When I save a <record_type> with name "Alex Morgan" and email "shared@example.test"
    And I save a <record_type> with name "Sam Rivera" and email "shared@example.test"
    Then the attempted person is rejected without adding a record
    And only the first person is stored with email "shared@example.test"

    Examples:
      | record_type |
      | Provider    |
      | Client      |

  Scenario Outline: Reject a person without name or email
    When I save a <record_type> without name or email
    Then the attempted person is rejected without adding a record
    And the attempted person has errors for name and email

    Examples:
      | record_type |
      | Provider    |
      | Client      |

  Scenario Outline: Reject a person with blank name and email
    When I save a <record_type> with name "" and email ""
    Then the attempted person is rejected without adding a record
    And the attempted person has errors for name and email

    Examples:
      | record_type |
      | Provider    |
      | Client      |

  Scenario Outline: Reject missing or malformed person details
    When I save a <record_type> with name "<name>" and email "<email>"
    Then the attempted person is rejected without adding a record

    Examples:
      | record_type | name        | email              |
      | Provider    |             | alex@example.test  |
      | Client      |             | alex@example.test  |
      | Provider    | Alex Morgan |                    |
      | Client      | Alex Morgan |                    |
      | Provider    | Alex Morgan | unformatted-email  |
      | Client      | Alex Morgan | unformatted-email  |

  Scenario Outline: Reject whitespace-only person details
    When I save a <record_type> with whitespace-only <field>
    Then the attempted person is rejected without adding a record

    Examples:
      | record_type | field |
      | Provider    | name  |
      | Client      | name  |
      | Provider    | email |
      | Client      | email |

  Scenario Outline: Reject an email differing only by case
    When I save a <record_type> with name "Alex Morgan" and email "shared@example.test"
    And I save a <record_type> with name "Sam Rivera" and email "SHARED@EXAMPLE.TEST"
    Then the attempted person is rejected without adding a record
    And only the first person is stored with email "shared@example.test"

    Examples:
      | record_type |
      | Provider    |
      | Client      |

  Scenario: Allow a provider and a client to share an email
    When I save a Provider with name "Alex Morgan" and email "shared@example.test"
    And I save a Client with name "Sam Rivera" and email "SHARED@EXAMPLE.TEST"
    Then the provider and client are both stored with their shared email
