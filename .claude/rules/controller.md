---
paths:
  - "app/controllers/**"
  - "config/initializers/filter_parameter_logging.rb"
  - "test/config/parameter_filtering_test.rb"
---

# Controller

## Namespacing

For a namespaced controller, do NOT use `class Namespace::FooController`. Open the module on its own line and indent the class:

```ruby
# Good
module Webhooks
  class InboundEmailsController < ApplicationController
    # ...
  end
end

# Bad
class Webhooks::InboundEmailsController < ApplicationController
  # ...
end
```

Why: Ruby constant lookup is lexical. The shorthand `class Namespace::FooController` does NOT open `Namespace` as a lexical scope, so any constant under `Namespace` (concerns, sibling controllers, error classes) has to be referenced with its full path. The long form lets everything in `Namespace::*` resolve by short name:

```ruby
module Webhooks
  class InboundEmailsController < ApplicationController
    include Authenticated   # finds Webhooks::Authenticated
    # vs the shorthand form, which would require:
    # include Webhooks::Authenticated
  end
end
```

## Including concerns

Default: multiple concerns on a single `include` line.

```ruby
include Authenticated, Impersonatable, RateLimited
```

Split onto multiple `include` lines when:

- The list is getting long.
- There's an explicit include-order dependency. Put the comment **inline on the dependent include line itself**, not on a line above the include block — that way the comment travels with the constraint if anyone reorders later. Example:

  ```ruby
  include Authenticated
  include AuditLogged # must come after Authenticated — reads current_user to attach the actor
  include RateLimited
  ```

- It makes sense to logically group related concerns onto their own line (e.g. all the auth-related concerns on one line, all the rate-limiting concerns on another).

## Tests are mandatory

Every controller has a corresponding test file at `rails/test/controllers/<...>/<name>_controller_test.rb`. Two rules:

- **New controller → create the test file.** Cover each implemented action.
- **New or changed action on an existing controller → update the test.** Adding a new action means a new test in the existing file; changing the response shape, redirect target, side effects, or auth behavior of an existing action means updating the test that covers it.

Conventions (naming, fixtures vs inline AR objects, treating UI-rendering controllers like system tests) live in [[controller_test]] and auto-load when you touch the test file.

## A param or log line that carries a secret, a message body, or a phone/email needs a `filter_parameters` entry

The request log prints every param at `info`, and `config/initializers/filter_parameter_logging.rb` is the only thing between that line and the value. `Api::ResidentialProxyController` accepted the Decodo proxy as a `user:pass@host` URL for months before anyone read a1's `Parameters:` line against it, so the password landed in the log on every portal re-push. When an endpoint or webhook payload carries a credential, a message body, a phone or email, or a bearer capability, add the key to that initializer and pin it in `test/config/parameter_filtering_test.rb` with the real payload shape (nesting included — a filtered parent redacts its whole subtree). Three traps:

- Symbol entries substring-match, so `:text` would also hide `context`; use an anchored regex (`/\Atext(_markdown)?\z/`, `/\Aline\z/`) when a short key has diagnostic siblings, and add a "kept" assertion for the sibling.
- The same list becomes `ActiveRecord::Base.filter_attributes`, so `Message#text` and `User#phone` print `[FILTERED]` in dev/test `inspect`. The row is intact — read the attribute directly.
- `Rails.logger` interpolation bypasses the filter entirely. Log `user.id` / `credential.id`, never a phone, email, or URL with embedded credentials.

A value identifiable only by its content (LoopMessage embeds E.164 numbers and email handles inside `space.id` / `sender.id`) goes through the lambda entry; anything with a known key gets a key entry. Hosted-image signed ids travel in the path (`/i/<signed_id>.png`), which parameter filtering never touches — don't add a `:signed_id` entry and assume it covers them.
