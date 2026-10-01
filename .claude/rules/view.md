---
paths:
  - "app/views/**/*.erb"
---

# Views

## SVGs through `image_tag`

An SVG loaded with `image_tag` (e.g. `logo.svg`) is an `<img>`, so its `fill="currentColor"` ignores the surrounding text color and always renders black — Tailwind `text-*` classes on the tag do nothing. On a dark-mode background add `dark:invert`, or set it on a white backdrop as `messages/new.html.erb` does. Give a decorative image beside a visible label `alt: ""`; Rails doesn't generate `alt`, so screen readers otherwise announce the filename.
