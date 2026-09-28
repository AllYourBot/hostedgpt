---
paths:
  - "test/fixtures/**"
---

# Fixtures

Every model should have a fixture representing a realistic example of the model. If you don't understand how the model is used by the application well enough to construct a realistic example, ask.

Name the fixture after the scenario it represents, not the model. A `Conversation` about groceries is `grocery`, not `grocery_conversation`. A `User` is `keith`, not `keith_user`.

Fixtures should reference other well named fixtures. For example, if there is an old fixture named `one`, know that it's in the process of being deprecated. You should instead find a well-named fixture of that same type and reference that one instead.

## A fixture with no explicit timestamp AGES during the suite

Rails stamps `created_at`/`updated_at` at fixture-load time, so a fixture row keeps getting older as the suite runs. Any code with a recency window — a scope like `created_before(2.minutes.ago)`, a job that sweeps rows older than N — sees that row the moment the suite has been running longer than the window. The result is a test that passes alone (fixture is seconds old) and fails deterministically in a full run, which reads as a flake and gets retried instead of fixed.

If a test asserts on what such a scope returns, clear the table in `setup` (`GmailInboundMessage.delete_all`) or set the timestamps explicitly — don't rely on the fixture being young. `DrainGmailInboundMessagesJobTest` and `GmailPushJobTest` both do this. Setting `created_at: <%= 1.minute.ago %>` in the fixture itself does NOT fix it: that's also evaluated once at load time and ages the same way.

Goal: as few fixtures as possible. Start with one and flesh it out with more realistic detail as test scenarios demand. Only add a second fixture when a distinct state is significant enough that you'll be testing for it AND it would feel convoluted or impossible to jam into the existing one.
