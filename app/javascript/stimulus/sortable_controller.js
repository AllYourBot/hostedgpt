import { Controller } from '@hotwired/stimulus'

// Lets a list be rearranged by dragging its rows — with a mouse or a finger — then tells the
// server where everything ended up.
//
// Example:
//
// <div data-controller="sortable"
//      data-sortable-url-value="/assistants/reorder"
//      data-sortable-dragging-class="opacity-0"
//      class="flex flex-col">
//   <div data-sortable-target="item"
//        data-sortable-id="1"
//        data-action="pointerdown->sortable#press">Row</div>
//   ...
// </div>
//
// Rows slide out of the way as you drag over them, so the list you let go of is the list you get.
// Once the drag ends the ids are POSTed to the url as ids[] in their new order.
//
// A mouse lifts a row once it has traveled a few pixels, the way HTML5 drag used to. A finger has
// to rest a moment first, because touching a row is also how the sidebar scrolls — lifting on
// first contact would steal every scroll. Once a finger has lifted a row, though, the page stops
// scrolling until the row is put down.
//
// Three notes on the markup. Rows usually contain links and images that would rather be dragged
// (or opened) than the row: mark them draggable="false" so the row is what gets picked up, and a
// completed drag swallows the click that follows it so the drop never opens a link. And this list
// may live inside a turbo-frame that other pages refresh mid-drag (the conversations sidebar
// morphs itself whenever any conversation changes anywhere) — a morph that swaps the row out from
// under a held cursor kills the drag, so frame renders are held off while a drag is in flight.

const MOUSE_LIFT_DISTANCE = 6 // px of travel before a mouse press becomes a drag
const TOUCH_HOLD_MS = 250     // ms a finger must rest before it lifts a row

export default class extends Controller {
  static targets = [ "item" ]
  static values = { url: String }
  static classes = [ "dragging" ]

