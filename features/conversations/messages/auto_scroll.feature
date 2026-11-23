@javascript
Feature: Conversation auto-scroll
  The message list scrolls to the bottom and offers a scroll button

  Scenario: The conversation auto-scrolls to bottom when page loads
    Given I am signed in
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    Then the page is at the bottom
    And the scroll button is hidden

  Scenario: The scroll appears and disappears based on scroll position
    Given I am signed in
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    And the page is at the bottom
    When I scroll up to the second message
    Then the scroll button is visible
    When I scroll up to the first message
    Then the scroll button is visible
    When I scroll back down to the last message
    Then the page is scrolled to the bottom
    And the scroll button is hidden

  Scenario: Clicking scroll down button scrolls the page to the bottom
    Given I am signed in
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    And the page is at the bottom
    When I scroll up to the first message
    Then the scroll button is visible
    When I click the scroll button
    Then the page is scrolled to the bottom
    And the scroll button is hidden

  Scenario: Submitting a message with ENTER inserts two new messages and scrolls down
    Given I am signed in
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    When I submit "Watch me appear" with ENTER and stay at the bottom
    Then two new messages contain the submission

  Scenario: When the AI replies with a message it scrolls down
    Given I am signed in
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    And the last message shows the stub content
    When the stub reply streams while staying at the bottom
    Then the streamed content is displayed

  Scenario: When conversation is scrolled to the bottom, when the browser resizes it auto-scrolls to stay at the bottom
    Given I am signed in
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    When the browser resizes while staying at the bottom
    Then the page is at the bottom

  Scenario: When conversation is NOT scrolled to the bottom, when the browser resizes it DOES NOT auto-scroll so what scrolled to stays visible
    Given I am signed in
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    And the page is at the bottom
    When I scroll up to the second message
    Then resizing the browser does not auto-scroll the conversation
