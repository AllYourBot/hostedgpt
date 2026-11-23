@javascript
Feature: Conversation messages
  Message actions, regeneration, retries, AskUser, stalls, and morphing

  Scenario: Clipboard icon shows tooltip
    Given I am signed in
    And the user has 15 conversations
    And I am on the greeting conversation
    Then the clipboard icon on the last message shows its tooltip

  Scenario: Clicking clipboard icon changes the tooltip & icon to check, mousing out changes it back
    Given I am signed in
    And the user has 15 conversations
    And I am on the greeting conversation
    When I copy the last message
    Then the clipboard tooltip says "Copied!"
    When I move to the regenerate icon
    Then the clipboard tooltip says "Copy"

  Scenario: Regenerate icon shows tooltip
    Given I am signed in
    And the user has 15 conversations
    And I am on the greeting conversation
    Then the regenerate icon on the last message shows its tooltip

  Scenario: Clicking regenerate icon shows menu and triggers re-generation
    Given I am signed in
    And the user has 15 conversations
    And I am on the greeting conversation
    When I open the regenerate menu on the last message
    Then the menu lists both assistants
    And the last message is from the current assistant
    When I pick the other assistant from the menu
    Then the last message is from the other assistant
    And I am on version 2 of the conversation

  Scenario: Regenerate menu keeps every assistant reachable when it is taller than the space above a short conversation
    Given I am signed in
    And the user has 6 extra assistants
    And I am on the ruby version conversation
    When I open the regenerate menu on the last message
    Then no assistant in the regenerate menu is clipped out of the messages pane
    And picking the first assistant in the menu regenerates with it

  Scenario: A failed response shows a retry button which regenerates the reply
    Given I am signed in
    And the user has 15 conversations
    And the greeting conversation has an unanswered question
    And its latest message is a failed blank response
    When I re-open the greeting conversation
    Then a retry button is offered without hovering
    When I click retry
    Then clicking retry replaces the failed reply
    And I am on version 2 of the conversation

  Scenario: A reply cut off at the token limit shows a continue button which asks the assistant to keep going
    Given I am signed in
    And the user has 15 conversations
    And the greeting conversation's latest message is truncated
    When I re-open the greeting conversation
    Then a continue button is offered without hovering
    When I click continue
    Then clicking continue asks the assistant to keep going
    And no continue buttons remain

  Scenario: An AskUser question shows its choices as buttons and clicking one answers it
    Given I am signed in
    And the user has 15 conversations
    And the greeting conversation has an AskUser exchange
    When I re-open the greeting conversation
    Then the choices show as buttons without hovering
    When I click the Pro choice
    Then clicking Pro answers the question
    And no ask-user prompts remain

  Scenario: A stalled response shows a retry button once the stream goes quiet
    Given I am signed in
    And the user has 15 conversations
    And the greeting conversation has an unanswered question
    When I re-open the greeting conversation
    Then retry stays hidden while the stream is still expected
    And the thinking indicator is showing
    When the stream watchdog is shortened to 0.2 seconds
    Then retry appears once the stream has gone quiet
    And the thinking indicator gives way to retry

  Scenario: Submitting a message with ENTER inserts two new messages with morphing
    Given I am signed in
    And the user has 15 conversations
    And I am on the greeting conversation
    Then submitting "Watch me appear" with ENTER inserts two new messages with morphing

  Scenario: When the AI replies with a message it appears with morphing
    Given I am signed in
    And the user has 15 conversations
    And the greeting conversation has a stub assistant reply
    When I re-open the greeting conversation
    Then the last message shows the stub content
    And the AI reply streams its full content with morphing and scrolling
