@javascript
Feature: Editing a user message
  The message edit form, its cancel, and versioned saves

  Scenario: Edit icon shows a tooltip
    Given I am signed in
    And I am on the greeting conversation with the last user message hovered
    Then the edit icon shows its tooltip

  Scenario: There is no edit icon beneath messages with images
    Given I am signed in
    And I am on the attachment conversation
    Then the image message has no edit icon
    And the first message has an edit icon

  Scenario: Clicking edit activates a form with cancel, clicking cancel reverts
    Given I am signed in
    And I am on the greeting conversation with the last user message hovered
    When I click the edit icon
    Then I see "Cancel"
    When I click cancel
    Then no cancel buttons remain

  Scenario: Clicking edit, changing text, saving updates the message text, previous navigates back
    Given I am signed in
    And I am on the greeting conversation with the last user message hovered
    When I click the edit icon
    And I change the message text to "Don't think of a pink elephant."
    Then I am on version 1 of the greeting conversation
    When I save the edited message
    Then no save buttons remain
    And I am on version 2 of the greeting conversation
    And I see "Don't think of a pink elephant"
    And the last user message's content is "Don't think of a pink elephant."
    When I navigate back to the previous version
    Then I am on version 1 of the greeting conversation
    And I see the original message text
    And the last user message's content is the original message text
