@javascript
Feature: Login landing paths
  After logging in, the user is redirected based on the assistants page feature

  Scenario: After logging in, the user is redirected to the root path when assistants page is enabled
    Given the assistants page feature is enabled
    When I sign in from the root page
    Then I am on the assistants page

  Scenario: After logging in, the user is redirected to the assistant page when assistants page is disabled
    Given the assistants page feature is disabled
    When I sign in from the root page
    Then I am on my first assistant's new message page

  Scenario: Visiting the index defaults to the first assistant and starts a new conversation when assistants page is disabled
    Given I am signed in
    And the assistants page feature is disabled
    When I visit the root path
    Then I am on my first assistant's new message page
    And the first assistant in the nav is selected

  Scenario: Visiting the index stays on the root path when assistants page is enabled
    Given I am signed in
    And the assistants page feature is enabled
    When I visit the root path
    Then I am on the assistants page
