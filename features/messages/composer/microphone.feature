@javascript
Feature: Composer microphone
  The mic button, its shortcut, and spoken messages

  Scenario: When the user has voice feature disabled, composer does not ever show mic
    Given the voice feature is disabled
    And I am signed in
    And I am on Samantha's new message page
    Then the composer has no mic enable button

  Scenario: When the user has voice feature enabled, composer shows a mic icon before text is entered, and hides the mic after text
    Given the voice feature is enabled
    And I am signed in
    And I am on Samantha's new message page
    Then the mic enable button is visible
    When I type "H" in the composer
    Then the mic enable button is hidden
    When I press backspace
    Then the mic enable button is visible

  Scenario: When mic is clicked it turns red, when red mic is clicked it reverts back
    Given the voice feature is enabled
    And I am signed in
    And I am on Samantha's new message page
    Then the mic enable button is visible
    And the mic disable button is hidden
    When I click the mic enable button
    Then the mic enable button is hidden
    And the mic disable button is visible
    When I click the mic disable button
    Then the mic enable button is visible
    And the mic disable button is hidden

  Scenario: When mic keyboard shortcut is used it turns red, and clicking the text area reverts it back and lets you edit the text
    Given the voice feature is enabled
    And I am signed in
    And I am on Samantha's new message page
    Then the mic enable button is visible
    And the mic disable button is hidden
    When I press the mic keyboard shortcut
    Then the mic enable button is hidden
    And the mic disable button is visible
    When I set the composer value to "Hello?" and click the composer overlay
    Then the mic disable button is hidden
    And the composer holds "Hello?"

  Scenario: Words the listener hears are submitted as a spoken message
    Given the voice feature is enabled
    And I am signed in
    And I am on Samantha's new message page
    When I click the mic enable button
    Then the mic disable button is visible
    When the listener considers "What time is it?"
    Then I see "What time is it?"
    And the "What time is it?" message was spoken

  Scenario: Switching to another conversation in the sidebar turns the mic off
    Given the voice feature is enabled
    And I am signed in
    And I am on the greeting conversation
    When I click the mic enable button
    Then the mic disable button is visible
    When I open the attachment conversation from the nav
    Then I see "Testing one attachment"
    And the listener is disabled after switching conversations
    Then the composer shows the mic enable button
    And the composer hides the mic disable button

  Scenario: Sending a spoken message keeps the mic on
    Given the voice feature is enabled
    And I am signed in
    And I am on Samantha's new message page
    When I click the mic enable button
    When the listener considers "What time is it?"
    Then I see "What time is it?"
    And the composer shows the mic disable button
    And the listener stays enabled after sending a spoken message

  Scenario: Typed messages are not spoken messages
    Given the voice feature is enabled
    And I am signed in
    And I am on Samantha's new message page
    When I type "What day is it?" in the composer
    And I press enter
    Then I see "What day is it?"
    And the "What day is it?" message was not spoken
