import { Controller } from '@hotwired/stimulus'

// Opens a small emoji panel for a reactable row and posts the chosen emoji, updating the
// counts in place without navigating.
//
// Example:
//
// <div data-controller="emoji-picker"
//      data-emoji-picker-react-url-value="/messages/1/react"
//      data-emoji-picker-unreact-url-value="/messages/1/unreact"
//      data-action="click@document->emoji-picker#close">
//   <button data-action="click->emoji-picker#toggle"
//           data-emoji-picker-target="button"
//           data-role="react">React</button>
//   <div data-emoji-picker-target="panel" class="hidden">
//     <button data-action="click->emoji-picker#select"
//             data-emoji="👍"
//             data-reacted="false"
//             data-role="react-emoji">👍</button>
//     ...
//   </div>
//   <span data-emoji-picker-target="counts">
//     <span data-role="reaction-counts">…chips…</span>
//   </span>
// </div>
//
// Selecting an emoji POSTs it as emoji= to the react or unreact url — toggling on the
// button's reacted state — then flips that chip's count optimistically. Both endpoints
// answer 204 No Content, so the page never navigates away.
//
// Two notes on the markup. The panel lives with the row it reacts to: message rows are never
// sortable items, so the sortable ghost clone — which strips ids and Stimulus wiring from its
// scenery copy — can never detach this controller. Do not place this markup inside a
// data-sortable-target row: sidebar conversation rows render counts only, with a plain form
// toggle and no Stimulus wiring. And the toggle stops propagation so the document-level close
// does not shut the panel in the same click that opened it.

export default class extends Controller {
  static targets = [ "button", "panel", "counts" ]
  static values = { reactUrl: String, unreactUrl: String }

  toggle(event) {
    event.stopPropagation() // the document-level close must not shut the panel this click opened
    this.panelTarget.classList.toggle("hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
  }

  select(event) {
    event.stopPropagation() // the panel hides itself; the document-level close stays out of it
    const button = event.currentTarget
    const emoji = button.dataset.emoji
    const reacted = button.dataset.reacted === "true"

    const body = new FormData()
    body.append("emoji", emoji)

    // A failure needs no handling here: the counts live on the server, so the next render of
    // this row shows the counts the server kept, which is the honest answer about what stuck.
    fetch(reacted ? this.unreactUrlValue : this.reactUrlValue, {
      method: "POST",
      body,
      headers: { "X-CSRF-Token": this.#csrfToken },
    }).catch(() => {})

    button.dataset.reacted = String(!reacted)
    this.#bumpCount(emoji, reacted ? -1 : 1)
    this.close()
  }

  // The chips render server-side as "<emoji> <n>" spans; keep them in step optimistically so
  // the toggle feels instant, creating a chip on first react and removing it on last unreact.
  #bumpCount(emoji, delta) {
    const chip = this.countsTarget.querySelector(`[data-emoji-chip="${emoji}"]`)

    if (chip) {
      const count = parseInt(chip.textContent.trim().split(/\s+/).pop(), 10) + delta
      if (count <= 0) chip.remove()
      else chip.textContent = `${emoji} ${count}`
    } else if (delta > 0) {
      const fresh = document.createElement("span")
      fresh.setAttribute("data-emoji-chip", emoji)
      fresh.textContent = `${emoji} 1`
      this.countsTarget.querySelector('[data-role="reaction-counts"]').append(" ", fresh)
    }
  }

  get #csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
