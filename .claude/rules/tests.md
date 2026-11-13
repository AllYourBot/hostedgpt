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

## Don't assert a database sort against Ruby's `.sort`

Postgres sorts text by the database's collation, which varies by machine (`en_US.UTF-8` locally, where punctuation and case are skipped on the first pass), so `ORDER BY api_name` puts `gpt-4o` and `gpt4o`, or `Qwen` and `qwen`, in a different order than Ruby's byte-wise `Array#sort`. `assert_equal list.sort, list` passes on today's fixtures and breaks when someone adds one. Assert the fixtures you expect at fixed positions (first, last, or a pair whose order doesn't hinge on punctuation) instead.
