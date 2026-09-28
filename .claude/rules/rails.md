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
