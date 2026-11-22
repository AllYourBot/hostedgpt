Feature: Authentications
  The login page is readable in the browser's preferred color scheme

  @javascript
  @dark-mode-emulation
  Scenario: The sign up link on the login page is readable when the browser prefers dark mode
    Given the browser prefers dark mode
    And I am logged out
    Then the sign up link is much lighter than the dark login background
