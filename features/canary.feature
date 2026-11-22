@wip
Feature: System helper canary
  Exercises the shared World helper library so helper breakage surfaces here
  instead of mid-port

  @javascript
  Scenario: Browser helpers behave on a conversation page
    Given I am signed in
    And I am on the greeting conversation
    Then the message list has settled scrolled to the bottom
    And a polled assertion waits for messages to be present
    And the clipboard button on the last message shows its tooltip
    And the composer can receive the active element and keyboard events
    And all image loaders have finished

  @javascript
  Scenario: Feature stubs apply and restore within the scenario
    Given I am signed in
    When the assistants page feature is enabled
    And I visit the root path
    Then I am on the assistants page
    When the assistants page feature is disabled
    And I visit the root path
    Then the root path redirects to a conversation page

  Scenario: Fixture loading includes active storage sets
    Given I am signed in
    Then active storage fixture blobs are loaded
