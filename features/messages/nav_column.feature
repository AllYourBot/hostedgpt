@javascript
Feature: Nav column
  Conversation navigation, sidebar handles, keyboard toggles, and assistant links

  @skip
  Scenario: Clicking conversation in the left column updates the right and preserves scroll position of the left
    Then this scenario is skipped in the system suite

  Scenario: Clicking a conversation title from the assistants page (before visiting any chat) loads the conversation
    Given the assistants page feature is enabled
    And I am signed in
    When I visit the root path
    Then I am on the assistants page
    When I click the conversation title "Meeting Samantha"
    Then I am on version 1 of the "greeting" conversation
    And the "greeting" conversation's first message is displayed

  Scenario: Hovering the Assistants heading shows a plus icon that opens the New Assistant page
    Given the assistants page feature is enabled
    And I am signed in
    When I visit the root path
    Then I am on the assistants page
    Then the plus icon stays hidden until the Assistants heading is hovered
    When I hover the Assistants heading
    Then the plus icon shows its tooltip
    When I click the plus icon
    Then I am on the new settings assistant page

  Scenario: Clicking conversations in the left side updates the right column and path when assistants page is enabled
    Given the assistants page feature is enabled
    And I am signed in
    When I visit the root path
    Then I am on the assistants page
    And I visit my first assistant's new message page
    Then the first assistant is selected in the nav
    When I click the conversation title "Meeting Samantha"
    Then I am on version 1 of the "greeting" conversation
    And the "greeting" conversation's assistant is selected in the nav
    And the "greeting" conversation's first message is displayed
    When I click the conversation title "Javascript popstate"
    Then I am on version 1 of the "javascript" conversation
    And the "javascript" conversation's assistant is selected in the nav
    And the "javascript" conversation's first message is displayed
    When I click the conversation title "Ruby version"
    Then I am on version 1 of the "ruby_version" conversation
    And the "ruby_version" conversation's assistant is selected in the nav
    And the "ruby_version" conversation's first message is displayed

  Scenario: Clicking conversations in the left side updates the right column and path when assistants page is disabled
    Given the assistants page feature is disabled
    And I am signed in
    When I visit the root path
    Then the root path redirects to a conversation page
    And I visit my first assistant's new message page
    Then the first assistant is selected in the nav
    When I click the conversation title "Meeting Samantha"
    Then I am on version 1 of the "greeting" conversation
    And the "greeting" conversation's assistant is selected in the nav
    And the "greeting" conversation's first message is displayed
    When I click the conversation title "Javascript popstate"
    Then I am on version 1 of the "javascript" conversation
    And the "javascript" conversation's assistant is selected in the nav
    And the "javascript" conversation's first message is displayed
    When I click the conversation title "Ruby version"
    Then I am on version 1 of the "ruby_version" conversation
    And the "ruby_version" conversation's assistant is selected in the nav
    And the "ruby_version" conversation's first message is displayed

  Scenario: Nav column close handle shows proper tooltip and hides/shows column when clicked
    Given I am signed in
    Then the nav column is visible
    And the left handle is shown with its "Close sidebar" tooltip
    And the right handle is hidden
    When I click the sidebar handle
    Then the nav column is hidden
    And the right handle is shown with its "Open sidebar" tooltip
    And the left handle is hidden
    When I click the sidebar handle
    Then the nav column is visible
    And the left handle is shown with its "Close sidebar" tooltip
    And the right handle is hidden

  Scenario: Refreshing the page after closing sidebar keeps it closed
    Given I am signed in
    And I close the sidebar
    When I refresh the page
    Then the nav column is hidden

  Scenario: Refreshing the page after closing and re-opening sidebar keeps it opened
    Given I am signed in
    And I close the sidebar
    And I open the sidebar
    When I refresh the page
    Then the nav column is visible

  Scenario: The assistants page has a handle which closes the sidebar and keeps it closed after a refresh
    Given the assistants page feature is enabled
    And I am signed in
    When I visit the root path
    Then I am on the assistants page
    And the nav column is visible
    When I close the sidebar
    And I refresh the page
    Then the nav column is hidden

  Scenario: Meta+. opens and closes nav column
    Given I am signed in
    Then the nav column is visible
    And the left handle is shown
    And the right handle is hidden
    When I press the keyboard shortcut "meta+."
    Then the nav column is hidden
    And the right handle is shown
    And the left handle is hidden
    When I press the keyboard shortcut "meta+."
    Then the nav column is visible
    And the left handle is shown
    And the right handle is hidden

  Scenario: Meta+shift+s opens and closes nav column
    Given I am signed in
    Then the nav column is visible
    And the left handle is shown
    And the right handle is hidden
    When I press the keyboard shortcut "meta+shift+s"
    Then the nav column is hidden
    And the right handle is shown
    And the left handle is hidden
    When I press the keyboard shortcut "meta+shift+s"
    Then the nav column is visible
    And the left handle is shown
    And the right handle is hidden

  Scenario: Clicking the assistant name in the nav column starts a new conversation
    Given I am signed in
    And I visit the greeting conversation's show page
    When I click the first assistant's name in the nav
    Then I am on my first assistant's new message page
    When I hover the second assistant and click its new-conversation pencil
    Then I am on the second assistant's new message page

  Scenario: A long assistant name truncates before the context files icon so the selected assistant still shows it
    Given Samantha is renamed to a very long name
    And I am signed in
    And I am on her new message page
    Then her name truncates in the nav
    And her context files icon is not cut off
    And hovering her name shows the context files popout
