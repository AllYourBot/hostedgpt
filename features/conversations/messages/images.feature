@javascript
Feature: Message images
  Image previews render and open modals

  Scenario: Images render in messages WHEN pre-processed, clicking opens modal
    Given I am signed in
    And all image variants are pre-processed
    And I am on the attachments conversation
    Then the image button and its img exist with no loader visible
    And the images have loaded
    And the image modal is hidden
    When I click the image preview button until the modal shows
    Then the modal image is visible
    When I press "esc"
    Then the modal image has closed itself

  Scenario: A message with multiple images renders one preview per image, each with its own independent modal
    Given I am signed in
    And all image variants are pre-processed
    And I am on the attachments conversation
    Then the fifth message has two previews and two modals
    And the modals are hidden
    When I click the first preview
    Then the first modal is visible
    And the second modal is not visible
    When I press "esc"
    Then the first modal has closed itself
    When I click the second preview
    Then the second modal is visible
    And the first modal is not visible

  @image-variant-stubs
  Scenario: Images eventually render in messages WHEN NOT pre-processed, clicking opens modal
    Given I am signed in
    And image variant processing is simulated as not-yet-processed
    And I am on the attachments conversation
    Then the image button, img, and modal exist
    And the img becomes visible within 5 seconds
    And the images have loaded
    And the image modal is hidden
    When I click the image preview button until the modal shows
    Then the modal image becomes visible within 0.6 seconds
    When I press "esc"
    Then the modal image has closed itself

  @image-variant-stubs
  Scenario: Ensure page scrolls back down to the bottom after an image pops in late
    Given I am signed in
    And image variant processing is simulated as not-yet-processed
    And I am on the attachments conversation
    Then the image container and its img exist
    When the images load while the page is at the bottom
    Then the page is at the bottom after the image loads

  @image-variant-stubs
  Scenario: Images in previous messages remain after submitting a new message, they should not display a new spinner
    Given I am signed in
    And image variant processing is simulated as not-yet-processed
    And the attachments conversation's third image is waiting to render
    When I submit "hello?" with ENTER
    Then the composer is blank
    And the third message's image is visible
    When I submit "hello?" with ENTER
    Then the composer is blank
    And the third message's image is visible
