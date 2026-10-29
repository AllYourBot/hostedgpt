import { Controller } from "@hotwired/stimulus"
import renderMathInElement from "katex-auto-render"

export default class extends Controller {
  #timer
  #observer

  connect() {
    this.#typeset()
    this.#observer = new MutationObserver(() => this.#scheduleTypeset())
    this.#observer.observe(this.element, { childList: true, characterData: true, subtree: true })
  }

  disconnect() {
    clearTimeout(this.#timer)
    this.#observer?.disconnect()
  }

  #scheduleTypeset() {
    clearTimeout(this.#timer)
    this.#timer = setTimeout(() => this.#typeset(), 150)
  }

  get #streaming() {
    return this.element.dataset.streaming === "true"
  }

  #typeset() {
    if (this.#streaming) return
    if (!/\$\$|\\\(|\\\[/.test(this.element.textContent)) return

    try {
      renderMathInElement(this.element, {
        delimiters: [ // no single-$ delimiter: currency like $5 would become math
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
