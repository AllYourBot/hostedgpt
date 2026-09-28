---
paths:
  - "app/views/**"
---

# Turbo Patterns

Core principle: let Rails and Turbo do the work. If you find yourself writing many `turbo_stream.*` calls in controllers, you're fighting the framework.

## 1. Controllers just redirect

Standard Rails redirects — Turbo intercepts, fetches the new page, and if the request came from a `turbo_frame_tag`, extracts just the matching frame. The same controller action works for full-page and frame contexts.

```ruby
def create
  @task = @list.tasks.build(task_params)
  if @task.save
    redirect_to @task
  else
    render :new, status: :unprocessable_entity
  end
end
```

Avoid `respond_to`-with-`format.turbo_stream` branches in CRUD actions. Just redirect.

## 2. Use `turbo_frame_tag` for in-place updates

Wrap editable content in a frame so Turbo replaces just that piece:

```erb
<%# _task.html.erb %>
<%= turbo_frame_tag task do %>
  <div class="task-row">...task content...</div>
<% end %>

<%# edit.html.erb %>
<%= turbo_frame_tag @task do %>
  <div class="task-row">...edit form...</div>
<% end %>
```

When the edit form redirects to show, Turbo finds the matching frame and swaps it.

## 3. Nested frames for create flow

The new-record form needs to appear where the record will end up. Use nested frames:

```erb
<%# lists/show.html.erb — form placeholder is INSIDE the list %>
<div id="task_list">
  <%= turbo_frame_tag "new_task_form" %>
  <%= render @list.tasks %>
</div>

<%# tasks/new.html.erb — form wrapped in the placeholder frame %>
<%= turbo_frame_tag "new_task_form" do %>
  <div class="task-row">...new task form...</div>
<% end %>

<%# tasks/show.html.erb — wraps the task in BOTH frames %>
<%= turbo_frame_tag "new_task_form" do %>
  <%= render @task %>  <%# includes turbo_frame_tag task %>
<% end %>
```

After create redirects to show, the outer `new_task_form` frame replaces the form; the inner `task` frame is now in place for future edits. No JavaScript, no `turbo_stream` calls.

## 4. Single broadcast point in the model

For real-time sync across browsers, one `after_commit` callback in the model:

```ruby
class Task < ApplicationRecord
  after_commit :broadcast_changes

  private

  def broadcast_changes
    if saved_change_to_completed? && completed?
      Turbo::StreamsChannel.broadcast_action_to(list, action: :remove_animated, target: self)
    else
      Turbo::StreamsChannel.broadcast_update_to(
        list,
        target: "task_list",
        partial: "lists/tasks",
        locals: {list: list}
      )
    end
  end
end
```

Prefer full container refresh over surgical updates: one code path for create/update/delete/reorder, no race conditions between broadcast types, works for API-driven changes (voice agent), trivial to reason about, and the data is small.

**"The data is small" is load-bearing — verify it before choosing full-refresh.** This app's cable adapter is **Solid Cable** (`config/cable.yml`), which is database-backed: every broadcast is written as a row to `*_cable.sqlite3` and kept for `message_retention`, **whether or not anyone is subscribed**. (Delivery also depends on one listener thread per web process — if broadcasts stop arriving everywhere while sockets stay connected, see [[solid_cable]].) So a full-container re-render on a *frequent* event over an *unbounded/large* container multiplies into real disk: `payload × frequency × retention`. #723 was exactly this — the madmin conversation timeline re-rendered the whole conversation on every `Assistant::Event`, and a single base64 screenshot in a tool_result made each render ~50 MB, writing GBs/day to the cable DB with zero admins watching. **Full-refresh of an unbounded/high-frequency container is the wrong shape; broadcast the delta.** The real fix (now shipped) is `broadcast_append_to` a **one-item partial** — payload is O(new item), not O(history). It also *fixes* UX rather than fighting it: a Turbo `replace` resets `<details open>` (which forced a Stimulus controller to snapshot-and-restore open groups), but an `append` never touches the existing element, so expanded groups stay expanded with no JS. When a new item must join an existing group, give the group a **stable inner target** (`<div id="<group>-stream">`) and append the item's entries into it — the group's first item creates the wrapper, later items append into the box. Group by a **stable key that matches the user's mental unit** — here the **session** (one collapsible per agent turn). A message-anchored key looks reasonable but fragments a single turn whenever the agent emits an intermediate message (the events split into a group before and one after it); keying on the session keeps a turn's events in one group and lets messages interleave chronologically around it. Live-updatable summary bits (a "N events" count) need their own stable id and a separate `broadcast_update_to` on each append, since an append can't touch the summary. Belt-and-suspenders that still matter: **cap any inline blob** (`~20 KB/entry`, so one screenshot can't bloat even a single-item append) and **keep `message_retention` short** (`5.minutes`). Two traps: `broadcast_*_later_to` does NOT debounce (only page-refresh broadcasts do), so don't lean on coalescing; and a `has_many :through` scope (`conversation.events` through sessions) makes a bare `where("created_at > ?")` raise `ambiguous column` — qualify it (`Assistant::Event.arel_table[:created_at]`).

## Anti-patterns

- **`turbo_stream` responses for normal CRUD** — just redirect.
- **Broadcasts in both controller and model** — pick one (the model).
- **`broadcasts_to :list, inserts_by: :prepend`** — magic that's hard to override when you need custom behavior (e.g. animated removal for completed tasks).
- **Form outside its destination container** — put the form placeholder INSIDE the list so new records appear in the right place.

## In-page `#anchor` links and `:target`

Turbo Drive intercepts same-page `#fragment` link clicks and updates the URL via the History API rather than doing a native fragment navigation — so the `:target` pseudo-class never fires, and CSS keyed on `[id]:target` (a highlight, a scroll target) silently does nothing **on click**. It still works on a direct page load or an external link, because that's a real fragment navigation. When a link needs native `:target` behavior on click, opt it out of Turbo with `data: {turbo: false}`:

```erb
<%= link_to label, "#message-#{message.id}", data: {turbo: false} %>
```

(Example: the message-bubble timestamp permalink + `:target` highlight in `madmin/conversations/show.html.erb`.)

## A page that must not come back on Back needs two directives

`Cache-Control: no-store` (`no_store` in the controller) only governs the browser's cache/bfcache. Turbo keeps its own snapshot cache, and a restoration visit on Back renders that snapshot without asking the server, so the header alone changes nothing for a Turbo Drive navigation. Also add `<meta name="turbo-cache-control" content="no-cache">` to that page's `<head>` via `content_for :head` (the layout yields `:head`), scoped to the page rather than the layout. The Devise sign-in and signup views carry both because Devise rotates the CSRF token on sign-in (see [[rails]]).

## Turbo Drive never updates `<html>` classes

A visit swaps `<body>` and merges `<head>`; the `<html>` element survives from the first full load. Dark mode survives that only because every layout's `<body>` carries the `theme` Stimulus controller, which re-applies `dark` on connect — a new layout must do the same. A layout whose `<html>`/`<head>` genuinely differs needs a full load: `data: {turbo: false}` on every link into it. The full-screen browser page (`layouts/browser`, from `chrome_browsers/index` and `chrome_browsers/preview`) is the standing case; a restyle that rewrites those links must keep it (the Flying Car revert dropped it once).
