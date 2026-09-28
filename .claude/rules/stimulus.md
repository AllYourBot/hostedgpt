---
paths:
  - "app/javascript/stimulus/**"
---

# Stimulus Controllers

These controllers are designed to be re-used so before you create a new one, you need to be highly confident there is not already a controller in `app/javascript/stimulus/` that gives the abilities you need (e.g. `transition_controller`, `form_controller`, `modal_controller`). Similarly, when you write a controller, be thoughtful about how to generalize the controller if it might be appropriate to use this in the future.

## Member ordering

1. Static members (`static targets`, `static values`, `static classes`, `static outlets`)
2. Private fields (`#fieldName`)
3. Lifecycle methods (`initialize`, `connect`, `disconnect`)
4. Public methods
5. Private methods (`#methodName`)

```javascript
export default class extends Controller {
  static targets = ["output"]
  static values = { url: String }

  #privateField

  connect() {}
  disconnect() {}

  publicMethod() {
    this.#privateMethod()
  }

  #privateMethod() {}
}
```

## Private members

Use ES2022 native private class fields — `#methodName()` not `_methodName()`, `#variableName` not `_variableName`. Applies to both methods and instance variables.

## Controller communication

Two options — use the simpler one when it fits.

### 1. `this.dispatch()` + `data-action` (default)

Standard Stimulus events. Sender dispatches, receivers listen via `data-action`. Good for notifications that don't need return values.

```javascript
// sender
this.dispatch("submitted")

// receiver wired in HTML:
// data-action="composer:submitted@document->message-scroller#scrollDown"
```

### 2. `static outlets` (direct access)

When the sender needs to call methods on or read properties from the receiver. Creates a direct reference — the sender must declare the outlet upfront.

```javascript
static outlets = ["modal"]

this.modalOutlet.open()
```

## HTML formatting

When an element has multiple Stimulus attributes, put each on its own line:

```html
<section
  data-controller="clipboard"
  data-action="click->clipboard#copy"
  class="border p-4"
>
  ...
</section>
```
