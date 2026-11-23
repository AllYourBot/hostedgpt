@javascript
Feature: Composer autogrow
  The textarea grows and shrinks with its content

  Scenario: Textarea grows in height as newlines are added and shrinks in height when they are removed
    Given I am signed in
    And I select the greeting conversation from the nav
    And the images have loaded
    And I record the composer height
    When I type "1" in the composer
    And I press shift+enter and stay at the bottom
    Then the composer grows taller
    And I record the composer height
    When I type "2" in the composer
    And I press shift+enter and stay at the bottom
    Then the composer grows taller
    And I record the composer height
    When I press backspace
    Then the composer gets shorter
    And I record the composer height
    When I press backspace twice
    Then the composer gets shorter
    And I record the composer height
    When I press backspace twice
    Then the composer keeps its height

  Scenario: When large block of text is pasted, textarea grows in height and auto-scrolls to stay at the bottom
    Given I am signed in
    And I select the greeting conversation from the nav
    And the images have loaded
    And I record the composer height
    When I paste a large block of text staying at the bottom
    Then the composer grows taller

  Scenario: When large block of text is pasted, textarea grows in height and DOES NOT auto-scroll so what scrolled to stays visible
    Given I am signed in
    And I select the greeting conversation from the nav
    And the images have loaded
    And the page is at the bottom
    When I scroll up to the second message
    And I record the composer height
    And I paste a large block of text without scrolling
    Then the composer grows taller
