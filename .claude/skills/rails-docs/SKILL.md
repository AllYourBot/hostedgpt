---
name: rails-docs
description: Use when asked about any Rails-specific topic — ActiveRecord, routing, controllers, views, mailers, jobs, Action Cable, Action Text, Active Storage, migrations, validations, callbacks, associations, caching, security, or Rails internals — including "how do I do X in Rails", debugging Rails behavior, or checking whether an API/option still exists or changed in Rails 8. Always consult the official guides and API docs rather than answering from memory alone, since trained knowledge can be stale or wrong about version-specific details, and this project pins Rails 8.0.
---

# Rails official documentation lookup

This project (HostedGPT) runs Rails 8.0, per the project's `CLAUDE.md`. Trained knowledge about
Rails APIs can be outdated, mixed across versions, or simply wrong on specifics (option names,
defaults, deprecations, callback ordering, etc.). Before answering a Rails-specific question or
relying on a Rails API's exact behavior, check the official docs rather than guessing.

## Sources

- **Guides** (concepts, how-tos, conventions): https://guides.rubyonrails.org
  - Version-pinned guides are available at `https://guides.rubyonrails.org/v8.0/<guide-name>.html`
    if you need to confirm you're reading the Rails 8.0 version rather than edge/main.
- **API reference** (exact method signatures, options, source): https://api.rubyonrails.org
  - Version-pinned API docs: `https://api.rubyonrails.org/v8.0/`

## When to look things up

Use `WebFetch` against the sources above when:
- The question is about a specific Rails API's options, defaults, or behavior (e.g. "does
  `has_many` support `:strict_loading`?", "what does `config.active_record.encryption` need?").
- You're unsure whether something changed between Rails versions (deprecated, renamed, new in 8.0).
- You're about to write code that depends on exact method signatures, callback ordering, or
  routing/DSL syntax you're not fully certain of.
- The user asks a "how do I do X in Rails" question that isn't already answered by this project's
  own conventions in `CLAUDE.md`.

Skip the lookup for things you can verify faster by reading this codebase directly (e.g. "how does
this app handle streaming?" — that's answered by `app/services/ai_backend/`, not the guides), or for
very basic Ruby/Rails knowledge you're confident hasn't changed across versions.

## How to look things up

1. Identify the right guide or API page (e.g. Active Record Associations, Action Mailer Basics).
2. Fetch it with `WebFetch`, preferring the `/v8.0/` pinned URL when version accuracy matters.
3. If the guide doesn't have the exact method signature, cross-check `api.rubyonrails.org` for the
   precise method/class documentation.
4. Prefer the official source over Stack Overflow, blog posts, or other secondary sources when they
   conflict.

## Applying this project's conventions

Official Rails docs describe what's *possible*; they don't override this project's own patterns.
After confirming Rails behavior, still follow `CLAUDE.md`'s conventions — e.g. provider logic goes
in `app/services/ai_backend/`, soft deletion via `deleted_at` + `not_deleted` scopes, feature flags
via `Feature.<name>?`/`Setting.<name>`, and don't hard-code model lists (`models.yml` instead).
