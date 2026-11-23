@javascript
Feature: Math typesetting
  KaTeX renders math and stays readable mid-stream

  Scenario: Math typesets on page load instead of showing raw delimiters
    Given I am signed in
    And the greeting conversation's "im_a_bot" message holds math content
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    Then the math message typesets with no raw delimiters

  Scenario: Streamed math typesets after a turbo broadcast
    Given I am signed in
    And the greeting conversation's "im_a_bot" message holds math content
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    When the stub reply is updated to the math content and broadcast
    Then the settled math typesets
    And the settle broadcast flips the render gate back off

  Scenario: Mid-stream broadcast leaves math as readable source
    Given I am signed in
    And the greeting conversation's "im_a_bot" message holds math content
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    When the stub reply is updated to the math content and broadcast while thinking
    Then the streamed message flags its content div as streaming
    And KaTeX must not re-typeset while the reply streams
    And the math source stays readable mid-stream
