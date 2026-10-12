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

  @allow-rescue
  Scenario Outline: Former note endpoints are unavailable
    When I request "<method>" "<path>"
    Then the HTTP response status is 404

    Examples:
      | method | path             |
      | GET    | /notes           |
      | POST   | /notes           |
      | PATCH  | /notes/1/archive |
