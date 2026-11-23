@javascript
Feature: Submitting messages
  The submit button, enter, shift+enter, and submitting into conversations

  Scenario: Submit button is hidden and can only be clicked when text is entered
    Given I am signed in
    Then the submit button is hidden
    When I type "Entered text so we can now submit" in the composer
    Then the submit button is shown
    When I click the submit button
    Then the composer is blank
    And I am on the newest conversation's messages

  Scenario: Enter works to submit but only when text has been entered
    Given I am signed in
    Then the submit button is hidden
    When I press enter
    Then the path has not changed since I signed in
    When I type "Entered text so we can now submit" in the composer
    Then the submit button is shown
    When I submit with enter and the conversation navigation finishes
    Then the composer is blank
    And I am on the newest conversation's messages

  Scenario: Shift+enter inserts a newline and then enter submits
    Given I am signed in
    When I type "First line" in the composer
    And I press shift+enter
    And I type "Second line" in the composer
    Then the composer holds two lines
    And the path has not changed since I signed in
    When I submit with enter and the conversation navigation finishes
    Then the composer is blank
    And I am on the newest conversation's messages

  Scenario: Submitting a couple messages to an existing conversation with ENTER works
    Given I am signed in
    And I am on the greeting conversation
    And the composer input is focused
    And I record the current path
    When I submit "This is a message" to the existing conversation with ENTER
    Then the composer is blank
    And the path has not changed since I recorded it
    When I submit "This is a second message" to the existing conversation with ENTER
    Then the composer is blank
    And the path has not changed since I recorded it

  Scenario: Submitting a couple messages to an existing conversation with CLICKING works
    Given I am signed in
    And I am on the greeting conversation
    And the composer input is focused
    And I record the current path
    When I submit "This is a message" to the existing conversation by clicking
    Then the composer is blank
    And the path has not changed since I recorded it
    When I submit "This is a second message" to the existing conversation by clicking
    Then the composer is blank
    And the path has not changed since I recorded it
