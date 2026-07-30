---
name: tailwind-docs
description: Use when asked about Tailwind CSS — utility classes, responsive/state variants, `tailwind.config.js` theme customization, `@apply`, dark mode, or "how do I style X with Tailwind". Always consult the official Tailwind docs rather than answering from memory alone, since utility class names and config syntax have changed between Tailwind v3 and v4, and this project pins Tailwind v3 (via `tailwindcss-rails` gem, config in `config/tailwind.config.js`).
---

# Tailwind CSS documentation lookup

This project (HostedGPT) styles its Hotwire-rendered views with Tailwind CSS via the
`tailwindcss-rails` gem (`~> 2.7`, see `Gemfile`), which bundles **Tailwind CSS v3** — it still
uses a JS config file at `config/tailwind.config.js`, not Tailwind v4's CSS-first `@theme`
config. This matters because Tailwind v4 renamed/changed a number of utilities and the config
approach entirely, so answers pulled from memory can silently mix v3 and v4 syntax.

## Sources

- **Docs**: https://tailwindcss.com/docs
  - The current site defaults to the latest major version's docs. If a page's syntax looks like
    v4 (e.g. CSS `@import "tailwindcss"` / `@theme` blocks, no `tailwind.config.js`), that's a
    mismatch with this project — look for the v3 equivalent or verify against the
    `config/tailwind.config.js` file already in this repo, which follows v3 conventions.
  - The docs site also has a version switcher; prefer the v3 docs when available/linked from a
    page (URLs are sometimes of the form `https://v3.tailwindcss.com/docs/...`).

## When to look things up

Use `WebFetch` when:
- You need the exact utility class name/values for something (spacing scale, color palette,
  arbitrary value syntax) rather than guessing.
- You're customizing `config/tailwind.config.js` (theme extension, plugins, safelist) and need
  the v3 config shape.
- You're unsure whether a utility/variant exists in v3 (e.g. some newer utilities and variants
  were only added in v4).

Skip the lookup for basic, version-stable utilities you're confident about (e.g. `flex`,
`items-center`, `p-4`), or when the existing codebase already shows the exact class/pattern to
follow — check `app/views/` and `config/tailwind.config.js` for this project's own conventions
first.
