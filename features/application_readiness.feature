Feature: Application readiness
  Operators can verify that the application and its database are ready.

  Scenario Outline: Check readiness
    When I request "GET" "<path>"
    Then the HTTP response status is 200
    And the readiness response confirms the database is reachable

    Examples:
      | path    |
      | /health |
      | /up     |
