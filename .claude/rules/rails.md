---
paths:
  - "**"
---

# Rails

Path-specific guidance lives in narrowly-scoped rules (`model.md`, `controller_test.md`, `fixtures.md`, `stimulus.md`, `turbo.md`, etc.) that auto-load when you touch matching files.

## Constants

Do not extract a named constant for a value used in only one place. A constant earns its name only when the *same* value is referenced from multiple separate locations that must stay in sync — two methods that must agree, or a method and the test that exercises it. A single-use constant is pure indirection: the reader jumps to the definition only to find a plain literal it could have read inline, and the uppercase name implies a shared contract that does not exist.

```ruby
# Bad — HIGH_FREQUENCY_THRESHOLD is referenced exactly once
HIGH_FREQUENCY_THRESHOLD = 1.hour
def self.high_frequency_schedule?(string) = interval_for(string) <= HIGH_FREQUENCY_THRESHOLD

# Good — inline the literal; promote to a constant only when a second caller appears
def self.high_frequency_schedule?(string) = interval_for(string) <= 1.hour
```

## Endless methods and `it`

Write a method whose body is a single expression as an endless method, and use `it` in a single-line block that takes one parameter. Keep the `def`/`end` form for assignments and memoization (`def foo = @foo ||= bar` reads badly), `if`/`unless` modifiers (`def x = a if b` applies the condition to the definition, not the body), and lines over 120 columns. Keep named parameters in multi-line blocks and in a block that contains another block.

```ruby
def authenticated? = authentication.present? && authentication.persisted?
def has_documents? = documents.any? { it.file.attached? }
```

## `ActiveSupport::Notifications.subscribe` belongs in an initializer

A subscription is process-wide and lives until it is unsubscribed, so subscribing inside per-request or per-connection code (`Connection#connect`, a controller action, a job) adds another listener every call and each event then runs once per call ever made. Subscribe once at boot in `config/initializers/` and keep the handler's logic in a class it calls, as `action_cable_rebroadcast.rb` does.