  press(event) {
    if (this.dragging) return
    if (event.pointerType === "mouse" && event.button !== 0) return
    if (this.pressed) return // one gesture at a time: a second pointer never steals an armed press
    // Toggles, picker buttons, and menu items click — they never start drags. (The title link
    // intentionally still arms: dragging the title reorders the row.) Without this, arming a
    // press on a button tangles the gesture with the click that follows it.
    if (event.target.closest("button")) return

    this.pressed = event.currentTarget
    this.pointerId = event.pointerId
    this.pointerType = event.pointerType
    this.pressPoint = { x: event.clientX, y: event.clientY }
    this.dragging = false

    if (this.pointerType !== "mouse") {
      this.holdTimer = setTimeout(() => this.#lift(), TOUCH_HOLD_MS)
    }

    window.addEventListener("pointermove", this.#moved, { passive: false })
    window.addEventListener("pointerup", this.#ended)
    window.addEventListener("pointercancel", this.#cancelled)
  }

  disconnect() {
    if (!this.pressed) return
    this.#releaseTracking()
    this.#putDown()
  }

  #moved = (event) => {
    if (!this.pressed || event.pointerId !== this.pointerId) return

    if (!this.dragging) {
      if (this.pointerType !== "mouse") {
        // A finger that moves before the hold completes is scrolling, not dragging.
        clearTimeout(this.holdTimer)
        this.holdTimer = null
        return
      }

      const travel = Math.hypot(event.clientX - this.pressPoint.x, event.clientY - this.pressPoint.y)
      if (travel < MOUSE_LIFT_DISTANCE) return

      this.#lift()
    }

    event.preventDefault() // the page must not scroll while a finger carries a row
    this.#slideGhost(event)
    this.#slideRows(event)
  }

  #ended = (event) => {
    if (!this.pressed || event.pointerId !== this.pointerId) return
    this.#releaseTracking()

    if (this.dragging) {
      const orderChanged = this.#ids.join() !== this.orderAtDragStart.join()
      this.#putDown()
      // Replay after the POST resolves when the order changed: reloading first would render
      // the pre-persist order with no later render to correct it (204 answers carry no HTML).
      if (orderChanged) this.#persist().finally(() => this.#replayHeldRefresh())
      else this.#replayHeldRefresh()
      this.#swallowNextClick() // the click that follows a drop must not open the row's link
    } else {
      this.#putDown()
      this.#replayHeldRefresh()
    }
  }

  #cancelled = (event) => {
    if (!this.pressed || event.pointerId !== this.pointerId) return
    this.#releaseTracking()

    if (this.dragging) this.#restoreOrder() // a canceled drag never commits: rows go back as they were
    this.#putDown()
    this.#replayHeldRefresh()
  }

  #lift() {
    clearTimeout(this.holdTimer)
    this.holdTimer = null
    if (!this.pressed.isConnected) { this.pressed = null; return } // a refresh in the touch-hold window detached the row: no drag
    this.dragging = true
    this.orderAtDragStart = this.#ids

    // The ghost is cloned before the row hides: cloning after would copy the hiding class onto
    // the carried copy and the user would drag nothing visible.
    this.ghost = this.#cloneForGhost()
    this.#slideGhost(this.#syntheticMove())

    // Capture keeps every event aiming at the row even when the finger travels off the list —
    // and it aims the click that follows the drop at the row instead of whatever link is under it.
    try { this.pressed.setPointerCapture(this.pointerId) } catch { /* row detached mid-lift */ }
    this.pressed.classList.add(...this.draggingClasses)
    this.userSelectBeforeDrag = this.pressed.style.userSelect
    this.pressed.style.userSelect = "none" // no text selection while a row rides under the cursor

    document.addEventListener("turbo:before-frame-render", this.#holdFrameRender, true)
    document.addEventListener("turbo:before-morph-element", this.#holdSidebarMorph, true)
    document.addEventListener("turbo:before-stream-render", this.#holdSidebarStream, true)
    if (this.pointerType !== "mouse") window.addEventListener("touchmove", this.#stopScroll, { passive: false })
  }

  #slideRows(event) {
    // Pointer capture aims every event at the held row, so the row under the pointer has to be
    // asked for by coordinates. The ghost is pointer-events:none and the held row is the one the
    // pointer started on, so this returns either a sibling row or the held row itself.
    const item = this.#itemUnder(document.elementFromPoint(event.clientX, event.clientY))
    if (!item || item === this.pressed) return

    // Cross a row once the cursor is past its midpoint, so the swap happens where the row is headed
    // rather than the instant its edge is touched.
    const { top, height } = item.getBoundingClientRect()
    const below = event.clientY > top + height / 2

    // pointermove fires continuously, including while the pointer sits still. Moving the row on
    // every one of them would tear it out of the DOM and put it back dozens of times a second, so
    // only move when the pointer is asking for somewhere the row is not already.
    if ((below ? item.nextElementSibling : item.previousElementSibling) === this.pressed) return

    item.insertAdjacentElement(below ? "afterend" : "beforebegin", this.pressed)
  }

  #persist() {
    const body = new FormData()
    this.#ids.forEach(id => body.append("ids[]", id))

    // A failure needs no handling here: the order lives on the server, so the next render of this
    // list shows the order the server kept, which is the honest answer about what was saved.
    return fetch(this.urlValue, {
      method: "POST",
      body,
      headers: { "X-CSRF-Token": this.#csrfToken },
    }).catch(() => {})
  }

  // Returns the ghost: a copy of the row that floats under the pointer while the real row hides,
  // sized and parked so it hangs off the pointer exactly where the row was grabbed.
  #cloneForGhost() {
    const rect = this.pressed.getBoundingClientRect()
    this.grabOffset = {
      x: this.pressPoint.x - rect.left,
      y: this.pressPoint.y - rect.top,
    }

    this.ghost = this.#scenery(this.pressed.cloneNode(true))
    Object.assign(this.ghost.style, {
      position: "fixed",
      width: `${rect.width}px`,
      height: `${rect.height}px`,
      pointerEvents: "none",
      zIndex: "50",
    })
    document.body.appendChild(this.ghost)

    return this.ghost
  }

  #slideGhost(event) {
    this.ghost.style.left = `${event.clientX - this.grabOffset.x}px`
    this.ghost.style.top = `${event.clientY - this.grabOffset.y}px`
  }

  // The ghost is positioned at lift from where the pointer was then, and only follows afterwards —
  // this hands #slideGhost the press point so it lands correctly on the first frame.
  #syntheticMove() {
    return { clientX: this.pressPoint.x, clientY: this.pressPoint.y, target: this.pressed }
  }

