import { Controller } from "@hotwired/stimulus"
import renderMathInElement from "katex-auto-render"

// Typesets LaTeX math inside a message. Fires on connect (initial load and
// every Turbo Stream replace) plus a debounced MutationObserver for
// in-place morphs during streaming. Single-$ is deliberately not a
// delimiter so currency like $5 never becomes math.
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
