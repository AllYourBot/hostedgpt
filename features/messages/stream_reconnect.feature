@javascript
Feature: Stream reconnect
  Missed replies arrive when the stream reconnects

  Scenario: A reply missed while the stream was disconnected appears once it reconnects
    Given I am signed in
    And I am on the greeting conversation
    Then the stream source is connected
    When the photo-identified message is updated to "Missed while disconnected" without broadcasting
    Then I do not see "Missed while disconnected"
    When the stream connection is toggled
    Then I see "Missed while disconnected"

  Scenario: A page morph does not count as a dropped connection
    Given I am signed in
    And I am on the greeting conversation
    When the page is refreshed via Turbo.session.refresh
    Then the body recorded a morph
    And the stream source is connected
