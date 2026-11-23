@javascript
Feature: Diagram previews
  Mermaid fences render as diagrams with their source kept

  Scenario: Mermaid block renders a diagram preview and keeps its source
    Given I am signed in
    And the "im_a_bot" message holds a mermaid diagram
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    Then the diagram message previews as a diagram with its source in a disclosure

  Scenario: Invalid diagram leaves readable source and breaks nothing
    Given I am signed in
    And the "im_a_bot" message holds an invalid mermaid diagram
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    Then the invalid diagram does not preview and its source stays readable
    And past the debounce no failed-render artifacts linger

  Scenario: A cached diagram re-renders under the current theme after a flip
    Given I am signed in
    And the "im_a_bot" message holds a mermaid diagram
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    Then the diagram message previews as a diagram with its source in a disclosure
    When the theme flips and the diagram cache is evicted
    Then a fresh diagram renders under the current theme

  Scenario: Mid-stream broadcast leaves readable source and no flashing preview
    Given I am signed in
    And the "im_a_bot" message holds a mermaid diagram
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    When the stub reply holds the diagram and broadcasts while thinking
    Then the streamed message flags its content div as streaming
    And the diagram preview must not render while the reply streams
    And the diagram source stays readable mid-stream

  Scenario: Streamed diagram previews after a turbo broadcast
    Given I am signed in
    And the "im_a_bot" message holds a mermaid diagram
    And the greeting conversation has a stub assistant reply
    And I am on the greeting conversation
    When the stub reply holds the diagram and broadcasts
    Then the settled diagram previews as a diagram
    And the settle broadcast flips the render gate back off
