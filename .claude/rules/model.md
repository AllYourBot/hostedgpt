---
paths:
  - "app/models/*.rb"
---

# Model

## Keep the model file slim

The model file is the essential overview of what this model is — its associations, its core attributes, its public API. A developer ramping up should be able to read it top-to-bottom and understand the shape of the thing without wading through implementation details.

Ancillary logic — anything specifically about one aspect of the model (parsing inbound data, handling attachments, broadcasting changes, etc.) — belongs in a concern at `app/models/<model_name>/<aspect>.rb`. The signal that something is a candidate: a self-contained group of methods, callbacks, and validations that all pull in the same direction. When you can name that group, pull it out.

This applies to validations too. Keep core-attribute validations (presence, uniqueness, format) in the model; move aspect-specific validations (parse-result checks, side-effect-of-X checks) into the relevant concern alongside the methods they validate.

See [[model_concern]] for the concern conventions.

## Section ordering

Section ordering inside a model (no comment headers — just respect the order):

1. `belongs_to` associations
2. `has_many` associations
3. Any other associations (`has_one`, `has_and_belongs_to_many`, etc.)
4. `*_attached` associations (`has_one_attached`, `has_many_attached`)
5. Attribute-related lines (`alias_attribute`, `attr_*`, etc.)
6. Scopes
7. Validations
8. Public methods
9. Private methods

When declaring an enum, use a string column configured like:

```ruby
enum :source, %w[user assistant system].index_by(&:to_sym)
```

## Namespacing

For a namespaced model, do NOT use `class Namespace::ModelName`. Open the module on its own line and indent the class:

```ruby
# Good
module Message
  class Email < ApplicationRecord
    # ...
  end
end

# Bad
class Message::Email < ApplicationRecord
  # ...
end
```

Why: Ruby constant lookup is lexical. The shorthand `class Namespace::ModelName` does NOT open `Namespace` as a lexical scope, so any constant under `Namespace` (concerns, sibling models, error classes) has to be referenced with its full path inside the class body. The long form makes everything in `Namespace::*` resolvable by its short name:

```ruby
module Message
  class Email < ApplicationRecord
    include AttachmentReceivable   # finds Message::AttachmentReceivable
    # vs the shorthand form, which would require:
    # include Message::AttachmentReceivable
  end
end
```

That same lexical resolution is a **trap** when a top-level model shares a name with something under the namespace. Inside `module Assistant`, a bare `Message` resolves to `Assistant::Message` (the Loop-side message class), NOT the top-level `::Message` model — so `item.is_a?(Message)` silently tests the wrong class and never matches a real `::Message` row. Reference the top-level model explicitly as `::Message`. (This bit `Assistant::Transcript`, which interleaves `::Message` rows with `Assistant::Event`s.)

### Exception: namespace is an existing class (e.g. STI base)

When the "namespace" is itself a class — most commonly an STI base like `class Message < ApplicationRecord` with subclasses `Message::Email`, `Message::IMessage`, etc. — you cannot use `module Message`, because `Message` is already defined as a class. Re-open the class instead:

```ruby
class Message
  class Email < ApplicationRecord
    # ...
  end
end
```

Same lexical-scope benefit applies: `include AttachmentReceivable` inside this block resolves to `Message::AttachmentReceivable`.

## Including concerns

Default: multiple concerns on a single `include` line.

```ruby
include Messageable, Inspectable, Broadcastable
```

Split onto multiple `include` lines when:

- The list is getting long.
- There's an explicit include-order dependency. Put the comment **inline on the dependent include line itself**, not on a line above the include block — that way the comment travels with the constraint if anyone reorders later. Example:

  ```ruby
  include Messageable
  include AttachmentReceivable # must come after Messageable — overrides its message_text-style methods to append a URL footer
  include MimeParsing
  ```

- It makes sense to logically group related concerns onto their own line (e.g. all the messaging-related concerns on one line, all the audit-related concerns on another).

## An `after_destroy` that reads a has_many must `reload` it first

A destroyed record can still appear in a **cached** has_many collection on the same in-memory parent. So an `after_destroy` (or `after_commit on: :destroy`) that summarizes the surviving rows — `user.gmail_credentials.map { ... }` to build a message, etc. — can list the row you just deleted. `user.gmail_credentials.count` runs fresh SQL and is fine, but `.map`/`.each`/`.to_a` on a previously-loaded association use the stale cache, so the two disagree. Call `association.reload` at the top of the callback. (This bit `GmailCredential#update_roster`, which builds an agent-facing "pick a new default" message from the remaining accounts.)

## Clean up child rows that FK to a deleted record in `before_destroy`, not `after_destroy`

When another table has a NOT-NULL / RESTRICT foreign key pointing at this model, the FK is enforced the instant this row is deleted — which happens *before* `after_destroy` runs. So an `after_destroy` that deletes those child rows is too late: the row delete already raised `SQLite3::ConstraintException: FOREIGN KEY constraint failed`. Do the cleanup in `before_destroy` so the children are gone first. (This bit `GmailCredential#prune_send_as_addresses`: it deletes the `gmail_send_as_links` that FK to the credential, then removes any now-orphaned `UserEmailAddress`. As `after_destroy` it crashed every credential/user destroy; as `before_destroy` it's clean.) Don't add a DB `on_delete: :cascade` to "fix" it if a callback still needs to *read* those children — cascade fires inside the delete and the rows are gone before the callback can see them.

## A scope body that means "the whole table" must say `User.…`, not the bare method

Inside a scope lambda `self` is the relation being chained, so a bare class method or sibling scope runs *inside that chain*. `scope :not_dormant, -> { where.not(id: dormant.select(:id)) }` with `dormant` built on a bare `owner` (lowest-id human) quietly re-elects the owner per chain: `account.users.not_dormant` treats that account's lowest-id human as the owner, and `User.where.not(id: real_owner).not_dormant` keeps someone it should drop. Qualify any lookup that is global by intent (`User.owner`, `User.dormant_in_development`). Stubbing the class method in tests hides this — cover it with one test that chains the scope onto a relation excluding the expected row and leaves the method real.

## When creating a new model

Also:

- Add a fixture in `rails/test/fixtures/`
- Add a unit test in `rails/test/models/`
- Declare `encrypts` on any column holding a credential or customer content — see [[rails]], "Encrypting a column at rest"

Specifics for each of those live in their respective rules and load when you touch those directories.
