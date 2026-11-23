@javascript
Feature: Code block rendering
  Code fences, clipboard copying, and viewport behavior

  Scenario: Code block renders with a proper header
    Given I am signed in
    And I am on the greeting conversation
    Then the last message's code block header shows "sql" and "Copy code" but not "Copied"

  Scenario: Clicking copy on code block changes icon and copies to clipboard
    Given I am signed in
    And I am on the greeting conversation
    Then the clipboard is empty
    When I copy the code block
    Then the clipboard holds "SELECT * FROM users"
    And the last message's code block header shows "Copied" but not "Copy code"

  Scenario: Clicking copy on the overall message that includes code copies everything to clipboard and adds in the backticks
    Given I am signed in
    And I am on the greeting conversation
    Then the clipboard is empty
    When I copy the overall last message
    Then the clipboard holds the im-a-bot message's stripped content
    And the copy icon shows its "Copied!" tooltip

  Scenario: Using the overall keyboard shortcut for copying copies the code block within the last message
    Given I am signed in
    And I am on the greeting conversation
    Then the clipboard is empty
    When I press the copy keyboard shortcut
    Then the clipboard holds "SELECT * FROM users"

  Scenario: Using the overall keyboard shortcut for copying copies the full last message where there is NO code block
    Given I am signed in
    And I am on the javascript conversation
    Then the clipboard is empty
    When I press the copy keyboard shortcut
    Then the clipboard holds the javascript conversation's last message

  Scenario: Code block shrinks with the viewport instead of forcing the page wider
    Given I am signed in
    And the "im_a_bot" message holds a long SQL line
    And I am on the greeting conversation
    Then the conversation shrinks with the viewport down to 300px
