@javascript
Feature: Message HTML rendering
  Message content renders escaped, with newlines preserved

  Scenario: Html is escaped so that it renders to the user
    Given I am signed in
    And I am on the greeting conversation
    Then the first message's content renders its source text unescaped

  Scenario: Newlines within a paragraph are preserved
    Given I am signed in
    And I am on the greeting conversation
    Then the third message's content preserves its newlines
