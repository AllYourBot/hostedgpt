import { Controller } from "@hotwired/stimulus"
import mermaid from "mermaid"

let initializedTheme
let renderCounter = 0
const renderedDiagrams = new Map()
const RENDERED_DIAGRAMS_LIMIT = 25

// Renders ```mermaid fences as diagram previews. The original <pre> is
// moved intact (copy button included) into a "Diagram source" disclosure,
// so nothing is ever destroyed: invalid syntax or a mid-stream partial
// simply leaves readable source. While a reply streams (the content div's
// data-streaming flag) rendering holds off; the settle broadcast previews
// once the fence closes. Finished diagrams render once and are reused
// from a bounded source-keyed cache; every render pass checks the current
// theme and, after a mid-session flip (module state survives Turbo
// visits), re-initializes mermaid and clears the cache so cached diagrams
// re-render under the new theme.
export default class extends Controller {
  connect() {
    this.scheduleRender()
    this.observer = new MutationObserver(() => this.scheduleRender())
    this.observer.observe(this.element, { childList: true, characterData: true, subtree: true })
  }

  disconnect() {
    clearTimeout(this.timer)
    this.observer?.disconnect()
  }

  scheduleRender() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.render(), 200)
  }

  async render() {
    // Mid-stream the fence is unclosed: rendering a partial diagram gets a
    // parse error (and mermaid's own error graphic) flashing on every
    // chunk. Leave readable source until the settle broadcast.
    if (this.element.dataset.streaming === "true") return

    for (const pre of this.element.querySelectorAll('pre[lang="mermaid"], pre.language-mermaid')) {
      if (pre.dataset.diagramRendered) continue
      const code = pre.querySelector("code")
      const source = code ? code.textContent : pre.textContent
      if (!source || (!source.includes("\n") && !/-->|---/.test(source))) continue
      const id = `mermaid-${++renderCounter}`
      try {
        this.load()
        let svg = renderedDiagrams.get(source)
        if (!svg) {
          const result = await mermaid.render(id, source)
          svg = result.svg
          if (renderedDiagrams.size >= RENDERED_DIAGRAMS_LIMIT) {
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
        // Mermaid inserts its own error graphic before throwing inside a temp
        // wrapper (d${id}); clean up both so nothing lingers in the DOM.
        document.getElementById(id)?.remove()
        document.getElementById(`d${id}`)?.remove()
      }
    }
  }

  load() {
    const theme = this.theme()
    if (initializedTheme !== theme) {
      mermaid.initialize({ startOnLoad: false, theme })
      renderedDiagrams.clear()
      initializedTheme = theme
    }
  }

  theme() {
    // The stylesheet's dark variant matches on two branches: a .dark ancestor,
    // or a media query within .system — both classes live on <body>. Mirror it.
    const dark = document.documentElement.classList.contains("dark") || document.body.classList.contains("dark")
    const system = document.documentElement.classList.contains("system") || document.body.classList.contains("system")
    if (dark || (system && window.matchMedia("(prefers-color-scheme: dark)").matches)) return "dark"
    return "neutral"
  }
}
