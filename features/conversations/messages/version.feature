@javascript
Feature: Conversation versions
  Version navigation between branched message histories

  Scenario: Previous icon shows tooltip and next is disabled
    Given I am signed in
    And the versioned conversation's v2 branch is trimmed past index 2
    And I am on the versioned conversation at version 2
    Then the previous version icon shows its tooltip
    And the next version icon is disabled

  Scenario: Next icon shows tooltip
    Given I am signed in
    And message3_v1 is removed from the versioned conversation
    And I am on the versioned conversation at version 1
    Then the next version icon shows its tooltip
    And the previous version icon is disabled

  Scenario: Changing conversation version morphs full page: messages change, nav does not scroll, active assistant changes
    Given I am signed in
    And message3_v1 is removed from the versioned conversation
    And I am on the versioned conversation at version 1
    Then the v1 branch's last message is the selected assistant's last message
    When the window is shortened and the nav column is scrolled down slightly
    And I switch to the next version without scrolling the nav
    Then the page is at the bottom
    And the v2 branch's last message is the selected assistant's last message
