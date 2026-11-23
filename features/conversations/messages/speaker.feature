@javascript
Feature: Speaker playback
  The speaker controller's sentence playback across streams and morphs

  Scenario: Speaker controller values do not revert when the page morphs
    Given I am signed in
    And I am on the hello-claude conversation
    When the second assistant message's speaker values are forced
    And a new assistant message morphs the page
    Then the second assistant message keeps its forced speaker values

  Scenario: Press play on a new conversation, ask a question which loads a new page, the answer plays back after a STREAM, and again for a second question that MORPHS
    Given the voice feature is enabled
    And I am signed in
    And I am on Samantha's new message page with the mic enabled
    When the user speaks "You there?" creating a conversation
    Then the new page's reply spoke to sentence "0" and finished with nothing
    When the new page's reply streams "Yes, I'm here. Are you there?" while thinking
    Then the new page's reply spoke to sentence "1" and finished with nothing
    When the new page's reply streams "Yes, I'm here. Are you there?" to settle
    Then the new page's reply spoke to sentence "2" and finished with the last message
    When the user speaks "Yes" morphing the reply "That's great."
    Then the morphed page's reply spoke to sentence "1" and finished with the last message

  Scenario: Loading an existing conversation, pressing play does not play anything, but then asking a question causes just that answer to play back
    Given the voice feature is enabled
    And I am signed in
    And I am on the hello-claude conversation with the mic enabled
    Then nothing has played back on the existing conversation
    When the user speaks "You there?" and the reply streams "Yes, I'm here. Are you there?"
    Then the reply finished with the last message and spoke to sentence "2"
    When the user speaks "Yes" and the reply streams "That's great."
    Then the reply finished with the last message and spoke to sentence "1"

  Scenario: Arriving at a conversation from the sidebar, asking a question plays back just that answer
    Given the voice feature is enabled
    And I am signed in
    And I arrive at the hello-claude conversation from the sidebar with the mic enabled
    When the user speaks "You there?" and the reply streams "Yes, I'm here. Are you there?"
    Then the reply finished with the last message and spoke to sentence "2"
    And the first assistant message spoke to sentence "0"

  Scenario: While speaking a long reply if you click stop it stops speaking right away even though more streams in, and when re-enabled it does not play the existing message.
    Given the voice feature is enabled
    And I am signed in
    And I am on the hello-claude conversation with the mic enabled
    And the pre-existing latest message is recorded
    When the user speaks "Write me a poem." and the reply streams the long first sentence while thinking
    Then the long reply spoke to sentence "1" and the recorded message finished
    When the mic is disabled
    And the reply streams the long final sentence to settle
    Then the latest message finished and the long reply spoke to sentence "1"
    When the mic is enabled again
    Then the latest message finished and the long reply spoke to sentence "1"
    When the user speaks "You there?" and the reply streams "Yes, I'm here. Are you there?"
    Then the reply finished with the last message, spoke to sentence "2", and the long reply still spoke to sentence "1"

  Scenario: If a second assistant reply comes AFTER finishing the first one, the second reply auto-plays
    Given the voice feature is enabled
    And I am signed in
    And I am on the hello-claude conversation with the mic enabled
    When the user speaks "What is the weather in Austin?" and the reply streams "One second. I'm checking the weather."
    Then the reply finished with the last message and spoke to sentence "2"
    When a second reply is stubbed and streams "The weather is sunny with a high of 100 degrees."
    Then the message count grew by one
    And the reply finished with the last message and spoke to sentence "1"

  Scenario: If a second assistant reply comes DURING speaking the first one, the first still finishes and then the second auto plays
    Given the voice feature is enabled
    And I am signed in
    And I am on the hello-claude conversation with the mic enabled
    When the user speaks "What is the weather in Austin?" and the first reply streams "One second. I'm checking the weather." while thinking
    Then the pre-existing message finished and the first reply spoke to sentence "1"
    When a second reply is stubbed and the first reply streams "The weather is sunny with a high of 100 degrees." targeting the second
    Then four assistant messages are on screen
    And the second reply spoke to sentence "0"
    When the first reply streams "One second. I'm checking the weather." to settle
    Then the first reply spoke to sentence "2"
    And the second reply finished and spoke to sentence "1"

  Scenario: If an assistant reply turns into a tool call (which hides the message), when the final assistant reply comes it auto plays
    Given the voice feature is enabled
    And I am signed in
    And I am on the hello-claude conversation with the mic enabled
    When the user speaks "What is the weather in Austin?" and the reply streams ""
    And the reply turns into a tool call and refreshes
    Then the assistant message disappeared from screen
    When a second reply is stubbed and streams "I've checked the weather and it's sunny today."
    Then a new assistant message appeared on screen
    And the reply finished with the last message and spoke to sentence "1"

  Scenario: While a reply is read aloud its play button shows stop, and clicking stop ends the reading but not the next reply
    Given the voice feature is enabled
    And I am signed in
    And I am on the hello-claude conversation with the mic enabled
    When the user speaks "Write me a poem." and the reply streams the long first sentence while thinking
    Then the long reply spoke to sentence "1"
    And the long reply being read aloud shows stop
    When I click stop on the long reply
    Then clicking stop flips the long reply back to play
    When the reply streams the long final sentence to settle
    Then the long reply spoke to sentence "1"
    When the user speaks "You there?" and the reply streams "Yes, I'm here. Are you there?"
    Then the reply finished with the last message and spoke to sentence "2"

  Scenario: Once a reply has been read aloud its play button goes back from stop to play
    Given the voice feature is enabled
    And I am signed in
    And I am on the hello-claude conversation with the mic enabled
    When the user speaks "You there?" and the reply streams "Yes, I'm here. Are you there?"
    Then the long reply's play button reappears once it has been read
