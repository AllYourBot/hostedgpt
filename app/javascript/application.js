import "@hotwired/turbo-rails"
import("blocks").then(() => {
  import("stimulus")
})

// Populate environment vars
window.request = {
  current_path: window.location.pathname,
  referer_path: null
}
const getParams = () => { return Object.fromEntries(new URLSearchParams(window.location.search)) }
window.params = getParams()

document.addEventListener("turbo:visit", (event) => {
  console.log('turbo:visit')
  const new_path = URL.parse(event.detail.url).pathname
  if (new_path != request.current_path) {
    request.referer_path = request.current_path
    request.current_path = new_path
  }
  window.params = getParams()
})

// Utilities for test environment
window.imageLoadingForSystemTestsToCheck = {}
window.logs = []

// Debug code
// console.log('Document: refresh')
// document.addEventListener('turbo:visit', (event) => console.log(`Document: visit ${event.detail.action}, path = ${window.location.pathname} vs ${event.detail.url}`))
// document.addEventListener('turbo:morph', () => console.log('Document: morph render'))
// document.addEventListener('turbo:before-morph-element', (e) => { if (document.getElementById('composer').contains(e.target)) console.log('Document: before-morph', e.target) })
// document.addEventListener('turbo:frame-render', () => console.log('Document: frame render'))
// document.addEventListener('turbo:before-stream-render', (event) => console.log(`Document: stream render (${event.target.getAttribute('action')} event)`, event.target, event.detail.newStream.querySelector('template').content?.firstChild?.nextSibling?.querySelector('[data-speaker-target="text assistantText"]')))
