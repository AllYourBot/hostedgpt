import "@hotwired/turbo-rails"
import("blocks").then(() => {
  import("stimulus")
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
