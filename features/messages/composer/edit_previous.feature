@javascript
Feature: Composer edit previous
  The up-arrow edits the previous message

  Scenario: Pressing up while focused in composer edits the previous message
    Given I am signed in
    And I am on the greeting conversation
    Then the composer input is focused
    And I do not see "Cancel"
    When I press "up"
    Then I see "Cancel"
    And the last user message has a cancel control

  Scenario: Pressing up once text has been entered into the composer does not edit the previous message
    Given I am signed in
    And I am on the greeting conversation
    Then the composer input is focused
    And I type "Starting to type a question..." in the composer
    And I do not see "Cancel"
    When I press "up"
    Then I do not see "Cancel"
