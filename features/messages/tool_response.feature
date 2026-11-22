@javascript
Feature: Tool response
  A tool's action is visible to the user in the conversation

  Scenario: Ensure a visible link is displayed to user that the memory was updated
    Given I am signed in
    And I am on the memorize conversation
    Then I see "Memory updated"
