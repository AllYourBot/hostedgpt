---
paths:
  - "app/models/*.rb"
---

# Model

## Keep the model file slim

The model file is the essential overview of what this model is — its associations, its core attributes, its public API. A developer ramping up should be able to read it top-to-bottom and understand the shape of the thing without wading through implementation details.

Ancillary logic — anything specifically about one aspect of the model — belongs in a concern at `app/models/<model_name>/<aspect>.rb` (`Assistant::Export`, `Assistant::Context`, `Message::Version`). The signal that something is a candidate: a self-contained group of methods, callbacks, and validations that all pull in the same direction. When you can name that group, pull it out.

This applies to validations too. Keep core-attribute validations (presence, uniqueness, format) in the model; move aspect-specific validations into the relevant concern alongside the methods they validate.

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
enum :role, %w[user assistant tool].index_by(&:to_sym)
```

## Including concerns

Default: multiple concerns on a single `include` line.

```ruby
include Export, Slug, Context
```

Split onto multiple `include` lines when:

- The list is getting long.
- There's an explicit include-order dependency. Put the comment **inline on the dependent include line itself**, not on a line above the include block — that way the comment travels with the constraint if anyone reorders later.
- It makes sense to logically group related concerns onto their own line.

## An `after_destroy` that reads a has_many must `reload` it first

A destroyed record can still appear in a **cached** has_many collection on the same in-memory parent. So an `after_destroy` (or `after_commit on: :destroy`) that summarizes the surviving rows can list the row you just deleted. `.count` runs fresh SQL and is fine, but `.map`/`.each`/`.to_a` on a previously-loaded association use the stale cache, so the two disagree. Call `association.reload` at the top of the callback.

## Clean up child rows that FK to a deleted record in `before_destroy`, not `after_destroy`

When another table has a foreign key pointing at this model, the FK is enforced the instant this row is deleted — which happens *before* `after_destroy` runs. So an `after_destroy` that deletes those child rows is too late: the row delete already raised `PG::ForeignKeyViolation`. Do the cleanup in `before_destroy` (or with `dependent:`) so the children are gone first. Don't add a DB `on_delete: :cascade` to "fix" it if a callback still needs to *read* those children — cascade fires inside the delete and the rows are gone before the callback can see them.

## A scope body that means "the whole table" must name the class

Inside a scope lambda `self` is the relation being chained, so a bare class method or sibling scope runs *inside that chain*: `user.assistants.some_scope` quietly narrows the inner lookup to that user's rows too. Qualify any lookup that is global by intent with the class name. Stubbing the class method in tests hides this — cover it with one test that chains the scope onto a narrower relation and leaves the method real.

## Soft deletion

A model with `deleted_at` is soft-deleted, not destroyed (see CLAUDE.md). New associations to one come in pairs: `has_many :things` scoped `not_deleted`, and `has_many :things_including_deleted` for code that must still resolve historical rows.

## When creating a new model

Also:

- Add a fixture in `test/fixtures/`
- Add a unit test in `test/models/`
- Declare `encrypts` on any column holding a credential or customer content — see [[migration]]

Specifics for each of those live in their respective rules and load when you touch those directories.
