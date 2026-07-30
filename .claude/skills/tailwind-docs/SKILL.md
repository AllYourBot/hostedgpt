---
name: tailwind-docs
description: Use when asked about Tailwind CSS — utility classes, responsive/state variants, config/theme customization, `@apply`, dark mode, or "how do I style X with Tailwind". Always consult the official Tailwind docs rather than answering from memory alone, since utility class names and config syntax changed substantially between Tailwind v3 and v4 — check which one this project is actually on before trusting either.
---

# Tailwind CSS documentation lookup

This project (HostedGPT) styles its Hotwire-rendered views with Tailwind CSS via the
`tailwindcss-rails` gem. Tailwind v3 and v4 differ substantially — v3 uses a JS config file
(`tailwind.config.js`, `module.exports = { theme: {...} }`), v4 uses CSS-first config
(`@import "tailwindcss"` + `@theme` blocks in the stylesheet, often no JS config file at all) and
renamed/changed a number of utilities. Trained knowledge can silently mix the two, so confirm
which version this project is on before trusting either.

## Determine the version first

Check the repo structure rather than assuming:

```bash
ls config/tailwind.config.js 2>/dev/null   # present + module.exports = v3-style config
grep -rn '@theme' app/assets/stylesheets/ 2>/dev/null   # present = v4-style CSS config
grep -m1 'tailwindcss-rails (' Gemfile.lock
```

A present `config/tailwind.config.js` using `module.exports` (no `@theme` blocks in the CSS)
means this project is on Tailwind v3. If that ever flips — `tailwind.config.js` disappears and
`@theme` shows up in the stylesheet instead — the project has moved to v4, and this skill's
default assumption below no longer holds.

## Sources

- **Docs**: https://tailwindcss.com/docs
  - The current site defaults to the latest major version's docs, which won't match a v3 project.
  - If you determined this project is still on v3, prefer the v3-pinned docs at
    `https://v3.tailwindcss.com/docs/...` instead of the default (v4-or-later) docs site.
  - If a page's syntax looks like v4 (CSS `@import "tailwindcss"` / `@theme` blocks, no
    `tailwind.config.js` in examples) but the project is on v3, that's a mismatch — look for the
    v3-equivalent page instead.

## When to look things up

Use `WebFetch` when:
- You need the exact utility class name/values for something (spacing scale, color palette,
  arbitrary value syntax) rather than guessing.
- You're customizing the theme/config and need the config shape for the version this project
  actually uses (JS config for v3, CSS `@theme` for v4).
- You're unsure whether a utility/variant exists in the installed major version (some utilities
  and variants only exist in v4, or were renamed from their v3 equivalents).

Skip the lookup for basic, version-stable utilities you're confident about (e.g. `flex`,
`items-center`, `p-4`), or when the existing codebase already shows the exact class/pattern to
follow — check `app/views/` and the project's Tailwind config for this project's own conventions
first.
