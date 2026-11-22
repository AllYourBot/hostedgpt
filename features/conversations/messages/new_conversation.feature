@javascript
Feature: New conversation
  Starting a new conversation from an open one

  Scenario: Clicking new compose icon in the top-right starts a new conversation and preserves sidebar scroll
    Given I am signed in
    And I am on the greeting conversation
    Then the new chat button in the header shows its tooltip
    And the greeting conversation is selected in the nav
    When I click the new chat button
    Then I am on a new conversation page for the greeting's assistant
    And the greeting conversation is no longer selected in the nav

  Scenario: Creating new chat with meta+shift+o
    Given I am signed in
    And I am on the greeting conversation
    When I press the new chat keyboard shortcut "meta+shift+o"
    Then I am on a new conversation page for the greeting's assistant

  Scenario: Creating new chat with meta+j
    Given I am signed in
    And I am on the greeting conversation
    When I press the new chat keyboard shortcut "meta+j"
    Then I am on a new conversation page for the greeting's assistant
