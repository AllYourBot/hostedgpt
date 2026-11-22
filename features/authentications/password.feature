@javascript
Feature: Password authentication
  An existing user logs in with their password and can log out

  Scenario: Logging in and logging out when assistants page is enabled
    Given the assistants page feature is enabled
    And I am on the login page
    Then the email field is focused
    When I log in with my email and password
    Then I am on the assistants page
    When I log out
    Then I stay on the login page

  Scenario: Logging in and logging out when assistants page is disabled
    Given the assistants page feature is disabled
    And I am on the login page
    Then the email field is focused
    When I log in with my email and password
    Then I am on my first assistant's new message page
    When I log out
    Then I stay on the login page

  Scenario: When password is wrong, it shows an error message and keeps email pre-filled
    Given I am on the login page
    When I log in with my email and the wrong password
    Then I see "Invalid email or password"
    And my email stays pre-filled
    And the password field is focused
    And I stay on the login page
