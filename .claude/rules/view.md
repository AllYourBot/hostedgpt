---
paths:
  - "app/views/**/*.erb"
---

# Views

## SVGs through `image_tag`

An SVG loaded with `image_tag` (e.g. `logo.svg`) is an `<img>`, so its `fill="currentColor"` ignores the surrounding text color and always renders black — Tailwind `text-*` classes on the tag do nothing. On a dark-mode background add `dark:invert`, or set it on a white backdrop as `messages/new.html.erb` does. Give a decorative image beside a visible label `alt: ""`; Rails doesn't generate `alt`, so screen readers otherwise announce the filename.

## `Document#image_url` embeds the file when `APP_URL` is unset

Without `APP_URL` (the default in development), `image_url` returns a base64 `data:` URL, so every call downloads the variant during render and inlines it into the HTML, including every streaming re-broadcast of the message. For an image that isn't shown on load (a modal, a hidden tab), use `image_link_url` with a lazy `image-loader` instead.

## A dropdown whose trigger only shows on hover must open flush against its row

The sidebar's dots menus are daisyUI dropdowns, open only while the trigger holds focus (`:focus-within`), and the trigger is `invisible group-hover:visible` (or inside a `hidden group-hover:flex` wrapper). Leave any gap between the row and the menu, as `mt-7` did, and a pointer crossing it drops the row's hover, the trigger goes invisible, Chrome moves focus to `<body>`, and the menu closes before it can be clicked. A 1–2px gap is enough, and a test that moves the pointer in steps of more than 1px jumps over it. Anchor the menu at `top-full` of a dropdown that is `self-stretch` to the row's height, and add `group-focus-within:visible` (or `:flex`) to the trigger so it stays shown while its menu is open, as `collections/_nav.html.erb` does.
