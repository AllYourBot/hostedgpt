---
name: rails-docs
description: Use when asked about any Rails-specific topic — ActiveRecord, routing, controllers, views, mailers, jobs, Action Cable, Action Text, Active Storage, migrations, validations, callbacks, associations, caching, security, or Rails internals — including "how do I do X in Rails", debugging Rails behavior, or checking whether an API/option still exists or changed in a given Rails version. Always consult the official guides and API docs rather than answering from memory alone, since trained knowledge can be stale or wrong about version-specific details.
---

# Rails official documentation lookup

Trained knowledge about Rails APIs can be outdated, mixed across versions, or simply wrong on
specifics (option names, defaults, deprecations, callback ordering, etc.). Before answering a
Rails-specific question or relying on a Rails API's exact behavior, check the official docs
rather than guessing — pinned to the version this project actually runs, not whatever version
training data assumed.

## Determine the version first

Don't assume the Rails version from memory or from prose in `CLAUDE.md` — that can go stale the
moment someone bumps the gem without updating the docs. Check the source of truth instead:

```bash
grep -m1 '^    rails (' Gemfile.lock
```

That gives you the exact installed version (e.g. `rails (8.0.2.1)`). Use its `<major>.<minor>`
for the pinned doc URLs below.

## Sources

- **Guides** (concepts, how-tos, conventions): https://guides.rubyonrails.org
  - Version-pinned: `https://guides.rubyonrails.org/v<major>.<minor>/<guide-name>.html`
- **API reference** (exact method signatures, options, source): https://api.rubyonrails.org
  - Version-pinned: `https://api.rubyonrails.org/v<major>.<minor>/`

If a pinned URL 404s (e.g. docs for a brand-new version aren't published at that path yet), fall
back to the unpinned root and flag to the user that you're reading possibly-newer docs than the
installed version.

## When to look things up

Use `WebFetch` against the sources above when:
- The question is about a specific Rails API's options, defaults, or behavior (e.g. "does
  `has_many` support `:strict_loading`?", "what does `config.active_record.encryption` need?").
- You're unsure whether something changed between Rails versions (deprecated, renamed, new
  behavior in the installed version).
- You're about to write code that depends on exact method signatures, callback ordering, or
  routing/DSL syntax you're not fully certain of.
- The user asks a "how do I do X in Rails" question that isn't already answered by this project's
  own conventions in `CLAUDE.md`.

Skip the lookup for things you can verify faster by reading this codebase directly (e.g. "how does
this app handle streaming?" — that's answered by `app/services/ai_backend/`, not the guides), or for
very basic Ruby/Rails knowledge you're confident hasn't changed across versions.

## How to look things up

1. Determine the installed Rails version from `Gemfile.lock` (see above).
2. Identify the right guide or API page (e.g. Active Record Associations, Action Mailer Basics).
3. Fetch it with `WebFetch`, using the version-pinned URL.
4. If the guide doesn't have the exact method signature, cross-check `api.rubyonrails.org` for the
   precise method/class documentation.
5. Prefer the official source over Stack Overflow, blog posts, or other secondary sources when they
   conflict.

## Applying this project's conventions

Official Rails docs describe what's *possible*; they don't override this project's own patterns.
After confirming Rails behavior, still follow `CLAUDE.md`'s conventions — e.g. provider logic goes
in `app/services/ai_backend/`, soft deletion via `deleted_at` + `not_deleted` scopes, feature flags
via `Feature.<name>?`/`Setting.<name>`, and don't hard-code model lists (`models.yml` instead).
