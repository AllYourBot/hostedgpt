---
paths:
  - "app/javascript/controllers/**"
---

# Stimulus Controllers

These controllers are designed to be re-used so before you create a new one, you need to be highly confident there is not already a controller that gives the abilities you need. For example, simple things like showing and hiding elements is handled by the `effect_controller`. Similarly, when you write a controller, be thoughtful about how to generalize the controller if it might be appropriate to use this in the future.

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

Three options — use the simplest that fits.

### 1. `this.dispatch()` + `data-action` (default)

Standard Stimulus events. Sender dispatches, receivers listen via `data-action`. Good for notifications that don't need return values.

```javascript
// sender
this.dispatch("turnAborted")

// receiver wired in HTML:
// data-action="livekit-agent:turnAborted@document->macos-bridge#onTurnAborted"
```

### 2. `static outlets` (direct access)

When the sender needs to call methods on or read properties from the receiver. Creates a direct reference — the sender must declare the outlet upfront.

```javascript
static outlets = ["speech-detection"]

this.speechDetectionOutlet.startMonitoring(stream)
if (this.speechDetectionOutlet.speechDetected) { ... }
```

### 3. `callDynamicOutlets()` (wiring lives in HTML)

When the sender shouldn't know about the receiver at code time. Wiring is defined entirely in HTML via value attributes — makes the controller reusable across pages with different receivers.

```javascript
if (this.onStartedOutletValue) {
  this.callDynamicOutlets(this.onStartedOutletValue)
}
// wiring in HTML:
// data-livekit-agent-on-started-outlet-value="#macos-bridge->macos-bridge#onStarted"
```

## HTML formatting

When an element has multiple Stimulus attributes, put each on its own line:

```html
<section
  data-controller="permissions"
  data-permissions-requested-value="microphone"
  class="border p-4"
>
  ...
</section>
```
