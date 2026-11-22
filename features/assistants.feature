@javascript
Feature: Assistants page hamburger navigation
  The hamburger reveals the nav when the window is too narrow to show it

  Scenario: The hamburger reveals the nav when the window is too narrow to show it
    Given I am signed in
    And I am on the root path
    When the window is too narrow to show the nav
    Then the nav is hidden
    When I tap the hamburger
    Then the nav is shown
