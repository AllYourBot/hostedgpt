@javascript
Feature: User registration
  A new visitor signs up from the login page

  Scenario: The new user form reveals more fields when password is focused and those fields stay
    Given I am on the login page
    When I follow the first "Sign up" link
    Then I see "Email" and "Password" but not "Full Name"
    When I fill the registration email and password
    Then the full name field is revealed
    When I refill the registration email and password
    Then the full name field stays revealed

  Scenario: Creating a new user when assistants page is enabled
    Given the assistants page feature is enabled
    And I am on the login page
    When I sign up as "tester_true@test.com" named "John Doe"
    Then I am on the assistants page
    And the user "tester_true@test.com" exists named "John Doe" with a password credential

  Scenario: Creating a new user when assistants page is disabled
    Given the assistants page feature is disabled
    And I am on the login page
    When I sign up as "tester_false@test.com" named "John Doe"
    Then I am on the new user's first assistant's new message page
    And the user "tester_false@test.com" exists named "John Doe" with a password credential
