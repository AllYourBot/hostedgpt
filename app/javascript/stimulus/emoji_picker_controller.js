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
// Two notes on the markup. The panel lives with the row it reacts to, including inside a
// sortable item: the sortable ghost clone strips ids and Stimulus wiring from its scenery
// copy only, so the row's own controller stays connected through drags and morphs like any
// other row controller. Sidebar conversation rows carry this full picker with counts beside
// it, same partial as messages. And the toggle stops propagation so the document-level close
// does not shut the panel in the same click that opened it.

export default class extends Controller {
  static targets = [ "button", "panel", "counts" ]
  static values = { reactUrl: String, unreactUrl: String }

  toggle(event) {
    event.stopPropagation() // the document-level close must not shut the panel this click opened
    // One panel open at a time: opening this one closes the others, since the toggle's own
    // stopPropagation would otherwise defeat their document-level close and leave panels stacked.
    for (const root of document.querySelectorAll('[data-controller="emoji-picker"]')) {
      if (root === this.element) continue
      this.application.getControllerForElementAndIdentifier(root, "emoji-picker")?.close()
    }
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

    // The chip flips optimistically for instant feel; a non-2xx answer or a failed fetch
    // reverts it, since 204 endpoints never re-render and a stuck chip would lie until the
    // next full render of this row.
    fetch(reacted ? this.unreactUrlValue : this.reactUrlValue, {
      method: "POST",
      body,
      headers: { "X-CSRF-Token": this.#csrfToken },
    }).then((response) => {
      if (!response.ok) this.#revertSelect(button, emoji, reacted)
    }).catch(() => this.#revertSelect(button, emoji, reacted))

    button.dataset.reacted = String(!reacted)
    this.#bumpCount(emoji, reacted ? -1 : 1)
    this.close()
  }

  #revertSelect(button, emoji, reacted) {
    button.dataset.reacted = String(reacted)
    this.#bumpCount(emoji, reacted ? 1 : -1)
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
