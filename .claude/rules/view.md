---
paths:
  - "app/views/**/*.erb"
---

# Views

## SVGs through `image_tag`

An SVG loaded with `image_tag` (e.g. `logo.svg`) is an `<img>`, so its `fill="currentColor"` ignores the surrounding text color and always renders black — Tailwind `text-*` classes on the tag do nothing. On a dark-mode background add `dark:invert`, or set it on a white backdrop as `messages/new.html.erb` does. Give a decorative image beside a visible label `alt: ""`; Rails doesn't generate `alt`, so screen readers otherwise announce the filename.

## `Document#image_url` embeds the file when `APP_URL` is unset

Without `APP_URL` (the default in development), `image_url` returns a base64 `data:` URL, so every call downloads the variant during render and inlines it into the HTML, including every streaming re-broadcast of the message. For an image that isn't shown on load (a modal, a hidden tab), use `image_link_url` with a lazy `image-loader` instead.
