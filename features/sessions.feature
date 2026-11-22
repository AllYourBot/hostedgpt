@javascript
Feature: Sessions
  Logging in and the login page's oauth buttons

  Scenario: Logging in as an existing user when assistants page is enabled
    Given the assistants page feature is enabled
    And I am on the login page
    Then the email field is focused
    When I log in with my email and password
    Then I am on the assistants page

  Scenario: Logging in as an existing user when assistants page is disabled
    Given the assistants page feature is disabled
    And I am on the login page
    Then the email field is focused
    When I log in with my email and password
    Then I am on my first assistant's new message page

  Scenario: A wrong password shows an error and keeps the email pre-filled
    Given I am on the login page
    When I log in with my email and the wrong password
    Then I see "Invalid email or password"
    And my email stays pre-filled
    And the password field is focused
    And I stay on the login page

  Scenario: No Google button when the feature is disabled
    Given the google authentication feature is disabled
    And I am on the login page
    Then I do not see "Log In with Google"

  Scenario: The Google button when the feature is enabled
    Given the google authentication feature is enabled
    And I am on the login page
    Then I see "Log In with Google"

  Scenario: The Microsoft button when the feature is enabled
    Given the microsoft graph authentication feature is enabled
    And I am on the login page
    Then I see "Log In with Microsoft"

  Scenario: No Microsoft button when the feature is disabled
    Given the microsoft graph authentication feature is disabled
    And I am on the login page
    Then I do not see "Log In with Microsoft"
