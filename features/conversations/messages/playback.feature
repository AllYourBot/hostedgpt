@javascript
Feature: Message playback
  Voice playback controls and morph stability

  Scenario: Sentence controller values do not revert when the page morphs
    Given the voice feature is enabled
    And I am signed in
    And I am on the hello-claude conversation
    When the second assistant message's playback index is forced to 123
    And a new assistant message morphs the page
    Then the second assistant message keeps its 123 playback index

  @skip
  Scenario: When page loads a play buttons are visible, click play changes it to stop, audio plays, and it reverts when audo is completed and it can be clicked again
    Then this scenario is skipped in the system suite

  Scenario: Playback controller does not reconnect when another chunk of message streams
    Given the voice feature is enabled
    And I am signed in
    And I am on the hello-claude conversation
    When the second assistant message and its inner message are tagged for morph monitoring
    And the versioned reply streams "The quick brown fox jumped over the lazy dog."
    Then the second assistant message streamed its update
    And the second assistant message stayed tagged
    And the inner message was replaced

  Scenario: When stop button is pressed it stops playback
    Given the voice feature is enabled
    And I am signed in
    And I am on the hello-claude conversation
    Then the second assistant message's play button is visible and stop is not
    When I click play on the second assistant message
    Then play becomes stop on the second assistant message
    When I click stop on the second assistant message
    Then stop flips back to play on the second assistant message
