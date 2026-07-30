---
name: hotwire-docs
description: Use when asked about Turbo (Turbo Drive, Turbo Frames, Turbo Streams, ActionCable-broadcasted streams) or Stimulus (controllers, targets, actions, values, outlets) — including "how do I do X with Turbo/Stimulus", debugging a Turbo Stream broadcast, or wiring up a Stimulus controller. Always consult the official Hotwire docs rather than answering from memory alone, since Turbo/Stimulus APIs and idioms have shifted across versions and this project has no SPA framework — all interactivity goes through Hotwire.
---

# Hotwire (Turbo + Stimulus) documentation lookup

This project (HostedGPT) uses Hotwire (Turbo + Stimulus) for all frontend interactivity — no SPA
framework. Streaming chat updates arrive via Turbo Stream broadcasts over ActionCable, rendered
from server-side partials (see `app/views/messages/_message.html.erb` and `CLAUDE.md`). Trained
knowledge about Turbo/Stimulus can be stale or blend behavior across versions — check the official
docs before relying on specifics.

## Sources

- **Turbo Handbook & reference**: https://turbo.hotwired.dev
  - Overview: https://turbo.hotwired.dev/handbook/introduction
  - Drive: https://turbo.hotwired.dev/handbook/drive
  - Frames: https://turbo.hotwired.dev/handbook/frames
  - Streams: https://turbo.hotwired.dev/handbook/streams
  - Reference (attributes, actions, events): https://turbo.hotwired.dev/reference/attributes
- **Stimulus Handbook & reference**: https://stimulus.hotwired.dev
  - Overview: https://stimulus.hotwired.dev/handbook/introduction
  - Controllers/targets/actions/values/outlets: https://stimulus.hotwired.dev/handbook/hello-stimulus
  - Reference: https://stimulus.hotwired.dev/reference/controllers

## When to look things up

Use `WebFetch` against the sources above when:
- You need the exact Turbo Stream action list/syntax (`append`, `prepend`, `replace`, `update`,
  `remove`, `before`, `after`, `refresh`) or how targeting (`target=`/`targets=`) works.
- You're unsure how Turbo Frame lazy-loading, `data-turbo-*` attributes, or navigation
  interception behaves.
- You're writing or debugging a Stimulus controller and need exact lifecycle callback names,
  target/value/outlet declaration syntax, or action descriptor syntax (`event->controller#method`).
- The user asks "how do I do X with Turbo/Stimulus" and it's not already answered by this
  project's own patterns in `CLAUDE.md`.

Skip the lookup for questions answered faster by reading this codebase directly — e.g. how this
app's own streaming job builds and broadcasts updates is answered by
`app/services/ai_backend/`, `GetNextAIMessageJob`, and the `_message.html.erb` partials, not the
Hotwire docs.

## Applying this project's conventions

The Hotwire docs describe the general framework; this project's own streaming architecture (see
`CLAUDE.md`'s "Message generation flow") governs how it's actually used here — e.g. partial
updates are broadcast roughly every 100ms during streaming and only persisted once the stream
finishes. Confirm Turbo/Stimulus behavior against the docs, but follow this repo's existing
patterns for where controllers and broadcasts live.
