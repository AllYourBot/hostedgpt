---
paths:
  - "test/models/**"
---

# Unit Tests

**This file is for ActiveRecord models.** A test under `test/models/` whose subject is a plain Ruby object does not follow these — creation tests then method tests in source order, and no association, scope, validation or destroy sections.

Every model needs a unit test file that closely follows this structure.

## Test naming

Test names should be intentionally repetitive across siblings — ALL CAPS the word(s) that distinguish two near-identical tests. Examples:

- `"message_inbound webhook DOES forward when number IS recognized"`
- `"message_inbound webhook DOES NOT forward and replies back when number IS NOT recognized"`
- `"message_sent webhook DOES forward when number is recognized"`
- `"message_sent webhook DOES NOT forward and NO reply back when number IS NOT recognized"`

Reserve ALL CAPS for that disambiguation only — don't capitalize random words like "WITH" or "EXITS" for emphasis.

## Required section order

### `# Association tests`

One test per association, always using fixtures:

```ruby
test "has_many conversations" do
  assert_instance_of Conversation, user(:keith).conversations.first
end
```

Then, **in the same section**, one test per custom scope defined in the model. Don't just `assert_instance_of` — assert that the right fixture comes back (add or adjust a fixture if needed to make the scope's filter meaningful). Do NOT test the auto-generated scopes; see `auto_scopes.md`.

### `# Creation tests`

Start with a minimal-attributes creation test:

```ruby
test "create with minimal possible attributes" do
  assert_nothing_raised do
    User.create!(first_name: 'Keith', last_name: 'Smith', email: 'keith@example.com')
  end
end
```

Then a single test asserting every required field and validation. Don't just check `valid?` — assert the specific error message:

```ruby
test "new enforces all required attributes and formatting" do
  user = User.new
  assert_equal ["can't be blank"], user.errors[:first_name]
  assert_equal ["can't be blank"], user.errors[:last_name]
  assert_equal ["can't be blank"], user.errors[:email]

  user = User.new(email: 'bad_email')
  assert_equal ["is invalid"], user.errors[:email]
end
```

Then additional create permutations or side-effect tests, each titled `"create with ..."`.

### `# Destroy test`

Test all destroy propagations. Destroying a `User` defaults to one made in the test with `create_disposable_user` — a fixture user's agent browser deletes a `storage/chrome-sessions` dir other workers read, and `SharedBrowserDirGuard` raises on it (see [[tests]]). Create exactly the rows you assert on:

```ruby
test "associations are removed upon destroy" do
  user = create_disposable_user
  user.conversations.create!(...)
  assert_difference "Conversation.count", -1 do
    user.destroy
  end
end
```

Only a test about a fixture user's whole data graph destroys the fixture, after `release_fixture_agent_browser(user)`. Any other model's destroy test keeps using fixture relationships for its counts.

### `# Method tests`

Tests for custom methods and notable behaviors.

## Consolidate side effects into one test

If a single situation produces multiple side effects, write ONE test with multiple assertions — not multiple tests with the same setup. Use helpful failure messages per assertion.

## Models with concerns

Do NOT duplicate the concern's tests in the model's test file. Concern functionality is tested in the concern's own test file under `test/models/concerns/` (or the parallel subdirectory).

Exception: the destroy test may assert on side effects driven by the concern, so destroy coverage stays comprehensive.
