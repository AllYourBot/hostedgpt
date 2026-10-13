---
paths:
  - "test/**"
---

# Tests (general)

Always pass a failure message to assertions — they self-document the test:

```ruby
assert_equal x, y, "The value of y should not have changed"
```
## Don't name private test helpers `message`

Minitest's assertion API is `assert_X(value, message = nil)`, where `message` is the failure-message builder it calls internally. Defining a private test-class helper named `def message(...)` shadows that and breaks **every** `assert_X` in the file — with a confusing `ArgumentError: wrong number of arguments (given 1, expected 0; required keywords: …)` pointing at the failing assertion line, not the helper.

Pick a different name (`gmail_message`, `build_message`, `fake_message`). The same applies to other minitest internals — don't define helpers named `assertions`, `name`, or `tests`.
