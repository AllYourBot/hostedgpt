---
paths:
  - "test/controllers/**"
---

# Controller Tests

## Test naming

Same ALL-CAPS-the-distinguishing-word convention as `unit_test.md`:

- `"should return unauthorized if authorization header IS MISSING"`
- `"should return unauthorized if authorization header IS INCORRECT"`
- `"should return unauthorized if authorization header IS NOT CONFIGURED"`

## Basic test set

For implemented verbs only:

- `"should show [entity]"`
- `"should edit [entity]"`
- `"should update [entity]"`
- `"should destroy [entity]"`

## Consolidate situations, don't split assertions

If one request to an endpoint has multiple expected side effects, write ONE test for that SITUATION with multiple assertions (each with a helpful failure message). Bad:

```ruby
test "should enqueue a job on update"
test "should send a notification on update"
```

Good:

```ruby
test "on update should enqueue a job & send a notification"
```

## Use URL helpers and fixtures

Use `user_url(@user)` etc., not hardcoded URL strings. For retrieve/edit/destroy, use fixtures, not custom AR objects. If the same fixture is used repeatedly, put it as an ivar in `setup`.

## Controllers that render UI

When a controller returns UI for users, treat controller tests partly like system tests — assert on what's rendered (`assert_select`, and the helpers in `test/support/view_helpers.rb`).

## A view branch no test reaches is untested by every test you have

A conditional arm in a view renders only when some state produces it, so a controller test that never produces that state passes while the arm is outright broken — a missed rename raises a `NameError` at render time and nothing before then notices. When you add or edit an arm in a view, name the state that reaches it and write the request that produces it. States the test env never produces on its own are the ones most often left uncovered: a feature flag off by default in `config/options.yml`, or a user preference override.

## Testing CSRF behavior: forgery protection is OFF in the test env

`config/environments/test.rb` sets `allow_forgery_protection = false`, so a test that posts a bogus `authenticity_token` passes vacuously. Turn it on for the one request (`ActionController::Base.allow_forgery_protection = true`, restored in an `ensure`) — on `ActionController::Base`, not a subclass, because the OmniAuth request phase reads the base config too.
