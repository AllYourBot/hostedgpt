---
paths:
  - "app/models/concerns/**"
  - "app/models/*/**/*.rb"
---

# Model Concern

By default, a concern lives in a subdirectory named for the model it belongs to (e.g. `app/models/user/foo.rb`). If the concern is included in multiple models, move it to `app/models/concerns/`.

Every concern has a unit test file in the parallel `test/` directory.

Section ordering inside a concern follows the same order as a model — see [[model]] for the full list.
