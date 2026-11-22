@javascript
Feature: Settings people
  A signed-in user edits their person record from the settings page

  Scenario: Updating the person's email and name with a password
    Given I am signed in as the registered keith person
    And I am on the settings person edit page
    When I update my email and name appending "-2" and set the password
    Then I see the "Saved" alert
    And I stay on the settings person edit page
    And the person's email and name are updated

  Scenario: Updating the person's email and name without setting the password
    Given I am signed in as the registered keith person
    And I am on the settings person edit page
    When I update my email and name appending "-2" without a password
    Then I see the "Saved" alert
    And I stay on the settings person edit page
    And the person's email and name are updated

  Scenario: Disconnecting Gmail and offering to enable it again
    Given I am signed in as the registered keith person
    And the google tools feature is enabled
    And the Google SDK reauthentication always succeeds
    And I am on the settings person edit page
    Then the disconnect Gmail control is offered
    When I disconnect Gmail confirming the dialog
    Then I see the "Disconnected" alert
    And I stay on the settings person edit page
    And I see "Enable Gmail"
    And the disconnect Gmail control is no longer offered
    And the disconnect Google Tasks control is offered
    And Gmail is no longer connected while Google Tasks still is

  Scenario: The settings sidebar links to the assistants page instead of listing each assistant
    Given I am signed in as the registered keith person
    And I am on the settings person edit page
    When I follow "Assistants" within the settings menu
    Then I am on the settings assistants page
    And the settings menu has no assistant avatars
