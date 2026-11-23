@javascript
Feature: Stopped messages
  A cancelled reply's icon depends on its content

  Scenario: An empty cancelled message shows the stopped icon without ...
    Given I am signed in
    And the "dont_know_day" message is an empty cancelled reply
    And I am on the greeting conversation
    Then the message's content renders as empty
    And the stopped icon is visible

  Scenario: A cancelled message with some text shows the stopped icon with ...
    Given I am signed in
    And the "dont_know_day" message is a cancelled reply reading "But I"
    And I am on the greeting conversation
    Then the message's content ends with "..."
    And the stopped icon is visible
