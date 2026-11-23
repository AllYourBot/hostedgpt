@javascript
Feature: Composer attachments
  Image previews in the composer

  Scenario: Attaching an image to the composer shows a preview, keeps submit hidden, and refocuses input
    Given I am signed in
    Then the document previews are hidden
    When I attach the cat image
    Then a preview is shown with a data-uri image
    Then the submit button is hidden
    And the composer input is focused

  Scenario: Attaching an image and clicking X removes the image
    Given I am signed in
    When I attach the cat image
    Then a preview is shown with a data-uri image
    When I remove the first preview via its X
    Then the document previews are hidden
    Then the submit button is hidden
    And the composer input is focused

  Scenario: Attaching multiple images to the composer shows a preview for each
    Given I am signed in
    When I attach two cat images
    Then two previews are shown and visible
    Then the submit button is hidden
    And the composer input is focused

  Scenario: Attaching multiple images and removing one keeps the other
    Given I am signed in
    When I attach two cat images
    Then two previews are shown and visible
    When I remove the first preview
    Then one preview remains and it is visible
    Then the submit button is hidden
    And the composer input is focused
