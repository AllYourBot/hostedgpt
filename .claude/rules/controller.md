---
paths:
  - "app/controllers/**"
  - "config/initializers/filter_parameter_logging.rb"
---

# Controller

## Including concerns

Default: multiple concerns on a single `include` line.

```ruby
include Authenticate, HasConversationStarter
```

Split onto multiple `include` lines when:

- The list is getting long.
- There's an explicit include-order dependency. Put the comment **inline on the dependent include line itself**, not on a line above the include block — that way the comment travels with the constraint if anyone reorders later.
- It makes sense to logically group related concerns onto their own line.

## Tests are mandatory

Every controller has a corresponding test file at `test/controllers/<...>/<name>_controller_test.rb`. Two rules:

- **New controller → create the test file.** Cover each implemented action.
- **New or changed action on an existing controller → update the test.** Adding a new action means a new test in the existing file; changing the response shape, redirect target, side effects, or auth behavior of an existing action means updating the test that covers it.

Conventions live in [[controller_test]] and auto-load when you touch the test file.

## A param or log line that carries a secret needs a `filter_parameters` entry

The request log prints every param at `info`, and `config/initializers/filter_parameter_logging.rb` is the only thing between that line and the value. When an endpoint carries a credential (an API key, an OAuth token, a password), make sure its key matches an entry there. Two traps:

- Entries substring-match, so `:token` also hides `token_count`; that is why `filter_regexp` takes exemptions. Add an exemption when a short key has diagnostic siblings.
- `Rails.logger` interpolation bypasses the filter entirely. Log a record's id or a token's length, never the value.

## A `.json` request renders every ivar, including what the HTML view hides

`ApplicationController#default_render` answers any `.json` request by serializing the action's ivars with `as_json`, so an encrypted column comes back decrypted (`APIService#token`) even when the view deliberately never prints it. When a controller exposes records whose secrets belong to someone other than the viewer, refuse API requests (`head :not_acceptable if api_request?`), as `Admin::ApplicationController` does, and test the `.json` URL.
