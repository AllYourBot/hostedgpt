---
paths:
  - "app/models/concerns/**"
  - "app/models/*/**/*.rb"
---

# Model Concern

By default, a concern lives in a subdirectory named for the model it belongs to (e.g. `app/models/user/foo.rb`). If the concern is included in multiple models, move it to `app/models/concerns/`.

Every concern has a unit test file in the parallel `test/` directory.

Section ordering inside a concern follows the same order as a model — see [[model]] for the full list.

## Overriding a `store_accessor` declared in the concern

`store_accessor` in a concern's `included` block includes its generated-methods module into the model *after* the concern, so it sits above the concern in the ancestor chain and a same-named method in the concern's body is silently shadowed. Define the override inside the `included` block, as `User::Locatable#use_ip_location=` does, so it lands on the class and can call `super`.

## Writing one `preferences` key from a job or callback

`update!(some_pref: x)` saves the user's whole `preferences` jsonb hash as it was when that user was loaded, undoing any preference another request changed since, and it runs every `User` validation. Outside the settings form, set just the key with `jsonb_set` via `update_all`, as `User::Locatable#remember_ip_location` does.
