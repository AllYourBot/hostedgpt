@javascript
Feature: Composer focus and shortcuts
  The composer's autofocus, ESC unfocus, and the "/" and "?" shortcuts

  Scenario: The cursor is auto-focused in the text input for a new conversation and selecting existing conversation and ESC unfocuses
    Given I am signed in
    Then the composer input is focused
    When I press "esc"
    Then the body is focused
    When I select the greeting conversation from the nav
    And the images have loaded
    Then the composer input is focused

  Scenario: When cursor is not focused in the text input, / focuses it and then an accidental second / does not appear
    Given I am signed in
    When I press "esc"
    Then the body is focused
    When I press "/"
    Then the composer input is focused
    And the composer is empty
    When I press "/"
    Then the composer is empty

  Scenario: When cursor is focused in the text input, ? works as a key press
    Given I am signed in
    Then the composer is empty
    When I press "?"
    Then the composer holds "?"

  Scenario: When not in text input, ? opens the keyboard shortcuts and ESC dismisses it and keyboard shortcuts work normally
    Given I am signed in
    When I press "esc"
    Then the body is focused
    And I do not see "Keyboard shortcuts"
    When I press "?"
    Then I see "Keyboard shortcuts"
    When I press "esc"
    Then I do not see "Keyboard shortcuts"
    When I press "/"
    Then the composer input is focused

  Scenario: When not in text input, ? opens the keyboard shortcuts and CLICKING OUTSIDE dismisses it and keyboard shortcuts work normally
    Given I am signed in
    When I press "esc"
    Then the body is focused
    And I do not see "Keyboard shortcuts"
    When I press "?"
    Then I see "Keyboard shortcuts"
    When I click outside the modal
    Then I do not see "Keyboard shortcuts"
    When I press "/"
    Then the composer input is focused
