Feature: Client journal entries
  Clients can store freeform journal text of at least 50 characters.
  Each entry belongs to one client and retains its text unchanged.

  Background:
    Given the following journal clients exist:
      | name        |
      | Sam Rivera  |
      | Taylor Reed |

  Scenario: Persist multiline freeform text unchanged
    When client "Sam Rivera" records this journal entry:
      """
      A synthetic reflection with punctuation & <tags> and enough detail to save.
      A second line preserves its words and spacing.
      """
    Then the journal entry is stored for client "Sam Rivera" with its original text
    And the journal entry has creation and update timestamps

  Scenario: Keep multiple entries and separate client collections
    When client "Sam Rivera" records this journal entry:
      """
      The first synthetic journal reflection has at least fifty characters.
      """
    And client "Sam Rivera" records this journal entry:
      """
      The second synthetic journal reflection also has at least fifty characters.
      """
    And client "Taylor Reed" records this journal entry:
      """
      An unrelated client's synthetic reflection has at least fifty characters.
      """
    Then client "Sam Rivera" has exactly their 2 recorded journal entries
    And client "Taylor Reed" has exactly their 1 recorded journal entries

  Scenario: Accept the minimum length
    When client "Sam Rivera" records a journal entry with 50 characters
    Then the journal entry is stored for client "Sam Rivera" with its original text

  Scenario: Reject text below the minimum length
    When client "Sam Rivera" records a journal entry with 49 characters
    Then the journal entry is rejected without adding a record

  Scenario Outline: Reject missing or blank journal text
    When client "Sam Rivera" records a journal entry with <text> text
    Then the journal entry is rejected without adding a record

    Examples:
      | text       |
      | missing    |
      | empty      |
      | whitespace |

  Scenario Outline: Require an existing client
    When a journal entry is recorded with a <client> client
    Then the journal entry is rejected without adding a record

    Examples:
      | client      |
      | missing     |
      | nonexistent |
