import { Controller } from '@hotwired/stimulus'

// Lets a list be rearranged by dragging its rows, then tells the server where everything ended up.
//
// Example:
//
// <div data-controller="sortable"
//      data-sortable-url-value="/assistants/reorder"
//      data-sortable-dragging-class="opacity-0"
//      data-action="dragover->sortable#over drop->sortable#drop">
//   <div data-sortable-target="item"
//        data-sortable-id="1"
//        draggable="true"
//        data-action="dragstart->sortable#start dragend->sortable#end">Row</div>
//   ...
// </div>
//
// Rows slide out of the way as you drag over them, so the list you let go of is the list you get.
// Once the drag ends the ids are POSTed to the url as ids[] in their new order.
//
// Two notes on the markup. The container needs both the dragover and drop actions: without them the
// browser considers us an invalid drop target and, on links, follows the href instead. And rows
// usually contain links and images, which the browser would rather drag than the row — mark those
// draggable="false" so the row is what gets picked up.

export default class extends Controller {
  static targets = [ "item" ]
  static values = { url: String }
  static classes = [ "dragging" ]

  start(event) {
    this.dragged = event.currentTarget
    this.orderAtDragStart = this.#ids

    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "") // Firefox will not start a drag that carries no data

    // The browser paints the row the user carries from a snapshot it takes after this event returns,
    // which is too late for us to hide the row it snapshots. So hand it a copy to photograph instead.
    // With the copy carrying the cursor, the real row is free to disappear right now, leaving a gap
    // that travels through the list showing where the drop will land — one row on screen, not two.
    event.dataTransfer.setDragImage(...this.#cloneForDragImage(event))

    this.dragged.classList.add(...this.draggingClasses)
  }

  over(event) {
    if (!this.dragged) return

    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const item = this.#itemUnder(event.target)
    if (!item || item === this.dragged) return

    // Cross a row once the cursor is past its midpoint, so the swap happens where the row is headed
    // rather than the instant its edge is touched.
    const { top, height } = item.getBoundingClientRect()
    const below = event.clientY > top + height / 2

    // dragover fires continuously, including while the cursor sits still. Moving the row on every one
    // of them would tear it out of the DOM and put it back dozens of times a second, so only move when
    // the cursor is asking for somewhere the row is not already.
    if ((below ? item.nextElementSibling : item.previousElementSibling) === this.dragged) return

    item.insertAdjacentElement(below ? "afterend" : "beforebegin", this.dragged)
  }

  drop(event) {
    event.preventDefault() // the rows are already in place; all that is left is to not navigate
  }

  end() {
    if (!this.dragged) return

    this.dragged.classList.remove(...this.draggingClasses)
    this.dragged = null

    this.dragImage?.remove()
    this.dragImage = null

    if (this.#ids.join() !== this.orderAtDragStart.join()) this.#persist()
  }

  #persist() {
    const body = new FormData()
    this.#ids.forEach(id => body.append("ids[]", id))

    // A failure needs no handling here: the order lives on the server, so the next render of this
    // list shows the order the server kept, which is the honest answer about what was saved.
    fetch(this.urlValue, {
      method: "POST",
      body,
      headers: { "X-CSRF-Token": this.#csrfToken },
    }).catch(() => {})
  }

  // Returns the setDragImage arguments: a copy of the row parked off screen, and the cursor's offset
  // within it so the copy hangs off the pointer exactly where the row was grabbed.
  #cloneForDragImage(event) {
    const { width, height, left, top } = this.dragged.getBoundingClientRect()

    this.dragImage = this.#scenery(this.dragged.cloneNode(true))

    // Parked with fixed positioning so it stays out of the document's layout, and sized explicitly
    // because outside the sidebar it has no column to take its width from.
    Object.assign(this.dragImage.style, {
      position: "fixed",
      top: "0px",
      left: "-10000px",
      width: `${width}px`,
      height: `${height}px`,
      pointerEvents: "none",
    })
    document.body.appendChild(this.dragImage)

    return [this.dragImage, event.clientX - left, event.clientY - top]
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
