import { Controller } from "@hotwired/stimulus"

// A dropdown-top menu opens upward from its trigger, so inside a scrolling pane a long menu
// pokes out above the pane's top edge, where it's clipped and can't be scrolled to. When the
// dropdown opens, this caps the menu's height at the room between the trigger and that edge;
// pair it with overflow-y-auto on the menu so whatever doesn't fit scrolls inside the menu.
export default class extends Controller {
  static targets = ["menu"]

  fit() {
    const clipTop = this.#clippingAncestor()?.getBoundingClientRect().top ?? 0
    const room = this.element.getBoundingClientRect().top - clipTop - 8 // keep a little gap from the edge

    this.menuTarget.style.maxHeight = `${Math.max(room, 0)}px`
  }

  #clippingAncestor() {
    for (let el = this.element.parentElement; el; el = el.parentElement) {
      if (getComputedStyle(el).overflowY !== "visible") return el
    }
  }
}