  // The copy exists to be photographed, so it sheds everything that would let the rest of the page
  // mistake it for a real row: its ids, and the Stimulus wiring that would connect it to whatever
  // controllers happen to sit above the body it gets parked in.
  #scenery(element) {
    for (const node of [element, ...element.querySelectorAll("*")]) {
      for (const { name } of [...node.attributes]) {
        if (name === "id" || name === "data-controller" || name === "data-action" || name.endsWith("-target")) {
          node.removeAttribute(name)
        }
      }
    }

    return element
  }

  #restoreOrder() {
    this.orderAtDragStart.forEach(id => {
      const item = this.itemTargets.find(target => String(target.dataset.sortableId) === String(id))
      if (item) this.element.appendChild(item)
    })
  }

  #releaseTracking() {
    window.removeEventListener("pointermove", this.#moved)
    window.removeEventListener("pointerup", this.#ended)
    window.removeEventListener("pointercancel", this.#cancelled)
  }

  #putDown() {
    if (this.holdTimer) {
      clearTimeout(this.holdTimer)
      this.holdTimer = null
    }

    if (this.dragging) {
      this.pressed.classList.remove(...this.draggingClasses)
      this.pressed.style.userSelect = this.userSelectBeforeDrag
      document.removeEventListener("turbo:before-frame-render", this.#holdFrameRender, true)
      document.removeEventListener("turbo:before-morph-element", this.#holdSidebarMorph, true)
      document.removeEventListener("turbo:before-stream-render", this.#holdSidebarStream, true)
      window.removeEventListener("touchmove", this.#stopScroll)
      this.ghost?.remove()
      this.ghost = null
      try { this.pressed.releasePointerCapture(this.pointerId) } catch { /* already released */ }
    }

    this.dragging = false
    this.pressed = null
  }

  // A refresh held mid-drag was dropped, not deferred: reload the sidebar frame so toggles
  // answered 204 mid-drag still flip their icons instead of looking dead until the next
  // broadcast. The frame refetches its src, which re-renders both sections from the server.
  #replayHeldRefresh() {
    if (!this.heldRefresh) return
    this.heldRefresh = false
    const frame = document.getElementById("nav-conversations")
    if (frame?.src) frame.reload()
  }

  #swallowNextClick() {
    const swallow = (event) => {
      event.preventDefault()
      event.stopPropagation()
    }
    document.addEventListener("click", swallow, { capture: true, once: true })
    // The click rides in right behind the pointerup; if none came, take the guard back down before
    // it can eat an innocent click somewhere else.
    setTimeout(() => document.removeEventListener("click", swallow, { capture: true }), 0)
  }

  // Sidebar updates arrive as frame renders, morphs, and streams. A morph mid-drag would
  // detach the row under the cursor — cleanup would run against a detached node — so every
  // sidebar-bound refresh waits until the drag is over. Frame renders and morphs are scoped to
  // the sidebar so chat streams keep flowing; held updates are dropped, then replayed by
  // reloading the sidebar frame in #putDown.
  #holdFrameRender = (event) => {
    if (this.dragging) {
      event.preventDefault()
      this.heldRefresh = true
    }
  }

  #holdSidebarMorph = (event) => {
    if (this.dragging && event.target.closest?.("#nav-scrollable")) {
      event.preventDefault()
      this.heldRefresh = true
    }
  }

  #holdSidebarStream = (event) => {
    if (!this.dragging) return
    const target = event.target.getAttribute?.("target")
    if (target && document.getElementById(target)?.closest("#nav-scrollable")) {
      event.preventDefault()
      this.heldRefresh = true
    }
  }

  #stopScroll = (event) => {
    event.preventDefault()
  }

  #itemUnder(element) {
    const item = element.closest?.('[data-sortable-target="item"]')
    return this.itemTargets.includes(item) ? item : null
  }

  get #ids() {
    return this.itemTargets.map(item => item.dataset.sortableId)
  }

  get #csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
