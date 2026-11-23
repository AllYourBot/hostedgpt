@javascript
Feature: Composer resetting
  The composer clears after submit but respects typing in flight

  Scenario: The composer clears after the user presses submit, but if they start typing really quickly it won't clear with the final morph
    Given I am signed in
    And I am on the greeting conversation
    When I submit "Text has been entered" with morphing and scrolling
    And the assistant reply is stubbed with "Assistant reply"
    Then the composer is blank
    And I type "New text" in the composer
    And the composer holds "New text"
    When the conversation refreshes with a long reply
    Then the composer holds "New text"
