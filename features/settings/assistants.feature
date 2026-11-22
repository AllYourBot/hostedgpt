@javascript
Feature: Settings assistants
  An admin manages assistants from the settings pages

  Scenario: The assistants page renders each assistant with its service logo avatar
    Given I am signed in
    And I am on the settings assistants page
    Then each assistant renders with its service logo avatar

  Scenario: Should create assistant
    Given I am signed in
    And I am on the new settings assistant page
    When I create an assistant with Samantha's details
    Then I see the "Saved" alert

  Scenario: Should update Assistant
    Given I am signed in
    And I am on the settings assistant edit page for Samantha
    When I update her details appending "-2"
    Then I see the "Saved" alert

  Scenario: Conversation starters saved on the Assistant update page are suggested on a new conversation
    Given I am signed in
    And I am on the settings assistant edit page for Samantha
    When I set the conversation starters
    And I save the settings form
    Then I see the "Saved" alert
    And the first conversation starter field keeps its value
    And I am on a new conversation with Samantha
    Then I see "What should I cook tonight?"
    When I click the conversation starter "Plan my week"
    Then the starter's question is sent as written

  Scenario: A second save to the Assistant update page shows the notification again and it dismisses with the X
    Given I am signed in
    And I am on the settings assistant edit page for Samantha
    When I save the settings form
    Then I see the "Saved" alert
    When I save the settings form again
    Then I see the "Saved" alert
    And I dismiss the alert
    Then I do not see "Saved"

  Scenario: Should upload and remove a context file
    Given I am signed in
    And I am on the settings assistant edit page for Samantha
    Then the assistant's context section is shown
    When I attach the test document
    Then I see the "File uploaded" alert
    And I see "test_document.txt"
    When I remove the uploaded document confirming the dialog
    Then I do not see "test_document.txt"
    And I see the "File removed" alert
