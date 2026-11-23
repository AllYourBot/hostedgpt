@javascript
Feature: Thinking expansion
  The thinking text expands via the summary arrow

  Scenario: Pressing the arrow beside Thinking expands the thinking text
    Given I am signed in
    And the greeting conversation's last assistant reply is thinking "Pondering the greeting"
    And I am on the greeting conversation
    When I press the thinking summary arrow
    Then I see "Pondering the greeting"
