import { Controller } from "@hotwired/stimulus"
import renderMathInElement from "katex-auto-render"

// Typesets LaTeX math inside a message. Fires on connect (initial load and
// every Turbo Stream replace) plus a debounced MutationObserver for
// in-place morphs during streaming. Single-$ is deliberately not a
// delimiter so currency like $5 never becomes math.
//
// The content is deliberately NOT typeset while a reply is streaming
// (data-streaming): the stream re-renders the message per chunk, and
// re-typesetting incomplete math churns raw-to-typeset, the latex cousin
// of the diagram preview's flash. Math typesets once on the settle
// broadcast and statically on page load. If live streaming math is ever
// wanted, that gate is the one thing to revisit.
export default class extends Controller {
  connect() {
    this.typeset()
    this.observer = new MutationObserver(() => this.scheduleTypeset())
    this.observer.observe(this.element, { childList: true, characterData: true, subtree: true })
  }

  disconnect() {
    clearTimeout(this.timer)
    this.observer?.disconnect()
  }

  scheduleTypeset() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.typeset(), 150)
  }

  typeset() {
    // See the class comment: no mid-stream typesetting, deliberately.
    if (this.element.dataset.streaming === "true") return
    if (!/\$\$|\\\(|\\\[/.test(this.element.textContent)) return

    try {
      renderMathInElement(this.element, {
        delimiters: [
          { left: "$$", right: "$$", display: true },
          { left: "\\[", right: "\\]", display: true },
          { left: "\\(", right: "\\)", display: false }
        ],
        throwOnError: false
      })
    } catch (error) {
      console.error("math typeset failed", error)
    }
  }
}
