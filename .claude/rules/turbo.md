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

Prefer full container refresh over surgical updates: one code path for create/update/delete/reorder, no race conditions between broadcast types, works for changes made outside the request (a background job), trivial to reason about, and the data is small.

This app's cable adapter is PostgreSQL (`config/cable.yml`), and message streaming already re-renders `messages/_message` on every chunk, so before choosing a full-container refresh for a frequent event, check the payload stays small.

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

## A page that must not come back on Back needs two directives

`Cache-Control: no-store` (`no_store` in the controller) only governs the browser's cache/bfcache. Turbo keeps its own snapshot cache, and a restoration visit on Back renders that snapshot without asking the server, so the header alone changes nothing for a Turbo Drive navigation. Also add `<meta name="turbo-cache-control" content="no-cache">` to that page's `<head>` via `content_for :head` (the layout yields `:head`), scoped to the page rather than the layout.
