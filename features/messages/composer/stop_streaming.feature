@javascript
Feature: Composer stop streaming
  The stop button while the assistant replies

  Scenario: Stop button shows in composer while replying and disappears when done
    Given I am signed in
    And I am on the greeting conversation
    When I submit "You there?" with ENTER
    Then the composer shows the stop button
    When the assistant reply streams "Foo bar" and finishes
    Then the composer hides the stop button

  Scenario: Stop button shows in composer while replying and clicking cancel stops it
    Given I am signed in
    And I am on the greeting conversation
    When I submit "You there?" with ENTER
    Then the composer is blank
    And the composer shows the stop button
    When the assistant reply streams "Foo bar"
    And the reply is not cancelled
    And I click the composer's stop button
    Then the reply becomes cancelled
    And the composer hides the stop button

  Scenario: Stop keyboard shortcut stops it
    Given I am signed in
    And I am on the greeting conversation
    When I submit "You there?" with ENTER
    Then the composer is blank
    And the composer shows the stop button
    When the assistant reply streams "Foo bar"
    And the reply is not cancelled
    When I press the stop keyboard shortcut
    Then the reply becomes cancelled
    And the composer hides the stop button
