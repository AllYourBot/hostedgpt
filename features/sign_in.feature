Feature: Sign in
  A returning user signs in with email and password to reach the app

  @javascript
  Scenario: Signing in with a valid password
    Given a user with a password
    When I sign in
    Then I reach my app

  
    Scenario: Rejecting a wrong password
    Given a user with a password
    When I sign in with the wrong password
    Then the sign in is refused
