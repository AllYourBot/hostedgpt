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

When a controller returns UI for users, treat controller tests partly like system tests — assert on what's rendered:

```ruby
test "Submitting the form with a bad email shows an error message"
```

Helpers available: `click_on`, `assert_text`, `assert_selector`, etc. Full list in `test/support/controller_interaction_helpers.rb` and `test/support/controller_integration_interaction_helpers.rb`.

## A view branch no test reaches is untested by every test you have

A conditional arm in a view renders only when some state produces it, so a controller test that
never produces that state passes while the arm is outright broken — a missed rename raises a
`NameError` at render time and nothing before then notices. The "assign a plan" dropdown (then on
the team page) shipped that way: every test either had the plan already held or had no inventory
at all, so the arm never rendered and the page would have 500'd on the first real purchase. When
you add or edit an arm in a view, name the state that reaches it and write the request that produces it.
Two states the test env never produces on its own, and therefore the two most often left
uncovered: **hosted mode** (tests run self-hosted, so hosted-only UI renders only inside
`Jumpstart.config.stub(:self_hosted?, false)`) and **anything fetched from the portal** (nil
unless stubbed, which renders the outage arm rather than the real one).

## Testing CSRF behavior: forgery protection is OFF in the test env

`config/environments/test.rb` sets `allow_forgery_protection = false`, so a test that posts a bogus `authenticity_token` passes vacuously. Wrap the request in `with_forgery_protection` (`test/support/forgery_protection_helpers.rb`), which flips the flag on `ActionController::Base` — not a subclass, because `omniauth-rails_csrf_protection`'s `TokenVerifier` reads `ActionController::Base.config`, so the same flip arms the `POST /users/auth/<provider>` request phase too. With `show_exceptions = :rescuable`, an unrescued `InvalidAuthenticityToken` comes back as a 422 response (`assert_response :unprocessable_content`), not an exception — don't `assert_raises` it.
