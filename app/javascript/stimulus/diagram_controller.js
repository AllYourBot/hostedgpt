import { Controller } from "@hotwired/stimulus"

let initializedTheme
let renderCounter = 0
const renderedDiagrams = new Map()

let mermaidModule
// Loaded only when a diagram is actually present: mermaid.esm.min.mjs is
// ~1MB, so an eager import would tax every page load, diagram or not. The
// module-level memo keeps re-renders from touching the module graph again
// (dynamic import alone also memoizes, but this makes intent explicit).
async function loadMermaid() {
  mermaidModule ??= (await import("mermaid")).default
  return mermaidModule
}

export default class extends Controller {
  #timer
  #observer

  connect() {
    this.#scheduleRender()
    this.#observer = new MutationObserver(() => this.#scheduleRender())
    this.#observer.observe(this.element, { childList: true, characterData: true, subtree: true })
  }

  disconnect() {
    clearTimeout(this.#timer)
    this.#observer?.disconnect()
  }

  #scheduleRender() {
    clearTimeout(this.#timer)
    this.#timer = setTimeout(() => this.#render(), 200)
  }

  async #render() {
    if (this.#streaming) return

    for (const pre of this.element.querySelectorAll('pre[lang="mermaid"], pre.language-mermaid')) {
      if (pre.dataset.diagramRendered) continue
      const code = pre.querySelector("code")
      const source = code ? code.textContent : pre.textContent
      if (!source || (!source.includes("\n") && !/-->|---/.test(source))) continue
      const id = `mermaid-${++renderCounter}`
      try {
        const mermaid = await loadMermaid()
        this.#initializeMermaidForCurrentTheme(mermaid)
        let svg = renderedDiagrams.get(source)
        if (!svg) {
          const result = await mermaid.render(id, source)
          svg = result.svg
          if (renderedDiagrams.size >= 25) {
            renderedDiagrams.delete(renderedDiagrams.keys().next().value)
          }
          renderedDiagrams.set(source, svg)
        }
        if (!document.contains(pre)) continue
        const preview = document.createElement("div")
        preview.className = "mermaid-preview overflow-x-auto my-2"
        preview.innerHTML = svg
        const details = document.createElement("details")
        details.className = "text-sm opacity-80"
        const summary = document.createElement("summary")
        summary.className = "cursor-pointer"
        summary.textContent = "Diagram source"
        const sourceNode = pre.cloneNode(true)
        sourceNode.dataset.diagramRendered = "true"
        details.append(summary, sourceNode)
        pre.replaceWith(preview, details)
      } catch (error) {
        console.warn("mermaid render skipped", error?.message)
        // mermaid leaves its error graphic and temp wrapper behind when it throws
        document.getElementById(id)?.remove()
        document.getElementById(`d${id}`)?.remove()
      }
    }
  }

  get #streaming() {
    return this.element.dataset.streaming === "true"
  }

  #initializeMermaidForCurrentTheme(mermaid) {
    const theme = this.#theme()
    if (initializedTheme !== theme) {
      mermaid.initialize({ startOnLoad: false, theme })
      renderedDiagrams.clear()
      initializedTheme = theme
    }
  }

  #theme() {
    // must match the stylesheet's dark variant
    const dark = document.documentElement.classList.contains("dark") || document.body.classList.contains("dark")
    const system = document.documentElement.classList.contains("system") || document.body.classList.contains("system")
    if (dark || (system && window.matchMedia("(prefers-color-scheme: dark)").matches)) return "dark"
    return "neutral"
  }
}
