@javascript
Feature: Conversations sidebar
  Hover options, inline editing, deletion, and the nav drawer on narrow screens

  Scenario: Options icon shows a tooltip
    Given I am signed in
    When I hover the greeting conversation
    Then the options icon shows its tooltip

  Scenario: Clicking conversation edit option enables edit, unfocusing submits it
    Given I am signed in
    When I hover the greeting conversation
    And I open the conversation options
    And I click the edit option
    And I rename the conversation to "Meeting Samantha Jones" by clicking elsewhere
    Then the conversation shows "Meeting Samantha Jones"
    And the conversation is titled "Meeting Samantha Jones" in the database

  Scenario: Clicking conversation edits icon enables edit, pressing Enter submits it
    Given I am signed in
    When I hover the greeting conversation
    And I open the conversation options
    And I click the edit option
    And I rename the conversation to "Meeting Samantha Jones" with enter
    Then the conversation shows "Meeting Samantha Jones"
    And the conversation is titled "Meeting Samantha Jones" in the database

  Scenario: Clicking conversation edits it and pressing Esc aborts the edit and does not save
    Given I am signed in
    When I hover the greeting conversation
    And I open the conversation options
    And I click the edit option
    And I rename the conversation to "Meeting Linda" and press esc
    Then the conversation shows "Meeting Samantha"
    And the conversation is titled "Meeting Samantha" in the database

  Scenario: Clicking the conversation delete, when you ARE NOT on this conversation, deletes it and the url does not change
    Given I am signed in
    When I hover the greeting conversation
    And I open the conversation options
    And I click the delete option
    Then I see the "Deleted conversation" alert
    And the path has not changed since I signed in

  Scenario: Clicking the conversation delete, when you ARE not on this conversation, deletes it and redirects you to a new conversation when assistants page is enabled
    Given the assistants page feature is enabled
    And I am signed in
    And I am on the greeting conversation
    When I hover the greeting conversation
    And I open the conversation options
    And I click the delete option
    Then I see the "Deleted conversation" alert
    And I am on the assistants page

  Scenario: Clicking the conversation delete, when you ARE not on this conversation, deletes it and redirects you to a new conversation when assistants page is disabled
    Given the assistants page feature is disabled
    And I am signed in
    And I am on the greeting conversation
    When I hover the greeting conversation
    And I open the conversation options
    And I click the delete option
    Then I see the "Deleted conversation" alert
    And I am on my first assistant's new message page

  Scenario: The deleted conversation alert goes away when you open another conversation
    Given I am signed in
    When I hover the greeting conversation
    And I open the conversation options
    And I click the delete option
    Then I see the "Deleted conversation" alert
    When I hover the javascript conversation
    Then the alert is still visible
    And I open the javascript conversation
    And the alert is hidden

  Scenario: On a narrow screen, clicking a conversation closes the nav drawer so the conversation is visible
    Given I am signed in
    When the screen is narrow
    And I toggle the nav open
    Then the nav column is visible
    And I open the greeting conversation from the nav
    Then the nav column is hidden
    And I am on the greeting conversation's messages
    And the first message is the hear-me fixture message
